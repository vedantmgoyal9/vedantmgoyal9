package main

import (
	"archive/zip"
	"fmt"
	"io"
	"os"
	"path"
)

func extractFileFromZip(zipPath, filePathInsideZip, toPath string) error {
	zipReader, err := zip.OpenReader(zipPath)
	if err != nil {
		return fmt.Errorf("error opening zip file: %v", err)
	}
	defer zipReader.Close()

	for _, file := range zipReader.File {
		if file.Name != filePathInsideZip {
			continue
		}

		// copy the file to the current directory using io.Copy
		rc, err := file.Open()
		if err != nil {
			return fmt.Errorf("error opening file inside zip: %v", err)
		}
		defer rc.Close()

		// create a new file
		newFile, err := os.Create(path.Join(toPath, file.Name))
		if err != nil {
			return fmt.Errorf("error creating file for zip extraction: %v", err)
		}
		defer newFile.Close()

		// copy the file
		_, err = io.Copy(newFile, rc)
		if err != nil {
			return fmt.Errorf("error copying file from zip: %v", err)
		}
	}
	return nil
}
