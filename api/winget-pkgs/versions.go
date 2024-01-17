package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"slices"
	"sort"
	"strings"

	"github.com/google/go-github/v58/github"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/api/winget-pkgs/_natural"
)

// #route /api/winget-pkgs/versions?package_identifier={package_identifier}
func Versions(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	github_client := github.NewClient(nil)
	
	pkg_id := r.URL.Query().Get("package_identifier")
	if pkg_id == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("package_identifier query parameter is required"))
		return
	}

	pkg_path := fmt.Sprintf("manifests/%s/%s", strings.ToLower(pkg_id[0:1]), strings.ReplaceAll(pkg_id, ".", "/"))

	_, dir_contents, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", pkg_path, nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("error getting package versions for %s: %s", pkg_id, err)))
		return
	}

	package_versions := []string{}
	commonly_ignored_versions := []string{"eap", "preview", "beta", "dev", "nightly", "canary", "insiders"}
	for _, dir_content := range dir_contents {
		if dir_content.GetType() == "dir" && !slices.Contains(commonly_ignored_versions, strings.ToLower(dir_content.GetName())) {
			package_versions = append(package_versions, dir_content.GetName())
		}
	}

	sort.Sort(natural.StringSlice(package_versions)) // sort versions naturally

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"PackageIdentifier": pkg_id,
		"Versions":          package_versions,
	})
}
