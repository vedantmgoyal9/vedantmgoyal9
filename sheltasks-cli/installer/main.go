/*
Copyright © 2023 Vedant
*/
package installer

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strings"

	"github.com/vedantmgoyal9/vedantmgoyal9/sheltasks-cli/msi"
)

var cache_installerInfo = map[string]map[string]string{}

func DownloadAndGetInfo(installerUrl string) map[string]string {
	if installerInfo, ok := cache_installerInfo[installerUrl]; ok {
		return installerInfo
	}

	installerUrl, err := url.QueryUnescape(installerUrl)
	if err != nil {
		panic(fmt.Errorf("error while unescaping installerUrl: %v", err))
	}

	resp, err := http.Get(installerUrl)
	if err != nil {
		panic(fmt.Errorf("error while downloading installer: %v", err))
	}
	// a non-2xx response doesn't cause an error, so we need to check it manually
	if resp.StatusCode >= 400 && resp.StatusCode <= 599 { // 400-499: client error; 500-599: server error;
		panic(fmt.Errorf("installer url is invalid. status code: %d", resp.StatusCode))
	}
	defer resp.Body.Close()

	tempDir, err := os.MkdirTemp("", "sheltasks-cli-*")
	if err != nil {
		panic(fmt.Errorf("error while creating temp dir for downloading installer: %v", err))
	}
	defer os.RemoveAll(tempDir)

	installerPath := path.Join(tempDir, path.Base(installerUrl))
	out, err := os.Create(installerPath)
	if err != nil {
		panic(fmt.Errorf("error while creating installer file: %v", err))
	}
	// using `defer` keyword executes the function when this function has reached its end, but
	// in this case, we need to close the file just after writing response body to it, so that
	// msi.dll (syscall) can access the file and open msi database for reading values from it
	// defer out.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		panic(fmt.Errorf("error while writing installer to file: %v", err))
	}
	out.Close() // closing the file here

	installerInfo := make(map[string]string)
	installerInfo["InstallerUrl"] = installerUrl
	installerInfo["InstallerSha256"] = getFileSha256Hash(installerPath)
	installerInfo["InstallerType"] = getInstallerType(installerPath)

	// get scope from url, (warning) may result in false positives
	if strings.Contains(strings.ToLower(installerUrl), "user") {
		installerInfo["Scope"] = "user"
	} else if strings.Contains(strings.ToLower(installerUrl), "machine") {
		installerInfo["Scope"] = "machine"
	}

	// get architecture from url, if not found, get it from pe header
	installerInfo["Architecture"] = getArchitectureFromUrl(installerUrl)
	if installerInfo["Architecture"] == "" {
		installerInfo["Architecture"] = getArchitectureFromPeHeader(installerPath)
	}

	switch installerInfo["InstallerType"] {
	case "msi", "wix":
		installerInfo["Publisher"], _ = msi.GetProperty("Manufacturer", installerPath)
		installerInfo["PackageVersion"], _ = msi.GetProperty("ProductVersion", installerPath)
		installerInfo["ProductCode"], _ = msi.GetProperty("ProductCode", installerPath)
		installerInfo["UpgradeCode"], _ = msi.GetProperty("UpgradeCode", installerPath)
		installerInfo["InstallerLocale"], _ = msi.GetLocale(installerPath)
		installerInfo["Scope"], _ = msi.GetScope(installerPath)
	case "msix", "appx":
		installerInfo["PackageFamilyName"] = getMsixPackageFamilyName(installerPath, tempDir)
		installerInfo["SignatureSha256"] = getFileSha256Hash(extractFileFromZip(installerPath, "AppxSignature.p7x", tempDir))
	default:
		// TODO: Get package version from exe (fix this...)
		var cmdOutput bytes.Buffer
		command := exec.Command("pwsh", "-Command", fmt.Sprintf("(Get-Item '%s').VersionInfo.ProductVersion.ToString()", installerPath))
		command.Stdout = &cmdOutput
		command.Run()
		installerInfo["PackageVersion"] = strings.TrimSpace(cmdOutput.String())
	}

	for key, value := range installerInfo {
		if value == "" { // delete empty values
			delete(installerInfo, key)
		}
	}

	cache_installerInfo[installerUrl] = installerInfo
	return installerInfo
}

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

func getInstallerType(installerPath string) string {
	switch strings.ToLower(path.Ext(installerPath)) {
	case ".msix", ".msixbundle":
		return "msix"
	case ".appx", ".appxbundle":
		return "appx"
	case ".zip":
		return "zip"
	case ".msi":
		if _, err := msi.GetProperty("WixUI_Mode", installerPath); err == nil {
			return "wix"
		}
		return "msi"
	case ".exe":
		file, err := os.Open(installerPath)
		if err != nil {
			panic(fmt.Errorf("[installer-type] error while opening exe: %v", err))
		}
		defer file.Close()

		fileInfo, err := file.Stat()
		if err != nil {
			panic(fmt.Errorf("[installer-type] error while getting exe file info: %v", err))
		}

		magicBytes := make([]byte, fileInfo.Size())
		if _, err = file.Read(magicBytes); err != nil {
			panic(fmt.Errorf("[installer-type] error while reading exe file: %v", err))
		}

		if bytes.HasPrefix(magicBytes, nullsoftBytes) {
			return "nullsoft"
		} else if bytes.HasPrefix(magicBytes, innoBytes) {
			return "inno"
		} else if bytes.Contains(magicBytes, burnBytes) {
			return "burn"
		} else {
			return "exe"
		}
	default:
		panic(fmt.Errorf("[installer-type] unknown installer type"))
	}
}

var (
	burnBytes     = []byte{0x2E, 0x77, 0x69, 0x78, 0x62, 0x75, 0x72, 0x6E} // .wixburn
	innoBytes     = []byte{77, 90, 80, 0, 2, 0, 0, 0, 4, 0, 15, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 186, 16, 0, 14, 31, 180, 9, 205, 33, 184, 1, 76, 205, 33, 144, 144, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 109, 117, 115, 116, 32, 98, 101, 32, 114, 117, 110, 32, 117, 110, 100, 101, 114, 32, 87, 105, 110, 51, 50, 13, 10, 36, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 10, 0}
	nullsoftBytes = []byte{77, 90, 144, 0, 3, 0, 0, 0, 4, 0, 0, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 216, 0, 0, 0, 14, 31, 186, 14, 0, 180, 9, 205, 33, 184, 1, 76, 205, 33, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 99, 97, 110, 110, 111, 116, 32, 98, 101, 32, 114, 117, 110, 32, 105, 110, 32, 68, 79, 83, 32, 109, 111, 100, 101, 46, 13, 13, 10, 36, 0, 0, 0, 0, 0, 0, 0, 173, 49, 8, 129, 233, 80, 102, 210, 233, 80, 102, 210, 233, 80, 102, 210, 42, 95, 57, 210, 235, 80, 102, 210, 233, 80, 103, 210, 76, 80, 102, 210, 42, 95, 59, 210, 230, 80, 102, 210, 189, 115, 86, 210, 227, 80, 102, 210, 46, 86, 96, 210, 232, 80, 102, 210, 82, 105, 99, 104, 233, 80, 102, 210, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 5, 0}
)
