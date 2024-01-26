package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"slices"

	"sigs.k8s.io/kustomize/kyaml/yaml"
)

// #route /api/winget-pkgs-rest/packageManifests?package_identifier={package_identifier}
func PackageManifests(w http.ResponseWriter, r *http.Request) {
	// only allow GET requests
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	pkg_id := r.URL.Query().Get("package_identifier")
	if pkg_id == "" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "package_identifier query parameter is required")
		return
	}

	manifests := []ManifestsApiResponse{}

	res, err := http.Get("https://vedantmgoyal.vercel.app/api/winget-pkgs/manifests/" + pkg_id)
	// error will only be of type *url.Error, so added check for status code as well
	if err != nil || res.StatusCode != http.StatusOK {
		// we assume that the error is because the package was not found because
		// the API seems to be stable 🙂 and the only error that can occur is when the package is not found
		w.WriteHeader(http.StatusNoContent)
		fmt.Fprintf(w, "package %s not found in winget-pkgs (https://github.com/microsoft/winget-pkgs)", pkg_id)
		return
	}
	defer res.Body.Close()
	json.NewDecoder(res.Body).Decode(&manifests)

	var installers, default_locale, package_version interface{}
	for _, manifest_raw := range manifests {
		manifest := yaml.MustParse(manifest_raw.Content + "\n---\n")
		switch manifest.Field("ManifestType").Value.YNode().Value {
		case "installer":
			// copy from root level to installer level
			_installers, _ := manifest.GetSlice("Installers")
			no_of_installers := len(_installers)
			for _, field := range common_fields_root_and_installer {
				root_level_value, _ := manifest.Pipe(yaml.Get(field))
				if root_level_value == nil {
					continue
				}
				for i := 0; i < no_of_installers; i++ {
					if installer_level_value, _ := manifest.Pipe(yaml.Lookup("Installers"),
						yaml.Lookup(fmt.Sprintf("%d", i)),
						yaml.Get(field)); installer_level_value == nil {
						manifest.PipeE(yaml.Lookup("Installers"),
							yaml.Lookup(fmt.Sprintf("%d", i)),
							yaml.SetField(field, root_level_value))
					} else if installer_level_value.YNode().Kind == yaml.MappingNode {
						root_level_value_map, installer_level_keys := map[string]string{}, []string{}
						root_level_value.VisitFields(func(node *yaml.MapNode) error {
							root_level_value_map[node.Key.YNode().Value] = node.Value.YNode().Value
							return nil
						})
						installer_level_value.VisitFields(func(node *yaml.MapNode) error {
							installer_level_keys = append(installer_level_keys, node.Key.YNode().Value)
							return nil
						})
						for root_level_value_map_key, root_level_value_map_value := range root_level_value_map {
							if !slices.Contains(installer_level_keys, root_level_value_map_key) {
								manifest.PipeE(yaml.Lookup("Installers"),
									yaml.Lookup(fmt.Sprintf("%d", i)),
									yaml.Lookup(field),
									yaml.SetField(root_level_value_map_key, yaml.NewStringRNode(root_level_value_map_value)))
							}
						}
					}
				}
				manifest.PipeE(yaml.Clear(field))
			}

			installers_new, _ := manifest.Pipe(yaml.Get("Installers"))
			yaml.Unmarshal([]byte(installers_new.MustString()), &installers)
		case "defaultLocale":
			manifest.PipeE(yaml.Clear("PackageIdentifier"))
			manifest.PipeE(yaml.Clear("PackageVersion"))
			manifest.PipeE(yaml.Clear("ManifestType"))
			manifest.PipeE(yaml.Clear("ManifestVersion"))

			yaml.Unmarshal([]byte(manifest.MustString()), &default_locale)
		case "version":
			package_version = manifest.Field("PackageVersion").Value.YNode().Value
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]map[string]interface{}{
		"Data": {
			"PackageIdentifier": pkg_id,
			"Versions": []interface{}{
				interface{}(map[string]interface{}{
					"PackageVersion": package_version,
					"DefaultLocale":  default_locale,
					"Installers":     installers,
					"Locales":        nil,
				}),
			},
		},
	})
}

type ManifestsApiResponse struct {
	FileName string `json:"FileName"`
	Content  string `json:"Content"`
}

var common_fields_root_and_installer = []string{
	"InstallerLocale",
	"Platform",
	"MinimumOSVersion",
	"InstallerType",
	"NestedInstallerType",
	"NestedInstallerFiles",
	"Scope",
	"InstallModes",
	"InstallerSwitches",
	"InstallerSuccessCodes",
	"ExpectedReturnCodes",
	"UpgradeBehavior",
	"Commands",
	"Protocols",
	"FileExtensions",
	"Dependencies",
	"PackageFamilyName",
	"ProductCode",
	"Capabilities",
	"RestrictedCapabilities",
	"Markets",
	"InstallerAbortsTerminal",
	"ReleaseDate",
	"InstallLocationRequired",
	"RequireExplicitUpgrade",
	"DisplayInstallWarnings",
	"UnsupportedOSArchitectures",
	"UnsupportedArguments",
	"AppsAndFeaturesEntries",
	"ElevationRequirement",
	"InstallationMetadata",
}
