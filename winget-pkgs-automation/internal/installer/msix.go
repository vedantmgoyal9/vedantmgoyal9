package installer

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"unicode/utf16"
)


func getMsixPackageFamilyName(msixPath, tempDir string) string {
	encodingTable := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

	appxManifest, _ := os.ReadFile(extractFileFromZip(msixPath, "AppxManifest.xml", tempDir))

	identityName := regexp.MustCompile(`(?m)<Identity.*?Name="(.+?)"`).FindStringSubmatch(string(appxManifest))[1]
	identityPublisher := regexp.MustCompile(`(?m)<Identity.*?Publisher="(.+?)"`).FindStringSubmatch(string(appxManifest))[1]

	utf16Bytes := utf16.Encode([]rune(identityPublisher))

	var binaryBuffer = new(bytes.Buffer)

	errWritingUtf16BytesToBinaryBuffer := binary.Write(binaryBuffer, binary.LittleEndian, utf16Bytes)
	if errWritingUtf16BytesToBinaryBuffer != nil {
		panic(fmt.Errorf("[msix-pfn] error writing publisher utf16 bytes to binary buffer: %v", errWritingUtf16BytesToBinaryBuffer))
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

	return identityName + "_" + result
}
