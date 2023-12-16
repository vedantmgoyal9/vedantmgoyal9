/*
Copyright © 2023 Vedant
*/
package cli

import (
	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
)

var (
	removeVersionCmd_reason       string
	removeVersionCmd_reuseDraftPr bool
	removeVersionCmd_forkUser     string
)

var removeVersionCmd = &cobra.Command{
	Use:     "remove-version <package-id> <version>",
	Aliases: []string{"r", "rm", "rmver", "delete", "del"},
	Short:   "Remove a package version",
	Args:    cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		manifests := github.GetWinGetManifests(args[0], args[1])
		var removedManifests []github.WinGetManifest
		for _, manifest := range manifests {
			removedManifests = append(removedManifests, github.WinGetManifest{
				FileName: manifest.FileName,
				Content:  "",
			})
		}

		github.SubmitManifests(args[0], args[1], removedManifests, github.RmVerCommit, removeVersionCmd_forkUser, removeVersionCmd_reuseDraftPr, removeVersionCmd_reason)
	},
}

func init() {
	removeVersionCmd.Flags().StringVarP(&removeVersionCmd_reason, "reason", "r", "", "reason for deleting the manifest (required)")
	removeVersionCmd.Flags().BoolVar(&removeVersionCmd_reuseDraftPr, "reuse-draft-pr", false, "reuse & update an existing draft pr, if any")
	removeVersionCmd.Flags().StringVar(&removeVersionCmd_forkUser, "fork-user", "", "owner of winget-pkgs fork (default: user of the token)")

	removeVersionCmd.MarkFlagRequired("reason")
	removeVersionCmd.Flags().MarkHidden("reuse-draft-pr")

	rootCmd.AddCommand(removeVersionCmd)
}
