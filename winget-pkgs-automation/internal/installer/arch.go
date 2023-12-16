package installer

import (
	"encoding/binary"
	"fmt"
	"os"
	"regexp"
	"strings"
)

var (
	x64_archs       = []string{"x64", "x86_64", "64-bit", "64bit", "win64", "winx64", "ia64", "amd64"}
	x86_archs       = []string{"x86", "x32", "32-bit", "32bit", "win32", "winx86", "ia32", "i386", "i486", "i586", "i686", "386", "486", "586", "686"}
	arm64_archs     = []string{"arm64", "aarch64"}
	arm_archs       = []string{"arm", "armv7", "aarch"}
	file_extensions = strings.Join([]string{"exe", "zip", "msi", "msix", "appx", "msixbundle", "appxbundle"}, "|")
)

func getArchitectureFromUrl(url string) string {
	all_archs := strings.Join(x64_archs, "|") + "|" + strings.Join(x86_archs, "|") + "|" + strings.Join(arm64_archs, "|") + "|" + strings.Join(arm_archs, "|")
	archInUrl := regexp.MustCompile(fmt.Sprintf("(%s)(%s)(%s)|(%s)\\.(%s)", "[,/\\._-]", all_archs, "[,/\\._-]", all_archs, file_extensions)).FindAllString(url, -1)
	if len(archInUrl) == 0 {
		return ""
	}

	switch {
	case _isDetectedArchInList(archInUrl[len(archInUrl)-1], x64_archs):
		return "x64"
	case _isDetectedArchInList(archInUrl[len(archInUrl)-1], x86_archs):
		return "x86"
	case _isDetectedArchInList(archInUrl[len(archInUrl)-1], arm64_archs):
		return "arm64"
	case _isDetectedArchInList(archInUrl[len(archInUrl)-1], arm_archs):
		return "arm"
	default:
		return ""
	}
}

func _isDetectedArchInList(a string, list []string) bool {
	for _, b := range list {
		if strings.Contains(strings.ToLower(a), strings.ToLower(b)) {
			return true
		}
	}
	return false
}

func getArchitectureFromPeHeader(installerPath string) string {
	const peHeaderLocation int64 = 0x3C
	file, err := os.Open(installerPath)
	if err != nil {
		panic(fmt.Errorf("[arch-from-pe] error while opening exe to determine installer architecture: %v", err))
	}
	defer file.Close()

	// Skip DOS header
	_, err = file.Seek(peHeaderLocation, 0)
	if err != nil {
		panic(fmt.Errorf("[arch-from-pe] error while seeking to PE header: %v", err))
	}

	// Read PE offset
	var peOffset int32
	err = binary.Read(file, binary.LittleEndian, &peOffset)
	if err != nil {
		panic(fmt.Errorf("[arch-from-pe] error while reading PE offset: %v", err))
	}

	// Skip PE signature
	_, err = file.Seek(int64(peOffset)-peHeaderLocation, 1)
	if err != nil {
		panic(fmt.Errorf("[arch-from-pe] error while seeking to PE signature: %v", err))
	}

	// Read machine value from PE header
	var machine uint16
	err = binary.Read(file, binary.LittleEndian, &machine)
	if err != nil {
		panic(fmt.Errorf("[arch-from-pe] error while reading machine value: %v", err))
	}

	switch fmt.Sprintf("%x", machine) {
	case "8664":
		return "x64"
	case "14c":
		return "x86"
	case "aa64":
		return "arm64"
	case "1c0", "1c4":
		return "arm"
	default:
		return ""
	}
}
