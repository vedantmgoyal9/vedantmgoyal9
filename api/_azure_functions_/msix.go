package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"os"
	"path"
	"regexp"
	"strconv"
	"strings"
	"unicode/utf16"
)

func getMsixPackageFamilyName(msixPath, extractPath string) (string, error) {
	encodingTable := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
	err := extractFileFromZip(msixPath, "AppxManifest.xml", extractPath)
	if err != nil {
		return "", fmt.Errorf("error extracting AppxManifest.xml from msix: %v", err)
	}
	appxManifest, _ := os.ReadFile(path.Join(extractPath, "AppxManifest.xml"))
	identityName := regexp.MustCompile(`(?m)<Identity.*?Name="(.+?)"`).FindStringSubmatch(string(appxManifest))[1]
	identityPublisher := regexp.MustCompile(`(?m)<Identity.*?Publisher="(.+?)"`).FindStringSubmatch(string(appxManifest))[1]
	utf16Bytes := utf16.Encode([]rune(identityPublisher))
	var binaryBuffer = new(bytes.Buffer)
	errWritingUtf16BytesToBinaryBuffer := binary.Write(binaryBuffer, binary.LittleEndian, utf16Bytes)
	if errWritingUtf16BytesToBinaryBuffer != nil {
		return "", fmt.Errorf("error writing publisher utf16 bytes to binary buffer: %v", err)
	}
	publisherUnicodeSha256 := sha256.Sum256(binaryBuffer.Bytes())
	var sha256HashBytesInBinary, result string
	for _, char := range publisherUnicodeSha256[:8] {
		sha256HashBytesInBinary += fmt.Sprintf("%08b", char)
	}
	sha256HashBytesInBinary += strings.Repeat("0", 65-len(sha256HashBytesInBinary))
	for i := 0; i < len(sha256HashBytesInBinary); i += 5 {
		index, _ := strconv.ParseInt(sha256HashBytesInBinary[i:i+5], 2, 64)
		result += string(encodingTable[index])
	}
	return identityName + "_" + result, nil
}

func getMsixSignatureHash(msixPath, extractPath string) (string, error) {
	err := extractFileFromZip(msixPath, "AppxSignature.p7x", extractPath)
	if err != nil {
		return "", fmt.Errorf("error extracting AppxSignature.p7x from msix: %v", err)
	}
	sha256Hash, err := getFileSha256Hash(path.Join(extractPath, "AppxSignature.p7x"))
	if err != nil {
		return "", fmt.Errorf("error getting sha256 hash of AppxSignature.p7x: %v", err)
	}
	return sha256Hash, nil
}
