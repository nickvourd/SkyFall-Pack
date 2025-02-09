package Arguments

import (
	"WorkerMan/Packages/Colors"
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

var (
	__version__      = "1.0"
	__license__      = "MIT"
	__author__       = []string{"@nickvourd", "@kavasilo"}
	__github__       = "https://github.com/nickvourd/Skyfall-Pack"
	__version_name__ = "Zero Calories"
	__ascii__        = `
 
██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗████╗ ████║██╔══██╗████╗  ██║
██║ █╗ ██║██║   ██║██████╔╝█████╔╝ █████╗  ██████╔╝██╔████╔██║███████║██╔██╗ ██║
██║███╗██║██║   ██║██╔══██╗██╔═██╗ ██╔══╝  ██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
 ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝                                                       
`

	__text__ = `
WorkerMan v%s - Parser for your Cloudflare Workers.
WorkerMan is an open source tool licensed under %s.
Written with <3 by %s && %s...
Please visit %s for more...

`

	WorkerManCli = &cobra.Command{
		Use:          "WorkerMan",
		SilenceUsage: true,
		RunE:         StartWorkerMan,
		Aliases:      []string{"workerman", "WORKERMAN"},
	}
)

// ShowAscii function
func ShowAscii() {
	// Initialize RandomColor
	randomColor := Colors.RandomColor()
	fmt.Print(randomColor(__ascii__))
	fmt.Printf(__text__, __version__, __license__, __author__[0], __author__[1], __github__)
}

// init function
// init all flags.
func init() {
	// Disable default command completion for WorkerMan CLI.
	WorkerManCli.CompletionOptions.DisableDefaultCmd = true

	// Add commands to the WorkerMan CLI.
	WorkerManCli.Flags().SortFlags = true
	WorkerManCli.Flags().BoolP("version", "v", false, "Show WorkerMan current version")
	WorkerManCli.AddCommand(buildArgument)

	// Add flags to the 'build' command.
	buildArgument.Flags().SortFlags = true
	buildArgument.Flags().StringP("teamserver", "t", "", "Set teamserver hostname/URL")
	buildArgument.Flags().StringP("worker", "w", "", "Set worker hostname/URL")
	buildArgument.Flags().StringP("name", "n", "", "Set worker name")
	buildArgument.Flags().Int32P("port", "p", 8443, "Set port for the teamserver")
	buildArgument.Flags().StringP("custom-header", "c", "X-CSRF-Token", "Set custom Header")
	buildArgument.Flags().StringP("custom-secret", "s", "MySecretValue", "Set custom Header secret value")
}

// ShowVersion function
func ShowVersion(versionFlag bool) {
	// if one argument
	if versionFlag {
		// if version flag exists
		fmt.Print("[+] Current version: " + Colors.BoldRed(__version__) + "\n\n[+] Version name: " + Colors.BoldRed(__version_name__) + "\n\n")
		os.Exit(0)
	}
}

// StartWorkerMan function
func StartWorkerMan(cmd *cobra.Command, args []string) error {
	logger := log.New(os.Stderr, "[!] ", 0)

	// Call function named ShowAscii
	ShowAscii()

	// Check if additional arguments were provided.
	if len(os.Args) == 1 {
		// Display help message.
		err := cmd.Help()

		// If error exists
		if err != nil {
			logger.Fatal("Error: ", err)
			return err
		}
	}

	// Obtain flag
	versionFlag, _ := cmd.Flags().GetBool("version")

	// Call function named ShowVersion
	ShowVersion(versionFlag)

	return nil
}
