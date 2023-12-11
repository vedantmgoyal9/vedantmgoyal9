/*
Copyright © 2023 Vedant
*/
package cmd

import (
	"github.com/spf13/cobra"
)

var automationCmd = &cobra.Command{
	Use:   "automation",
	Short: "Run/manage automation and package jsons",
	Args: cobra.NoArgs,
	// TODO: Unhide this command when it is ready
	Hidden: true,
}

func init() {
	rootCmd.AddCommand(automationCmd)
}
