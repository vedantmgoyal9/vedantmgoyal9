package installer

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"strings"

	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/pkg/msi"
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

	tempDir, err := os.MkdirTemp("", "wgpkgs-cli-*")
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
	installerInfo["InstallerSha256"] = getFileSha256Hash(installerPath)
	installerInfo["InstallerType"] = getInstallerType(installerPath)

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
	burnBytes     = []byte{0x2E, 0x77, 0x69, 0x78, 0x62, 0x75, 0x72, 0x6E}
	innoBytes     = []byte{77, 90, 80, 0, 2, 0, 0, 0, 4, 0, 15, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 186, 16, 0, 14, 31, 180, 9, 205, 33, 184, 1, 76, 205, 33, 144, 144, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 109, 117, 115, 116, 32, 98, 101, 32, 114, 117, 110, 32, 117, 110, 100, 101, 114, 32, 87, 105, 110, 51, 50, 13, 10, 36, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 10, 0}
	nullsoftBytes = []byte{77, 90, 144, 0, 3, 0, 0, 0, 4, 0, 0, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 216, 0, 0, 0, 14, 31, 186, 14, 0, 180, 9, 205, 33, 184, 1, 76, 205, 33, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 99, 97, 110, 110, 111, 116, 32, 98, 101, 32, 114, 117, 110, 32, 105, 110, 32, 68, 79, 83, 32, 109, 111, 100, 101, 46, 13, 13, 10, 36, 0, 0, 0, 0, 0, 0, 0, 173, 49, 8, 129, 233, 80, 102, 210, 233, 80, 102, 210, 233, 80, 102, 210, 42, 95, 57, 210, 235, 80, 102, 210, 233, 80, 103, 210, 76, 80, 102, 210, 42, 95, 59, 210, 230, 80, 102, 210, 189, 115, 86, 210, 227, 80, 102, 210, 46, 86, 96, 210, 232, 80, 102, 210, 82, 105, 99, 104, 233, 80, 102, 210, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 5, 0}
)
