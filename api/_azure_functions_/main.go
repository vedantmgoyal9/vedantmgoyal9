package main

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"strings"
)

func main() {
	listenPort := ":8080"
	if val, ok := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT"); ok {
		listenPort = ":" + val
	}
	http.HandleFunc("/", getInstallerInfo)
	http.ListenAndServe(listenPort, nil)
}

func getInstallerInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	installerUrl := r.URL.Query().Get("instUri")
	if installerUrl == "" {
		http.Error(w, "instUri is either empty or not provided", http.StatusBadRequest)
		return
	}

	installerUrl, err := url.QueryUnescape(installerUrl)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while unescaping installerUrl: %v", err), http.StatusInternalServerError)
		return
	}

	installerFileName := strings.Split(installerUrl, "/")[len(strings.Split(installerUrl, "/"))-1]
	// C:\home\site\wwwroot is a read-writeable directory in Azure Functions runtime environment
	tempPath := "C:\\home\\site\\wwwroot"
	installerPath := path.Join(tempPath, installerFileName)

	resp, err := http.Get(installerUrl)
	if err != nil {
		if resp.StatusCode == 403 || resp.StatusCode == 404 {
			http.Error(w, fmt.Sprintf("Installer url is invalid. Status code: %d", resp.StatusCode), http.StatusBadRequest)
			return
		}
		http.Error(w, fmt.Sprintf("Error while downloading installer: %v", err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	out, err := os.Create(installerPath)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while creating installer file: %v", err), http.StatusInternalServerError)
		return
	}
	// using `defer` keyword executes the function when this function has reached its end, but
	// in this case, we need to close the file just after writing response body to it, so that
	// msi.dll (syscall) can access the file and open msi database for reading values from it
	// defer out.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while writing installer to file: %v", err), http.StatusInternalServerError)
		return
	}
	out.Close()

	installerInfo := make(map[string]interface{})
	installerInfo["InstallerSha256"], _ = getFileSha256Hash(installerPath)
	installerInfo["InstallerType"], _ = getInstallerType(installerPath)
	installerInfo["Architecture"], _ = getArchitectureFromPeHeader(installerPath)

	switch installerInfo["InstallerType"] {
	case "msi", "wix":
		if version, err := getMsiDbProperty("ProductVersion", installerPath); err == nil {
			installerInfo["PackageVersion"] = version
		} else {
			http.Error(w, fmt.Sprintf("Error while getting msi version: %v", err), http.StatusInternalServerError)
			return
		}
		installerInfo["ProductCode"], _ = getMsiDbProperty("ProductCode", installerPath)
		installerInfo["UpgradeCode"], _ = getMsiDbProperty("UpgradeCode", installerPath)
	case "msix", "appx":
		installerInfo["PackageFamilyName"], _ = getMsixPackageFamilyName(installerPath, tempPath)
		installerInfo["SignatureSha256"], _ = getMsixSignatureHash(installerPath, tempPath)
	default:
		var cmdOutput bytes.Buffer
		command := exec.Command("pwsh", "-Command", fmt.Sprintf("(Get-Item '%s').VersionInfo.ProductVersion.ToString()", installerPath))
		command.Stdout = &cmdOutput
		command.Run()
		installerInfo["PackageVersion"] = strings.TrimSpace(cmdOutput.String())
	}

	os.Remove(installerPath)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	err = json.NewEncoder(w).Encode(installerInfo)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while converting info to json: %v", err), http.StatusInternalServerError)
		return
	}
}

