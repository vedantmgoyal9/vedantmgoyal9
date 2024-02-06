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
	Use:   "sheltasks-cli",
	Short: "ShelTasks: My personal CLI to streamline daily frequent tasks, for enhanced productivity.",
	Long: `ShelTasks, is a personalized CLI companion tailored for my unique needs, simplifying my daily tasks with a single command.
It's designed to enhance my productivity, handling specific routines so I can focus on what matters most to me.`,
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
	rootCmd.SetOut(os.Stdout)
	// rootCmd.SetUsageFunc(boa.UsageFunc)
	// rootCmd.SetHelpFunc(boa.HelpFunc)
}
