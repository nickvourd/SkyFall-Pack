package Arguments

import (
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

// buildArgument represents the 'build' command in the CLI.
var buildArgument = &cobra.Command{
	// Use defines how the command should be called.
	Use:          "build",
	Short:        "Generate and configure wrangler.json, index.js, and nginx's default site configuration",
	SilenceUsage: true,
	Aliases:      []string{"BUILD", "Build"},

	// RunE defines the function to run when the command is executed.
	RunE: func(cmd *cobra.Command, args []string) error {
		logger := log.New(os.Stderr, "[!] ", 0)

		// Show ASCII banner
		ShowAscii()

		// Check if additional arguments were provided
		if len(os.Args) <= 2 {
			err := cmd.Help()
			if err != nil {
				logger.Fatal("Error ", err)
				return err
			}
			os.Exit(0)
		}

		// Parse the arguments
		teamserver, _ := cmd.Flags().GetString("teamserver")
		worker, _ := cmd.Flags().GetString("worker")
		name, _ := cmd.Flags().GetString("name")
		port, _ := cmd.Flags().GetString("port")
		customHeader, _ := cmd.Flags().GetString("custom-header")
		customSecret, _ := cmd.Flags().GetString("custom-secret")

		fmt.Print(teamserver, worker, name, port, customHeader, customSecret)

		return nil
	},
}