func getInstallerType(installerPath string) (string, error) {
	switch strings.ToLower(path.Ext(installerPath)) {
	case ".msix", ".msixbundle":
		return "msix", nil
	case ".appx", ".appxbundle":
		return "appx", nil
	case ".zip":
		return "zip", nil
	case ".msi":
		if _, err := getMsiDbProperty("WixUI_Mode", installerPath); err == nil {
			return "wix", nil
		}
		return "msi", nil
	case ".exe":
		file, err := os.Open(installerPath)
		if err != nil {
			return "", fmt.Errorf("error while opening exe to determine installer type: %v", err)
		}
		defer file.Close()

		fileInfo, err := file.Stat()
		if err != nil {
			return "", fmt.Errorf("error while getting exe file info: %v", err)
		}
		magicBytes := make([]byte, fileInfo.Size())
		_, err = file.Read(magicBytes)
		if err != nil {
			return "", fmt.Errorf("error while reading exe file: %v", err)
		}

		if bytes.HasPrefix(magicBytes, nullsoftBytes) {
			return "nullsoft", nil
		} else if bytes.HasPrefix(magicBytes, innoBytes) {
			return "inno", nil
		} else if bytes.Contains(magicBytes, burnBytes) {
			return "burn", nil
		} else {
			return "exe", nil
		}
	default:
		return "unknown", nil
	}
}

func getArchitectureFromPeHeader(installerPath string) (string, error) {
	const peHeaderLocation int64 = 0x3C
	file, err := os.Open(installerPath)
	if err != nil {
		return "", fmt.Errorf("error while opening exe to determine installer architecture: %v", err)
	}
	defer file.Close()

	// Skip DOS header
	_, err = file.Seek(peHeaderLocation, 0)
	if err != nil {
		return "", fmt.Errorf("error while seeking to PE header: %v", err)
	}

	// Read PE offset
	var peOffset int32
	err = binary.Read(file, binary.LittleEndian, &peOffset)
	if err != nil {
		return "", fmt.Errorf("error while reading PE offset: %v", err)
	}

	// Skip PE signature
	_, err = file.Seek(int64(peOffset)-peHeaderLocation, 1)
	if err != nil {
		return "", fmt.Errorf("error while seeking to PE signature: %v", err)
	}

	// Read machine value from PE header
	var machine uint16
	err = binary.Read(file, binary.LittleEndian, &machine)
	if err != nil {
		return "", fmt.Errorf("error while reading machine value: %v", err)
	}

	switch fmt.Sprintf("%x", machine) {
	case "8664":
		return "x64", nil
	case "14c":
		return "x86", nil
	case "aa64":
		return "arm64", nil
	case "1c0", "1c4":
		return "arm", nil
	default:
		return "x64", nil
	}
}

var (
	burnBytes     = []byte{0x2E, 0x77, 0x69, 0x78, 0x62, 0x75, 0x72, 0x6E}
	innoBytes     = []byte{77, 90, 80, 0, 2, 0, 0, 0, 4, 0, 15, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 186, 16, 0, 14, 31, 180, 9, 205, 33, 184, 1, 76, 205, 33, 144, 144, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 109, 117, 115, 116, 32, 98, 101, 32, 114, 117, 110, 32, 117, 110, 100, 101, 114, 32, 87, 105, 110, 51, 50, 13, 10, 36, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 10, 0}
	nullsoftBytes = []byte{77, 90, 144, 0, 3, 0, 0, 0, 4, 0, 0, 0, 255, 255, 0, 0, 184, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 216, 0, 0, 0, 14, 31, 186, 14, 0, 180, 9, 205, 33, 184, 1, 76, 205, 33, 84, 104, 105, 115, 32, 112, 114, 111, 103, 114, 97, 109, 32, 99, 97, 110, 110, 111, 116, 32, 98, 101, 32, 114, 117, 110, 32, 105, 110, 32, 68, 79, 83, 32, 109, 111, 100, 101, 46, 13, 13, 10, 36, 0, 0, 0, 0, 0, 0, 0, 173, 49, 8, 129, 233, 80, 102, 210, 233, 80, 102, 210, 233, 80, 102, 210, 42, 95, 57, 210, 235, 80, 102, 210, 233, 80, 103, 210, 76, 80, 102, 210, 42, 95, 59, 210, 230, 80, 102, 210, 189, 115, 86, 210, 227, 80, 102, 210, 46, 86, 96, 210, 232, 80, 102, 210, 82, 105, 99, 104, 233, 80, 102, 210, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 69, 0, 0, 76, 1, 5, 0}
)
