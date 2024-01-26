package handler

import (
	"archive/zip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path"
	"sort"

	_ "github.com/ncruces/go-sqlite3/driver"
	_ "github.com/ncruces/go-sqlite3/embed"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/api/_natural"
)

// #route /api/winget-pkgs/versions?package_identifier={package_identifier}
func Versions(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	pkg_id := r.URL.Query().Get("package_identifier")
	if pkg_id == "" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "package_identifier query parameter is required")
		return
	}

	package_versions := map[string][]string{}

	// download source.msix from winget cdn
	// https://cdn.winget.microsoft.com/cache/source.msix
	res, err := http.Get("https://cdn.winget.microsoft.com/cache/source.msix")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while downloading source.msix: %v", err)
		return
	}
	out, err := os.Create(path.Join("/tmp", "source.msix"))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while creating source.msix file: %v", err)
		return
	}
	defer out.Close()
	_, err = io.Copy(out, res.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while writing source.msix to file: %v", err)
		return
	}

	// extract Public/index.db from source.msix to /tmp
	zipReader, err := zip.OpenReader(path.Join("/tmp", "source.msix"))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while opening source.msix for reading: %v", err)
		return
	}
	for _, file := range zipReader.File {
		if file.Name != "Public/index.db" {
			continue
		}
		rc, err := file.Open()
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while opening Public/index.db inside source.msix: %v", err)
			return
		}
		defer rc.Close()
		newFile, err := os.Create(path.Join("/tmp", "index.db"))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while creating /tmp/index.db: %v", err)
			return
		}
		defer newFile.Close()
		_, err = io.Copy(newFile, rc)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while copying from zip to /tmp: %v", err)
			return
		}
	}

	db, err := sql.Open("sqlite3", path.Join("/tmp", "index.db"))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while opening /tmp/index.db: %v", err)
		return
	}
	defer db.Close()
	rows, err := db.Query("SELECT id, version FROM manifest")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while running query on 'manifest' table in /tmp/index.db: %v", err)
		return
	}
	for rows.Next() {
		var id string
		var version string
		err = rows.Scan(&id, &version)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while scanning rows: %v", err)
			return
		}
		// SELECT id FROM ids WHERE rowid = {id}
		var pkg_id_from_ids string
		err = db.QueryRow("SELECT id FROM ids WHERE rowid = ?", id).Scan(&pkg_id_from_ids)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while running query on ids table in /tmp/index.db: %v", err)
			return
		}
		// SELECT version FROM versions WHERE rowid = {version}
		var pkg_version_from_versions string
		err = db.QueryRow("SELECT version FROM versions WHERE rowid = ?", version).Scan(&pkg_version_from_versions)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while running query on versions table in /tmp/index.db: %v", err)
			return
		}
		// add to package_versions map
		package_versions[pkg_id_from_ids] = append(package_versions[pkg_id_from_ids], pkg_version_from_versions)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if pkg_id == "*" {
		json.NewEncoder(w).Encode(package_versions)
	} else if (package_versions[pkg_id]) == nil {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, "package %s not found in winget-pkgs source.msix. make sure atleast one version of the package exists in winget-pkgs, or wait for publish pipeline to complete for the package", pkg_id)
	}else {
		sort.Sort(sort.Reverse(natural.StringSlice(package_versions[pkg_id]))) // sort versions naturally
		json.NewEncoder(w).Encode(map[string]interface{}{
			"PackageIdentifier": pkg_id,
			"Versions":          package_versions[pkg_id],
		})
	}
}
