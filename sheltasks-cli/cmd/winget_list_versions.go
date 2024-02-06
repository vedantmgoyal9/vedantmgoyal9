package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/spf13/cobra"
)

var wingetListVersionsCmd_json bool

var wingetListVersionsCmd = &cobra.Command{
	Use:     "list-versions <package-id>",
	Aliases: []string{"lv", "versions", "sv"},
	Short:   "List versions of a package, available at winget-pkgs repo",
	Args:    cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		res, err := http.Get("https://vedantmgoyal.vercel.app/api/winget-pkgs/versions/" + args[0])
		if err != nil || res.StatusCode != http.StatusOK {
			resBody, _ := io.ReadAll(res.Body)
			panic(fmt.Errorf("failed to get versions for package %s: %s", args[0], resBody))
		}
		var result struct {
			PackageIdentifier string   `json:"PackageIdentifier"`
			Versions          []string `json:"Versions"`
		}
		json.NewDecoder(res.Body).Decode(&result)

		if wingetListVersionsCmd_json {
			versions_as_json, _ := json.Marshal(result)
			cmd.Println(string(versions_as_json))
		} else {
			cmd.Println(result.PackageIdentifier)
			cmd.Println(strings.Repeat("-", len(result.PackageIdentifier)))
			for _, version := range result.Versions {
				cmd.Println(version)
			}
		}
	},
}

func init() {
	wingetListVersionsCmd.Flags().BoolVar(&wingetListVersionsCmd_json, "json", false, "output in json format")

	wingetCmd.AddCommand(wingetListVersionsCmd)
}
