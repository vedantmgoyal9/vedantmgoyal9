package github

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/google/go-github/v54/github"
	"github.com/kyokomi/emoji/v2"
)

func DetectDataFromGithub(release_url string) DetectedDataFromGithub {
	release_url_splitted := strings.Split(release_url, "/")
	release, _, err := github_client.Repositories.GetReleaseByTag(context.Background(), release_url_splitted[3], release_url_splitted[4], release_url_splitted[7])
	if err != nil {
		panic(fmt.Errorf("error getting release: %v", err))
	}
	repo_info, _, _ := github_client.Repositories.Get(context.Background(), release_url_splitted[3], release_url_splitted[4])

	return DetectedDataFromGithub{
		PublisherUrl:        getPublisherUrl(repo_info),
		PublisherSupportUrl: getPublisherSupportUrl(repo_info),
		License:             getLicense(repo_info),
		LicenseUrl:          repo_info.GetLicense().GetHTMLURL(),
		PackageUrl:          repo_info.GetHTMLURL(),
		ReleaseDate:         release.GetPublishedAt().Format("2006-01-02"),
		ReleaseNotesUrl:     release.GetHTMLURL(),
		ReleaseNotes:        getFormattedReleaseNotes(release),
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
		return repo_info.GetLicense().GetKey()
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

// TODO: Needs more testing
func getFormattedReleaseNotes(release *github.RepositoryRelease) string {
	split_result := strings.Split(release.GetHTMLURL(), "/")
	owner_repo := split_result[3] + "/" + split_result[4]
	body := release.GetBody()
	if body == "" {
		return ""
	}

	var lines []string
	re := regexp.MustCompile("<details>.*</details>")
	body = re.ReplaceAllString(body, "")
	for _, line := range strings.Split(body, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if strings.HasPrefix(line, "* ") {
			line = "- " + line[2:]
		}
		line = regexp.MustCompile("~+([^~]+)~+").ReplaceAllString(line, "$1")
		line = regexp.MustCompile(`\*+([^*]+)\*+`).ReplaceAllString(line, "$1")
		line = strings.ReplaceAll(line, "`", "")
		line = regexp.MustCompile(`\[?!\[(.*?)]\((.*?)\)(?:]\((.*?)\))?`).ReplaceAllString(line, "")
		line = regexp.MustCompile(`\[([^]]+)]\([^)]+\)`).ReplaceAllString(line, "$1")
		line = regexp.MustCompile(`[a-fA-F0-9]{40}`).ReplaceAllString(line, "")
		line = regexp.MustCompile(`https?://github.com/([\w-]+)/([\w-]+)/(pull|issues)/(\d+)`).ReplaceAllStringFunc(line, func(s string) string {
			matches := regexp.MustCompile(`https?://github.com/([\w-]+)/([\w-]+)/(pull|issues)/(\d+)`).FindStringSubmatch(s)
			urlRepository := fmt.Sprintf("%s/%s", matches[1], matches[2])
			issueNumber := matches[4]
			if urlRepository == owner_repo {
				return fmt.Sprintf("#%s", issueNumber)
			} else {
				return fmt.Sprintf("%s#%s", urlRepository, issueNumber)
			}
		})
		line = emoji.Sprint(line)
		line = strings.TrimSpace(line)
		lines = append(lines, line)
	}

	var result strings.Builder
	for i, line := range lines {
		switch {
		case strings.HasPrefix(line, "#") && (i+1 < len(lines) && strings.HasPrefix(lines[i+1], "- ")):
			result.WriteString(strings.TrimSpace(strings.TrimPrefix(line, "#")) + "\n")
		case strings.HasPrefix(line, "- "):
			line = strings.TrimSpace(strings.TrimPrefix(line, "- "))
			line = regexp.MustCompile("([A-Z][a-z].*?[.!?]) ?(?:$|[A-Z])").ReplaceAllString(line, "$1\n  ")
			result.WriteString("- " + line + "\n")
		}
	}
	return strings.TrimSpace(result.String())
}
