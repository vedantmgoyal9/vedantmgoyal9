package handler

import (
	"archive/zip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
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

	url := "https://cdn.winget.microsoft.com/cache/source.msix"
	path_to_extract := "Public/index.db"
	path_msix := "/tmp/source.msix"
	path_database := "/tmp/index.db"
	if _, err := os.Stat(path_database); os.IsNotExist(err) {
		err := downloadSourceMsixAndExtractDatabase(url, path_to_extract, path_msix, path_database)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while downloading source.msix and extracting index.db: %v", err)
			return
		}
	}

	package_versions := make(map[string][]string)
	db, err := sql.Open("sqlite3", path_database)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while opening %s: %v", path_database, err)
		return
	}
	rows, err := db.Query("SELECT id, version FROM manifest")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error while running query on 'manifest' table in %s: %v", path_database, err)
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
			fmt.Fprintf(w, "error while running query on ids table in %s: %v", path_database, err)
			return
		}
		// SELECT version FROM versions WHERE rowid = {version}
		var pkg_version_from_versions string
		err = db.QueryRow("SELECT version FROM versions WHERE rowid = ?", version).Scan(&pkg_version_from_versions)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error while running query on versions table in %s: %v", path_database, err)
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
	} else {
		// sort versions naturally in descending order
		sort.Sort(sort.Reverse(natural.StringSlice(package_versions[pkg_id])))
		json.NewEncoder(w).Encode(map[string]interface{}{
			"PackageIdentifier": pkg_id,
			"Versions":          package_versions[pkg_id],
		})
	}
}

func downloadSourceMsixAndExtractDatabase(url, path_to_extract, path_msix, path_database string) error {
	// download source.msix from winget cdn (content delivery network)
	res, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("error getting response: %v", err)
	}
	out, err := os.Create(path_msix)
	if err != nil {
		return fmt.Errorf("error creating %s: %v", path_msix, err)
	}
	_, err = io.Copy(out, res.Body)
	if err != nil {
		return fmt.Errorf("error writing to %s: %v", path_msix, err)
	}

	// extract Public/index.db from source.msix to /tmp
	zipReader, err := zip.OpenReader(path_msix)
	if err != nil {
		return fmt.Errorf("error opening %s for reading: %v", path_msix, err)
	}
	for _, file := range zipReader.File {
		if file.Name != path_to_extract {
			continue
		}
		rc, err := file.Open()
		if err != nil {
			return fmt.Errorf("error opening %s inside %s: %v", path_to_extract, path_msix, err)
		}
		newFile, err := os.Create(path_database)
		if err != nil {
			return fmt.Errorf("error creating %s: %v", path_database, err)
		}
		_, err = io.Copy(newFile, rc)
		if err != nil {
			return fmt.Errorf("error writing to %s: %v", path_database, err)
		}
	}
	return nil
}
