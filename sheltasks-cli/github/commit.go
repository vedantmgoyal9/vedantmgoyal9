package github

import (
	"context"
	"fmt"

	"github.com/google/go-github/v58/github"
)

func commitFiles(pkg_id, version string, manifests []WinGetManifest, commitMessage, forkUser string, winget_pkgs_latest_commit *github.Branch, winget_pkgs_fork *github.Repository) *github.Commit {
	ctx := context.Background()

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
	tree, _, err := github_client.Git.CreateTree(ctx, forkUser, "winget-pkgs", winget_pkgs_latest_commit.GetCommit().GetCommit().GetTree().GetSHA(), manifestFiles)
	if err != nil {
		fmt.Printf("Failed to create tree on %s.\n", winget_pkgs_fork.GetFullName())
		panic(err)
	}

	// Create a commit using the tree on the fork
	// https://github.com/google/go-github/blob/master/example/commitpr/main.go#L131
	// this is not always populated, but is needed.
	winget_pkgs_latest_commit.Commit.Commit.SHA = winget_pkgs_latest_commit.Commit.SHA
	commit, _, err := github_client.Git.CreateCommit(ctx, forkUser, "winget-pkgs", &github.Commit{
		Message: github.String(commitMessage),
		Tree:    tree,
		Parents: []*github.Commit{winget_pkgs_latest_commit.GetCommit().GetCommit()},
	}, nil)
	if err != nil {
		fmt.Printf("Failed to create commit on %s.\n", winget_pkgs_fork.GetFullName())
		panic(err)
	}

	return commit
}
