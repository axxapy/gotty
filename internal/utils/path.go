package utils

import (
	"os"
	"strings"
)

// ExpandHome replaces a leading "~/" in path with the current user's home directory.
// If the home directory cannot be determined, path is returned unchanged.
func ExpandHome(path string) string {
	if !strings.HasPrefix(path, "~/") {
		return path
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return path
	}
	return home + path[1:]
}
