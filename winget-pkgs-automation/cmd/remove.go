/*
Copyright © 2023 Vedant
*/
package cmd

import (

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
)

var (
	removeCmd_reason string
	removeCmd_forkUser string
	removeCmd_reuseDraftPr bool
)

var removeCmd = &cobra.Command{
	Use:     "remove <package-id> <version>",
	Aliases: []string{"r", "rm", "delete", "del"},
	Short:   "Remove a package version",
	Args:   cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		pkg_id := args[0]
		version := args[1]

		manifests := github.GetWinGetManifests(pkg_id, version)
		var removedManifests []github.WinGetManifest
		for _, manifest := range manifests {
			removedManifests = append(removedManifests, github.WinGetManifest{
				FileName: manifest.FileName,
				Content:  "",
			})
		}

		github.SubmitManifests(pkg_id, version, removedManifests, github.RmVerCommit, removeCmd_forkUser, removeCmd_reuseDraftPr, removeCmd_reason)
	},
}

func init() {
	removeCmd.Flags().StringVarP(&removeCmd_reason, "reason", "r", "", "Reason for deleting the manifest (required)")
	removeCmd.Flags().StringVar(&removeCmd_forkUser, "fork-user", "", "Owner of winget-pkgs fork (default: user of the token)")
	removeCmd.Flags().BoolVar(&removeCmd_reuseDraftPr, "reuse-draft-pr", false, "Force push & update an existing draft PR, if any")

	removeCmd.MarkFlagRequired("reason")
	removeCmd.Flags().MarkHidden("reuse-draft-pr")

	rootCmd.AddCommand(removeCmd)
}
