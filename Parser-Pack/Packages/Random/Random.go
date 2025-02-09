package Random

import (
	"time"

	"golang.org/x/exp/rand"
)

// GenerateRandomVariableName function
func GenerateRandomVariableName() (string, string, string) {
	const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	rand.Seed(uint64(time.Now().UnixNano()))

	// Helper function to generate one random name
	generateName := func() string {
		// Random length between 4 and 7
		length := rand.Intn(4) + 4

		// Create byte slice for the name
		name := make([]byte, length)

		// First character must be a capital letter
		name[0] = letters[rand.Intn(len(letters))]

		// Rest can include numbers and any case letters
		for i := 1; i < length; i++ {
			name[i] = charset[rand.Intn(len(charset))]
		}

		return string(name)
	}

	// Generate three different names
	name1 := generateName()
	name2 := generateName()
	name3 := generateName()

	return name1, name2, name3
}
