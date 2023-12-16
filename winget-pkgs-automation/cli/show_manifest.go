/*
Copyright © 2023 Vedant
*/
package cli

import (
	"strings"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
)

var showManifestCmd = &cobra.Command{
	Use:     "show-manifest <package-id> <version>",
	Aliases: []string{"show", "sm", "view", "vm"},
	Short:   "Show manifests of a package from winget-pkgs repo",
	Args:    cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		manifests := github.GetWinGetManifests(args[0], args[1])
		for _, manifest := range manifests {
			cmd.Println(strings.Repeat("-", len(manifest.FileName)+1))
			cmd.Println(manifest.FileName)
			cmd.Println(strings.Repeat("-", len(manifest.FileName)+1))

			cmd.Println("\n" + strings.Trim(manifest.Content, "\n") + "\n")
		}
	},
}

func init() {
	rootCmd.AddCommand(showManifestCmd)
}
