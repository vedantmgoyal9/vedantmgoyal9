package github

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/google/go-github/v54/github"
)

func SubmitManifests(pkg_id, version string, manifests []WinGetManifest, commitType CommitType, forkUser string, reuseDraftPr bool, rmReason ...string) {
	if existingPullRequest := getExistingPullRequest(pkg_id, version); existingPullRequest != nil {
		fmt.Println("The pull request already exists.")
		fmt.Printf("-> %s [#%d]\n", existingPullRequest.GetTitle(), existingPullRequest.GetNumber())
		return
	}

	winget_pkgs, _, _ := github_client.Repositories.Get(context.Background(), "microsoft", "winget-pkgs")
	winget_pkgs_latest_commit, _, _ := github_client.Repositories.GetBranch(context.Background(), "microsoft", "winget-pkgs", winget_pkgs.GetDefaultBranch(), false)

	if forkUser == "" {
		forkUser = github_client_user
	}
	winget_pkgs_fork, _, err := github_client.Repositories.Get(context.Background(), forkUser, "winget-pkgs")
	if err != nil {
		fmt.Printf("Failed to get winget-pkgs fork on @%s.\n", forkUser)
		panic(err)
	}

	branchName := fmt.Sprintf("%s-%s-%s", pkg_id, version, time.Now().Format("20060102150405"))
	commitMessage := fmt.Sprintf("%s: %s version %s", commitType, pkg_id, version)
	pullRequestBody := &strings.Builder{}
	if commitType == RmVerCommit {
		pullRequestBody.WriteString("### Reason for deletion: " + rmReason[0] + "\n")
	}
	pullRequestBody.WriteString("### Pull request has been created with [WinGet Automation](https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation) 🪟📦🤖\n")
	commit := commitFiles(pkg_id, version, manifests, commitMessage, forkUser, winget_pkgs_latest_commit, winget_pkgs_fork)

	draftPullRequest := getDraftPullRequest(pkg_id, version)
	if draftPullRequest != nil && reuseDraftPr {
		pullRequest, _, _ := github_client.PullRequests.Get(context.Background(), "microsoft", "winget-pkgs", draftPullRequest.GetNumber())
		if _, _, err := github_client.Git.UpdateRef(context.Background(), forkUser, "winget-pkgs", &github.Reference{
			Ref: github.String("refs/heads/" + pullRequest.GetHead().GetRef()),
			Object: &github.GitObject{
				SHA: github.String(commit.GetSHA()),
			},
		}, true); err != nil {
			fmt.Printf("Failed to update branch \"%s\" on %s.\n", pullRequest.GetHead().GetRef(), winget_pkgs_fork.GetFullName())
			panic(err)
		}

		// Update pull request's title and body, and mark it as ready for review
		reqBody, _ := json.Marshal(map[string]string{
			"query": fmt.Sprintf(`
				mutation { 
					updatePullRequest(input: {pullRequestId: "%s", body: "%s", title: "%s", state: OPEN}) {pullRequest{ id }}
					markPullRequestReadyForReview(input: {pullRequestId: "%s"}) {pullRequest{ id }}
				}
			`, pullRequest.GetNodeID(), pullRequestBody.String(), commitMessage, pullRequest.GetNodeID())})
		req, _ := http.NewRequest(http.MethodPost, "https://api.github.com/graphql", bytes.NewReader(reqBody))
		req.Header.Set("Authorization", "bearer "+os.Getenv("GITHUB_TOKEN"))
		req.Header.Set("Accept", "application/vnd.github.shadow-cat-preview+json")
		if _, err := http.DefaultClient.Do(req); err != nil {
			fmt.Printf("Failed to update pull request: %s\n", pullRequest.GetHTMLURL())
			panic(err)
		} else {
			fmt.Printf("Used draft pull request: %s\n", pullRequest.GetHTMLURL())
			fmt.Println("-> New title: " + commitMessage)
			return
		}
	}

	// Create a branch on the fork
	if _, _, err := github_client.Git.CreateRef(context.Background(), forkUser, "winget-pkgs", &github.Reference{
		Ref: github.String("refs/heads/" + branchName),
		Object: &github.GitObject{
			SHA: github.String(commit.GetSHA()),
		},
	}); err != nil {
		fmt.Printf("Failed to create branch on %s.\n", winget_pkgs_fork.GetFullName())
		panic(err)
	}

	// Create a pull request on microsoft/winget-pkgs from the fork
	if pullRequest, _, err := github_client.PullRequests.Create(context.Background(), "microsoft", "winget-pkgs", &github.NewPullRequest{
		Title: github.String(commitMessage),
		Head:  github.String(forkUser + ":" + branchName),
		Base:  github.String(winget_pkgs.GetDefaultBranch()),
		Body:  github.String(pullRequestBody.String()),
	}); err != nil {
		fmt.Println("Failed to create pull request.")
		panic(err)
	} else {
		fmt.Printf("Pull request created: %s\n", pullRequest.GetHTMLURL())
	}
}

func commitFiles(pkg_id, version string, manifests []WinGetManifest, commitMessage, forkUser string, winget_pkgs_latest_commit *github.Branch, winget_pkgs_fork *github.Repository) *github.Commit {
	// Create a tree with the updated manifest files on the fork
	manifestFiles := []*github.TreeEntry{}
	for _, manifest := range manifests {
		entry := &github.TreeEntry{
			Path:    github.String(getPackagePath(pkg_id, version, manifest.FileName)),
			Mode:    github.String("100644"),
			Type:    github.String("blob"),
			Content: github.String(manifest.Content),
		}
		if manifest.Content == "" {
			entry.Content = nil
			entry.SHA = nil
		}
		manifestFiles = append(manifestFiles, entry)
	}
	tree, _, err := github_client.Git.CreateTree(context.Background(), forkUser, "winget-pkgs", winget_pkgs_latest_commit.GetCommit().GetCommit().GetTree().GetSHA(), manifestFiles)
	if err != nil {
		fmt.Printf("Failed to create tree on %s.\n", winget_pkgs_fork.GetFullName())
		panic(err)
	}

	// Create a commit using the tree on the fork
	// https://github.com/google/go-github/blob/master/example/commitpr/main.go#L131
	// this is not always populated, but is needed.
	winget_pkgs_latest_commit.Commit.Commit.SHA = winget_pkgs_latest_commit.Commit.SHA
	commit, _, err := github_client.Git.CreateCommit(context.Background(), forkUser, "winget-pkgs", &github.Commit{
		Message: github.String(commitMessage),
		Tree:    tree,
		Parents: []*github.Commit{winget_pkgs_latest_commit.GetCommit().GetCommit()},
	})
	if err != nil {
		fmt.Printf("Failed to create commit on %s.\n", winget_pkgs_fork.GetFullName())
		panic(err)
	}

	return commit
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
