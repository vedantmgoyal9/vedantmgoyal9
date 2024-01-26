package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"slices"
	"sort"
	"strings"

	"github.com/google/go-github/v58/github"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/api/_natural"
)

type Manifest struct {
	FileName string
	Content  string
}

// #route /api/winget-pkgs/manfiests?package_identifier={package_identifier}&version={version}?
func Manifests(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	github_client := github.NewClient(nil)

	pkg_id := r.URL.Query().Get("package_identifier")
	version := r.URL.Query().Get("version")
	if pkg_id == "" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "package_identifier query parameter is required")
		return
	}
	if version == "" {
		version = "latest"
	}

	response := struct {
		PackageIdentifier string   `json:"PackageIdentifier"`
		Versions          []string `json:"Versions"`
	}{}
	res, err := http.Get("https://vedantmgoyal.vercel.app/api/winget-pkgs/versions/" + pkg_id)
	// error will only be of type *url.Error, so added check for status code as well
	if err != nil || res.StatusCode != http.StatusOK {
		// we assume that the error is because the package was not found because
		// the API seems to be stable 🙂 and the only error that can occur is when the package is not found
		w.WriteHeader(http.StatusNoContent)
		fmt.Fprintf(w, "package %s not found in winget-pkgs (https://github.com/microsoft/winget-pkgs)", pkg_id)
		return
	}
	defer res.Body.Close()
	json.NewDecoder(res.Body).Decode(&response)
	pkg_versions := response.Versions

	if strings.ToLower(version) == "latest" {
		sort.Sort(natural.StringSlice(pkg_versions)) // sort versions naturally
		version = pkg_versions[len(pkg_versions)-1]
	} else if !slices.Contains(pkg_versions, version) {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, "version %s does not exist for package %s", version, pkg_id)
		return
	}

	_, dir_contents, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", getPackagePath(pkg_id, version), nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error getting manifests for %s version %s: %s", pkg_id, version, err)
		return
	}

	manifests := []Manifest{}
	for _, dir_content := range dir_contents {
		res, err := http.Get(dir_content.GetDownloadURL())
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error getting manifest %s: %s", dir_content.GetName(), err)
			return
		}
		manifest_raw, err := io.ReadAll(res.Body)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error reading response body for manifest %s: %s", dir_content.GetName(), err)
			return
		}
		defer res.Body.Close()
		manifests = append(manifests, Manifest{
			FileName: getPackagePath(pkg_id, version, dir_content.GetName()),
			Content:  string(manifest_raw),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(manifests)
}

func getPackagePath(pkg_id, version string, fileName ...string) string {
	pkg_path := fmt.Sprintf("manifests/%s/%s", strings.ToLower(pkg_id[0:1]), strings.ReplaceAll(pkg_id, ".", "/"))
	if len(version) > 0 {
		pkg_path += "/" + version
	}
	if len(fileName) > 0 {
		pkg_path += "/" + fileName[0]
	}
	return pkg_path
}
