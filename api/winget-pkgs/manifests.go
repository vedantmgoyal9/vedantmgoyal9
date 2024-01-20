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
	"github.com/vedantmgoyal2009/vedantmgoyal2009/api/winget-pkgs/_natural"
)

type Manifest struct {
	FileName string
	Content  string
}

// #route /api/winget-pkgs/manfiests?package_identifier={package_identifier}&version={version}
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
		w.Write([]byte("package_identifier query parameter is required"))
		return
	}
	if version == "" {
		version = "latest"
	}

	// duplicated code from versions.go, since it seems like vercel builds functions separately and
	// hence they can't access function declared in another file, while golang itself supports this
	_, versions_in_dir, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", getPackagePath(pkg_id, ""), nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("error getting package versions for %s: %s", pkg_id, err)))
		return
	}

	pkg_versions := []string{}
	commonly_ignored_versions := []string{"eap", "preview", "beta", "dev", "nightly", "canary", "insiders"}
	for _, dir_content := range versions_in_dir {
		if dir_content.GetType() == "dir" && !slices.Contains(commonly_ignored_versions, strings.ToLower(dir_content.GetName())) {
			pkg_versions = append(pkg_versions, dir_content.GetName())
		}
	}
	// end of duplicated code

	if strings.ToLower(version) == "latest" {
		sort.Sort(natural.StringSlice(pkg_versions)) // sort versions naturally
		version = pkg_versions[len(pkg_versions)-1]
	} else {
		if !slices.Contains(pkg_versions, version) {
			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte(fmt.Sprintf("version %s does not exist for package %s", version, pkg_id)))
			return
		}
	}

	_, dir_contents, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", getPackagePath(pkg_id, version), nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("error getting manifests for %s version %s: %s", pkg_id, version, err)))
		return
	}

	manifests := []Manifest{}
	for _, dir_content := range dir_contents {
		res, err := http.Get(dir_content.GetDownloadURL())
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error getting manifest %s: %s", dir_content.GetName(), err)))
			return
		}
		manifest_raw, err := io.ReadAll(res.Body)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error reading response body for manifest %s: %s", dir_content.GetName(), err)))
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
