package Output

import (
	"fmt"
	"os"
)

// WriteOutput2File function
func WriteOutput2File(content, filename string) error {
	// Open the file (or create it if it doesn't exist)
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create file: %w", err)
	}
	defer file.Close()

	// Write the content to the file
	_, err = file.WriteString(content)
	if err != nil {
		return fmt.Errorf("failed to write to file: %w", err)
	}

	return nil
}
