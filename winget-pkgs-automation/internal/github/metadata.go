package github

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/go-github/v54/github"
)

func GetMetadataFromGitHub(release_url string) MetadataFromGithub {
	release_url_splitted := strings.Split(release_url, "/")
	release, _, err := github_client.Repositories.GetReleaseByTag(context.Background(), release_url_splitted[3], release_url_splitted[4], release_url_splitted[7])
	if err != nil {
		panic(fmt.Errorf("error getting release: %v", err))
	}
	repo_info, _, _ := github_client.Repositories.Get(context.Background(), release_url_splitted[3], release_url_splitted[4])

	return MetadataFromGithub{
		PublisherUrl:        getPublisherUrl(repo_info),
		PublisherSupportUrl: getPublisherSupportUrl(repo_info),
		License:             getLicense(repo_info),
		LicenseUrl:          repo_info.GetLicense().GetHTMLURL(),
		PackageUrl:          repo_info.GetHTMLURL(),
		ReleaseDate:         release.GetPublishedAt().Format("2006-01-02"),
		ReleaseNotesUrl:     release.GetHTMLURL(),
		PrivacyUrl:          getPrivacyUrl(repo_info),
		Tags:                repo_info.Topics,
		ShortDescription:    repo_info.GetDescription(),
	}
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

func getPrivacyUrl(repo_info *github.Repository) string {
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
