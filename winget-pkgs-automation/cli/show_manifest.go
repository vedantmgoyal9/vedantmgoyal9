/*
Copyright © 2023 Vedant
*/
package cli

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
)

var (
	showManifestCmd_outDir string
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
		if showManifestCmd_outDir != "" {
			path_to_write_manifests, err := filepath.Abs(showManifestCmd_outDir)
			if err != nil {
				panic(fmt.Errorf("failed to get absolute path of out-dir: %s", err))
			}
			if _, err := os.Stat(path_to_write_manifests); os.IsNotExist(err) {
				os.Mkdir(path_to_write_manifests, 0755)
			}
			for _, manifest := range manifests {
				cmd.Println("Manifest saved to:", filepath.Join(path_to_write_manifests, manifest.FileName))
				os.WriteFile(filepath.Join(path_to_write_manifests, manifest.FileName), []byte(manifest.Content), 0644)
			}
		}
	},
}

func init() {
	showManifestCmd.Flags().StringVarP(&showManifestCmd_outDir, "out-dir", "o", "", "output directory, to save the manifests to")

	rootCmd.AddCommand(showManifestCmd)
}
