package Protection

import (
	"fmt"
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
