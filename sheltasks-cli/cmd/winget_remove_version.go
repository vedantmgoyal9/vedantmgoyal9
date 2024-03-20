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
	removeVersionCmd_reason       string
	removeVersionCmd_reuseDraftPr bool
	removeVersionCmd_forkUser     string
)

var removeVersionCmd = &cobra.Command{
	Use:     "remove-version <package-id> <version>",
	Aliases: []string{"r", "rm", "rmver", "delete", "del", "remove"},
	Short:   "Remove a package version",
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

		github.SubmitManifests(args[0], args[1], removedManifests, github.RmVerCommit, removeVersionCmd_forkUser, removeVersionCmd_reuseDraftPr, removeVersionCmd_reason)
	},
}

func init() {
	removeVersionCmd.Flags().StringVarP(&removeVersionCmd_reason, "reason", "r", "", "reason for deleting the manifest (required)")
	removeVersionCmd.Flags().BoolVar(&removeVersionCmd_reuseDraftPr, "reuse-draft-pr", false, "reuse & update an existing draft pr, if any")
	removeVersionCmd.Flags().StringVar(&removeVersionCmd_forkUser, "fork-user", "", "owner of winget-pkgs fork (default: user of the token)")

	removeVersionCmd.MarkFlagRequired("reason")
	removeVersionCmd.Flags().MarkHidden("reuse-draft-pr")

	wingetCmd.AddCommand(removeVersionCmd)
}
