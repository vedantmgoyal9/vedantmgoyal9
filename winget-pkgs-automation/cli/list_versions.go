/*
Copyright © 2023 Vedant
*/
package cli

import (
	"encoding/json"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
)

var (
	listVersionsCmd_json bool
)

var listVersionsCmd = &cobra.Command{
	Use:     "list-versions <package-id>",
	Aliases: []string{"lv", "versions"},
	Short:   "List versions of a package, available at winget-pkgs repo",
	Args:    cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		versions := github.GetWinGetPackageVersions(args[0])
		if listVersionsCmd_json {
			versions_as_json, _ := json.Marshal(versions)
			cmd.Println(string(versions_as_json))
		} else {
			for _, version := range versions {
				cmd.Println(version)
			}
		}
	},
}

func init() {
	listVersionsCmd.Flags().BoolVar(&listVersionsCmd_json, "json", false, "output in json format")

	rootCmd.AddCommand(listVersionsCmd)
}
