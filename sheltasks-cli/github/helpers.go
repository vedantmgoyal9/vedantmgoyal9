package github

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/go-github/v58/github"
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

func getDraftPullRequest(pkg_id, version string) *github.Issue {
	ctx := context.Background()
	result, _, _ := github_client.Search.Issues(ctx, "repo:microsoft/winget-pkgs draft:true author:@me is:pr is:open", nil)
	if len(result.Issues) > 0 {
		return result.Issues[0]
	}
	return nil
}

func getExistingPullRequest(pkg_id, version string) *github.Issue {
	ctx := context.Background()
	searchQuery := fmt.Sprintf("repo:microsoft/winget-pkgs author:@me is:pr is:open %s %s", pkg_id, version)
	result, _, _ := github_client.Search.Issues(ctx, searchQuery, nil)
	if len(result.Issues) > 0 {
		return result.Issues[0]
	}
	return nil
}
