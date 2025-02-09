package main

import (
	"log"
	"os"

	"WorkerMan/Packages/Arguments"
	"WorkerMan/Packages/Utils"
)

// main function
func main() {
	logger := log.New(os.Stderr, "[!] ", 0)

	// Call function named CheckGoVersion
	Utils.CheckGoVersion()

	//  WorkerManCli Execute
	err := Arguments.WorkerManCli.Execute()
	if err != nil {
		logger.Fatal("Error: ", err)
		return
	}
}
