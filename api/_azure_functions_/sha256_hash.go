package main

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

func getFileSha256Hash(filePath string) (string, error) {
	// open the file
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("error opening file for hashing: %v", err)
	}
	defer file.Close()

	// get the hash of the file using golang crypto
	hasher := sha256.New()
	_, err = io.Copy(hasher, file)
	if err != nil {
		return "", fmt.Errorf("error hashing file: %v", err)
	}

	return fmt.Sprintf("%x", hasher.Sum(nil)), nil
}
