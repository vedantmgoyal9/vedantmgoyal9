package installer

import (
	"archive/zip"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path"
)

func getFileSha256Hash(filePath string) string {
	// open the file
	file, err := os.Open(filePath)
	if err != nil {
		panic(fmt.Errorf("error opening file [%s] for hashing: %v", filePath, err))
	}
	defer file.Close()

	// get the hash of the file using golang crypto
	hasher := sha256.New()
	_, err = io.Copy(hasher, file)
	if err != nil {
		panic(fmt.Errorf("error hashing file [%s]: %v", filePath, err))
	}

	return fmt.Sprintf("%x", hasher.Sum(nil))
}

func extractFileFromZip(zipPath, filePathInsideZip, tempDir string) string {
	var extractedFilePath string

	zipReader, err := zip.OpenReader(zipPath)
	if err != nil {
		panic(fmt.Errorf("[extract-zip] error opening zip file [%s]: %v", zipPath, err))
	}
	defer zipReader.Close()

	for _, file := range zipReader.File {
		if file.Name != filePathInsideZip {
			continue
		}

		// copy the file to the current directory using io.Copy
		rc, err := file.Open()
		if err != nil {
			panic(fmt.Errorf("[extract-zip] error opening [%s] inside zip [%s]: %v", file.Name, zipPath, err))
		}
		defer rc.Close()

		// create a new file
		extractedFilePath = path.Join(tempDir, file.Name)
		newFile, err := os.Create(extractedFilePath)
		if err != nil {
			panic(fmt.Errorf("[extract-zip] error creating file [%s] for zip extraction: %v", extractedFilePath, err))
		}
		defer newFile.Close()

		// copy the file
		_, err = io.Copy(newFile, rc)
		if err != nil {
			panic(fmt.Errorf("[extract-zip] error copying file [%s] from zip [%s]: %v", file.Name, zipPath, err))
		}
	}

	if extractedFilePath == "" {
		panic(fmt.Errorf("[extract-zip] file [%s] not found inside zip [%s]", filePathInsideZip, zipPath))
	}

	return extractedFilePath
}
