package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var (
	wingetShowManifestCmd_outDir string
)

var wingetShowManifestCmd = &cobra.Command{
	Use:     "show-manifest <package-id> <version>",
	Aliases: []string{"show", "sm", "view", "vm"},
	Short:   "Show manifests of a package from winget-pkgs repo",
	Args:    cobra.RangeArgs(1, 2),
	Run: func(cmd *cobra.Command, args []string) {
		version := "latest"
		if len(args) == 2 {
			version = args[1]
		}

		res, err := http.Get("https://vedantmgoyal.vercel.app/api/winget-pkgs/manifests/" + args[0] + "/" + version)
		if err != nil || res.StatusCode != http.StatusOK {
			resBody, _ := io.ReadAll(res.Body)
			panic(fmt.Errorf("failed to get manifests for package %s: %s", args[0], resBody))
		}
		var manifests []struct {
			FileName string `json:"FileName"`
			Content  string `json:"Content"`
		}
		json.NewDecoder(res.Body).Decode(&manifests)

		for _, manifest := range manifests {
			cmd.Println(strings.Repeat("-", len(manifest.FileName)+1))
			cmd.Println(manifest.FileName)
			cmd.Println(strings.Repeat("-", len(manifest.FileName)+1))

			cmd.Println("\n" + strings.Trim(manifest.Content, "\n") + "\n")
		}
		if wingetShowManifestCmd_outDir != "" {
			path_to_write_manifests, err := filepath.Abs(wingetShowManifestCmd_outDir)
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
	wingetShowManifestCmd.Flags().StringVarP(&wingetShowManifestCmd_outDir, "out-dir", "o", "", "output directory, to save the manifests to")

	wingetCmd.AddCommand(wingetShowManifestCmd)
}
