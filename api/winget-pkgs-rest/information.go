package handler

import (
	"encoding/json"
	"net/http"
)

// #route /api/winget-pkgs-rest/information
func Information(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]map[string]interface{}{
		"Data": {
			"SourceIdentifier":        "winget-pkgs-rest",
			"ServerSupportedVersions": []string{"1.6.0"},
		},
	})
}
