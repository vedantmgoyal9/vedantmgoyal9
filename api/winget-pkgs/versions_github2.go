package handler

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"slices"
	"sort"
	"strings"

	"github.com/vedantmgoyal2009/vedantmgoyal2009/api/_natural"
)

// #route /api/winget-pkgs/versions_github2?package_identifier={package_identifier}
func VersionsGitHub2(w http.ResponseWriter, r *http.Request) {
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

	WINGET_PKGS_OWNER := "microsoft"
	WINGET_PKGS_REPO_NAME := "winget-pkgs"
	WINGET_PKGS_BRANCH := "master"

	res, err := http.Get(fmt.Sprintf("https://codeload.github.com/%s/%s/zip/refs/heads/%s", WINGET_PKGS_OWNER, WINGET_PKGS_REPO_NAME, WINGET_PKGS_BRANCH))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error downloading repository: %s", err)
		return
	}
	out, err := os.Create("/tmp/winget-pkgs.zip")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error creating /tmp/winget-pkgs.zip file: %s", err)
		return
	}
	_, err = io.Copy(out, res.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error writing to /tmp/winget-pkgs.zip file: %s", err)
		return
	}

	repoZip, err := zip.OpenReader("/tmp/winget-pkgs.zip")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "error opening winget-pkgs.zip for reading: %s", err)
		return
	}

	var pkg_versions []string
	pkg_path := fmt.Sprintf("%s-%s/manifests/%s/%s", WINGET_PKGS_REPO_NAME, WINGET_PKGS_BRANCH, pkg_id[0:1], strings.ReplaceAll(pkg_id, ".", "/"))
	pkg_path = strings.ToLower(pkg_path)
	for _, file := range repoZip.File {
		file_name_lower := strings.ToLower(file.Name)
		if !strings.HasPrefix(file_name_lower, pkg_path) || !file.Mode().IsDir() {
			continue
		}
		version := file.Name[len(pkg_path)+1:]
		if slices.Contains(pkg_versions, version) || version == "" {
			continue
		}
		pkg_versions = append(pkg_versions, strings.TrimSuffix(version, "/"))
	}
	// remove sub-packages
	for i := 0; i < len(pkg_versions); i++ {
		is_sub_package := false
		for j := 0; j < len(pkg_versions); j++ {
			if strings.HasPrefix(pkg_versions[j], pkg_versions[i]) && pkg_versions[j] != pkg_versions[i] {
				is_sub_package = true
				pkg_versions = append(pkg_versions[:j], pkg_versions[j+1:]...)
				j--
			}
		}
		if is_sub_package {
			pkg_versions = append(pkg_versions[:i], pkg_versions[i+1:]...)
			i--
		}
	}

	if len(pkg_versions) == 0 {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, "package %s not found in microsoft/winget-pkgs", pkg_id)
		return
	}

	// sort versions naturally in descending order
	sort.Sort(sort.Reverse(natural.StringSlice(pkg_versions)))

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"PackageIdentifier": pkg_id,
		"Versions":          pkg_versions,
	})
}
