package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/google/go-github/v58/github"
)

// #route /api/gh-release-and-repo-info?owner={owner}&repo={repo}&release_tag={release_tag}
func GitHubReleaseAndRepoMetadata(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	// get the owner, repo and release tag from the URL
	owner := r.URL.Query().Get("owner")
	repo := r.URL.Query().Get("repo")
	release_tag := r.URL.Query().Get("release_tag")
	if len(owner) == 0 || len(repo) == 0 || len(release_tag) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("owner, repo and release_tag query parameters are required"))
		return
	}

	github_client := github.NewClient(nil)
	repo_info, _, err := github_client.Repositories.Get(context.Background(), owner, repo)
	if err != nil {
		w.WriteHeader(http.StatusTeapot)
		w.Write([]byte(fmt.Sprintf("error getting repo info: %s", err)))
		return
	}
	release, _, err := github_client.Repositories.GetReleaseByTag(context.Background(), owner, repo, release_tag)
	if err != nil {
		w.WriteHeader(http.StatusTeapot)
		w.Write([]byte(fmt.Sprintf("error getting release: %s", err)))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"PublisherUrl":        getPublisherUrl(repo_info),
		"PublisherSupportUrl": getPublisherSupportUrl(repo_info),
		"License":             getLicense(repo_info),
		"LicenseUrl":          repo_info.GetLicense().GetHTMLURL(),
		"PackageUrl":          repo_info.GetHTMLURL(),
		"ReleaseDate":         release.GetPublishedAt().Format("2006-01-02"),
		"ReleaseNotesUrl":     release.GetHTMLURL(),
		"PrivacyUrl":          getPrivacyUrl(repo_info, github_client),
		"Tags":                repo_info.Topics,
		"ShortDescription":    repo_info.GetDescription(),
	})
}

func getPublisherUrl(repo_info *github.Repository) string {
	if repo_info.GetOwner().GetType() == "Organization" {
		return repo_info.GetOwner().GetBlog()
	} else {
		return repo_info.GetOwner().GetHTMLURL()
	}
}

func getPublisherSupportUrl(repo_info *github.Repository) string {
	if repo_info.GetHasIssues() {
		return repo_info.GetHTMLURL() + "/issues"
	} else {
		return ""
	}
}

func getLicense(repo_info *github.Repository) string {
	if strings.Compare(strings.ToLower(repo_info.GetLicense().GetKey()), "other") != 0 {
		return repo_info.GetLicense().GetSPDXID()
	} else {
		return ""
	}
}

func getPrivacyUrl(repo_info *github.Repository, github_client *github.Client) string {
	_, files, _, err := github_client.Repositories.GetContents(context.Background(), repo_info.GetOwner().GetLogin(), repo_info.GetName(), ".", nil)
	if err != nil {
		return ""
	}
	for _, file := range files {
		if strings.Contains(strings.ToLower(file.GetHTMLURL()), "privacy") {
			return file.GetHTMLURL()
		}
	}
	return ""
}
