package cmd

import (
	"github.com/spf13/cobra"
)

var wingetCmd = &cobra.Command{
	Use:                   "winget",
	Short:                 "Commands related to winget-pkgs (windows package manager)",
	Aliases:               []string{"w", "wg", "win"},
	DisableFlagsInUseLine: true,
	DisableFlagParsing:    true,
}

func init() {
	rootCmd.AddCommand(wingetCmd)
}
