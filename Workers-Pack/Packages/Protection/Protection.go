package Protection

import (
	"fmt"
	"log"
	"os"
	"strings"
)

// MandatoryFlag function
func MandatoryFlag(flag string, valueSort string, valueLong string) {
	if flag == "" {
		fmt.Printf("[!] Mandatory '-%s' or '--%s' argument is missing! Please provide this to continue...\n\n", valueSort, valueLong)
		os.Exit(1)
	}
}

// ExtractFQDN function
func ExtractFQDN(input string) string {
	// Remove http:// or https:// if present
	fqdn := strings.TrimPrefix(strings.TrimPrefix(input, "https://"), "http://")

	// Remove any path or query parameters (everything after the first /)
	if idx := strings.Index(fqdn, "/"); idx != -1 {
		fqdn = fqdn[:idx]
	}

	return fqdn
}

// ExtractWorkerName function
func ExtractWorkerName(input string) string {
	// First remove any http/https prefix
	cleaned := strings.TrimPrefix(strings.TrimPrefix(input, "https://"), "http://")

	// Check if it contains workers.dev
	if strings.Contains(cleaned, "workers.dev") {
		// Split by dots
		parts := strings.Split(cleaned, ".")
		if len(parts) > 0 {
			// Return the first part (worker name)
			return parts[0]
		}
	}

	// If no workers.dev domain found, return the original input
	return cleaned
}

// CompareNameWithWorker function
func CompareNameWithWorker(name string, worker string) string {
	// Get the original parts before extraction for subdomain check
	nameParts := strings.Split(strings.TrimPrefix(strings.TrimPrefix(name, "https://"), "http://"), ".")

	// Extract base worker names
	nameWorker := ExtractWorkerName(name)
	workerName := ExtractWorkerName(worker)

	// Compare the base worker names
	if nameWorker != workerName {
		log.Fatal("Error: The worker name is not a part of worker URL/hostname! Please provide a valid worker name...\n\n")
	}

	// Check for subdomain if it exists in the original name
	if len(nameParts) > 2 && strings.Contains(name, "workers.dev") {
		subdomain := nameParts[1] // Get the subdomain part

		// Check if the subdomain exists in the worker URL
		if !strings.Contains(worker, subdomain) {
			log.Fatal("Error: The subdomain does not match with the worker URL! Please provide a valid subdomain...\n\n")
		}
	}

	return nameWorker
}
