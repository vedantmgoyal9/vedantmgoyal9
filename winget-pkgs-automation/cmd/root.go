/*
Copyright © 2023 Vedant
*/
package cmd

import (
	"os"

	"github.com/spf13/cobra"
	// "github.com/elewis787/boa"
)

var rootCmd = &cobra.Command{
	Use:   "winget-pkgs-automation",
	Short: "This CLI is a part of a larger project called winget-pkgs-automation.",
	Long:  `This CLI is a part of a larger project called winget-pkgs-automation.
It was created to aid the automation, but can be used independently as well.`,
	Aliases: []string{"wpa"},
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// rootCmd.SetUsageFunc(boa.UsageFunc)
	// rootCmd.SetHelpFunc(boa.HelpFunc)
}
