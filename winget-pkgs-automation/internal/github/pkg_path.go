package github

import (
	"fmt"
	"strings"
)

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
