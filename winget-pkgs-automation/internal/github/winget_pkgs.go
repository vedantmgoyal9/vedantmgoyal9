package github

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"slices"
	"sort"
)

var cache_pkgversions []string = []string{}
var cache_manifests map[string][]WinGetManifest = map[string][]WinGetManifest{}

func GetWinGetManifests(pkg_id, version string) []WinGetManifest {
	var versionToGetManifestsFor string
	versions := GetWinGetPackageVersions(pkg_id)
	if version == "latest" {
		sort.StringSlice(versions).Sort()
		versionToGetManifestsFor = versions[len(versions)-1]
	} else {
		if !slices.Contains(versions, version) {
			panic(fmt.Errorf("version %s does not exist for package %s", version, pkg_id))
		}
		versionToGetManifestsFor = version
	}

	if _, ok := cache_manifests[version]; ok {
		return cache_manifests[version]
	}

	_, dir_contents, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", getPackagePath(pkg_id, versionToGetManifestsFor), nil)
	if err != nil {
		panic(fmt.Errorf("error getting manifests for %s version %s: %s", pkg_id, versionToGetManifestsFor, err))
	}

	manifests := []WinGetManifest{}
	for _, dir_content := range dir_contents {
		res, err := http.Get(dir_content.GetDownloadURL())
		if err != nil {
			panic(fmt.Errorf("error getting manifest %s: %s", dir_content.GetName(), err))
		}
		manifest_raw, err := io.ReadAll(res.Body)
		if err != nil {
			panic(fmt.Errorf("error reading response body for manifest %s: %s", dir_content.GetName(), err))
		}
		manifests = append(manifests, WinGetManifest{
			FileName: dir_content.GetName(),
			Content:  string(manifest_raw),
		})
	}
	cache_manifests[versionToGetManifestsFor] = manifests

	return cache_manifests[versionToGetManifestsFor]
}

func GetWinGetPackageVersions(pkg_id string) []string {
	if len(cache_pkgversions) > 0 {
		return cache_pkgversions
	}

	_, dir_contents, _, err := github_client.Repositories.GetContents(context.Background(), "microsoft", "winget-pkgs", getPackagePath(pkg_id, ""), nil)
	if err != nil {
		panic(fmt.Errorf("error getting package versions for %s: %s", pkg_id, err))
	}

	for _, dir_content := range dir_contents {
		if dir_content.GetType() == "dir" {
			cache_pkgversions = append(cache_pkgversions, dir_content.GetName())
		}
	}

	return cache_pkgversions
}
