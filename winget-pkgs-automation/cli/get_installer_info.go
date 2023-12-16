/*
Copyright © 2023 Vedant
*/
package cli

import (
	"encoding/json"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/installer"
)

var getInstallerInfoCmd_json bool

var getInstallerInfoCmd = &cobra.Command{
	Use:     "get-installer-info <installer-url>",
	Aliases: []string{"gii"},
	Short:   "Get information about the installer",
	Args:    cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		installer_info := installer.DownloadAndGetInfo(args[0])

		if getInstallerInfoCmd_json {
			installer_info_as_json, _ := json.Marshal(installer_info)
			cmd.Println(string(installer_info_as_json))
		} else {
			cmd.Println("Downloading installer... This may take a while.")
			cmd.Println("Property\tValue")
			cmd.Println("--------\t-----")
			for key, value := range installer_info {
				cmd.Printf("%v\t%v\n", key, value)
			}
		}
	},
}

func init() {
	getInstallerInfoCmd.Flags().BoolVar(&getInstallerInfoCmd_json, "json", false, "output in json format")

	rootCmd.AddCommand(getInstallerInfoCmd)
}
