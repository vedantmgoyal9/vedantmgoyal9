package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal9/vedantmgoyal9/sheltasks-cli/github"
)

var (
	winget_removeVersionCmd_reason       string
	winget_removeVersionCmd_reuseDraftPr bool
	winget_removeVersionCmd_forkUser     string
)

var winget_removeVersionCmd = &cobra.Command{
	Use:     "winget-rmver <package-id> <version>",
	Aliases: []string{"wrv"},
	Short:   "Remove a package version from winget-pkgs",
	Args:    cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		res, err := http.Get("https://vedantmgoyal.vercel.app/api/winget-pkgs/manifests/" + args[0] + "/" + args[1])
		if err != nil || res.StatusCode != http.StatusOK {
			resBody, _ := io.ReadAll(res.Body)
			panic(fmt.Errorf("failed to get manifests for package %s: %s", args[0], resBody))
		}
		var manifests []struct {
			FileName string `json:"FileName"`
			Content  string `json:"Content"`
		}
		json.NewDecoder(res.Body).Decode(&manifests)

		var removedManifests []github.WinGetManifest
		for _, manifest := range manifests {
			removedManifests = append(removedManifests, github.WinGetManifest{
				FileName: manifest.FileName,
				Content:  "", // empty content to remove the manifest
			})
		}

		github.SubmitManifests(args[0], args[1], removedManifests, github.RmVerCommit, winget_removeVersionCmd_forkUser, winget_removeVersionCmd_reuseDraftPr, winget_removeVersionCmd_reason)
	},
}

func init() {
	winget_removeVersionCmd.Flags().StringVarP(&winget_removeVersionCmd_reason, "reason", "r", "", "reason for deleting the manifest (required)")
	winget_removeVersionCmd.Flags().BoolVar(&winget_removeVersionCmd_reuseDraftPr, "reuse-draft-pr", false, "reuse & update an existing draft pr, if any")
	winget_removeVersionCmd.Flags().StringVar(&winget_removeVersionCmd_forkUser, "fork-user", "", "owner of winget-pkgs fork (default: user of the token)")

	winget_removeVersionCmd.MarkFlagRequired("reason")
	winget_removeVersionCmd.Flags().MarkHidden("reuse-draft-pr")

	rootCmd.AddCommand(winget_removeVersionCmd)
}
