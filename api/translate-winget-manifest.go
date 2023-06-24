package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"

	"gopkg.in/yaml.v3"
)

func TranslateManifest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if r.Body == nil {
		http.Error(w, "Request body is empty", http.StatusBadRequest)
		return
	}

	var requestBody struct {
		LocaleYaml  string `json:"localeYaml"`
		TranslateTo string `json:"translateTo"`
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while reading request body: %v", err), http.StatusInternalServerError)
		return
	}

	err = json.Unmarshal(body, &requestBody)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while decoding manifest: %v", err), http.StatusInternalServerError)
		return
	}

	var manifest, localeSchema, sortedManifest map[string]interface{}
	err = yaml.Unmarshal([]byte(requestBody.LocaleYaml), &manifest)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error whileparsing manifest: %v", err), http.StatusInternalServerError)
		return
	}

	for i, tag := range manifest["Tags"].([]interface{}) {
		manifest["Tags"].([]interface{})[i] = getTranslation(tag.(string), requestBody.TranslateTo)
	}

	manifest["Author"] = getTranslation(manifest["Author"].(string), requestBody.TranslateTo)
	manifest["License"] = getTranslation(manifest["License"].(string), requestBody.TranslateTo)
	manifest["Copyright"] = getTranslation(manifest["Copyright"].(string), requestBody.TranslateTo)
	manifest["ShortDescription"] = getTranslation(manifest["ShortDescription"].(string), requestBody.TranslateTo)
	manifest["Description"] = getTranslation(manifest["Description"].(string), requestBody.TranslateTo)
	manifest["ReleaseNotes"] = getTranslation(manifest["ReleaseNotes"].(string), requestBody.TranslateTo)

	req, err := http.NewRequest("GET", "https://raw.githubusercontent.com/microsoft/winget-cli/master/schemas/JSON/manifests/v1.4.0/manifest.locale.1.4.0.json", nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("error while creating request to get manifest schema: %v", err), http.StatusInternalServerError)
		return
	}

	res, err := (&http.Client{}).Do(req)
	if err != nil {
		http.Error(w, fmt.Sprintf("error while getting manifest schema: %v", err), http.StatusInternalServerError)
		return
	}

	err = json.NewDecoder(res.Body).Decode(&localeSchema)
	if err != nil {
		http.Error(w, fmt.Sprintf("error while parsing manifest schema: %v", err), http.StatusInternalServerError)
		return
	}

	sortedManifest = make(map[string]interface{}, len(manifest))
	for key := range localeSchema["properties"].(map[string]interface{}) {
		if _, ok := manifest[key]; ok {
			sortedManifest[key] = manifest[key]
		}
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	err = yaml.NewEncoder(w).Encode(manifest)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error while converting translated manifest back to yaml: %v", err), http.StatusInternalServerError)
		return
	}
}

func getTranslation(str, lang string) string {
	req, err := http.NewRequest("GET", "https://t.song.work/api?text="+url.QueryEscape(str)+"&from=auto&to="+lang, nil)
	if err != nil {
		return fmt.Sprintf("error creating request to get translation: %v\n", err)
	}

	res, err := (&http.Client{}).Do(req)
	if err != nil {
		return fmt.Sprintf("error getting translation: %v\n", err)
	}

	var res_json map[string]interface{}
	err = json.NewDecoder(res.Body).Decode(&res_json)
	if err != nil {
		return fmt.Sprintf("error parsing translation response: %v\n", err)
	}

	return res_json["result"].(string)
}
