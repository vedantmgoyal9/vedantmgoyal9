/*
Copyright © 2023 Vedant
*/
package cli

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"strings"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/installer"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

var (
	updateCmd_instUrls      []string
	updateCmd_moreInfo_json string
	updateCmd_outDir        string
	updateCmd_submit        bool
	updateCmd_reuseDraftPr  bool
	updateCmd_forkUser      string
)

var updateCmd = &cobra.Command{
	Use:     "update <package-id> <version>",
	Aliases: []string{"up", "upgrade"},
	Short:   "Update package manifests in winget-pkgs repo",
	Args:    cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		moreInfo := moreInformation{}
		if updateCmd_moreInfo_json != "" {
			err := yaml.Unmarshal([]byte(updateCmd_moreInfo_json), &moreInfo)
			if err != nil {
				panic(fmt.Errorf("error unmarshalling more-info-json: %s", err))
			}
		}

		updated_manifests, commit_type := updateManifests(args[0], args[1], updateCmd_instUrls, moreInfo, cmd)

		if updateCmd_outDir != "" {
			path_to_write_manifests, err := filepath.Abs(updateCmd_outDir)
			if err != nil {
				panic(fmt.Errorf("failed to get absolute path of out-dir: %s", err))
			}
			if _, err := os.Stat(path_to_write_manifests); os.IsNotExist(err) {
				os.Mkdir(path_to_write_manifests, 0755)
			}
			for _, updated_manifest := range updated_manifests {
				cmd.Println("Manifest saved to:", filepath.Join(path_to_write_manifests, updated_manifest.FileName))
				os.WriteFile(filepath.Join(path_to_write_manifests, updated_manifest.FileName), []byte(updated_manifest.Content), 0644)
			}
		}

		if updateCmd_submit {
			cmd.Println("Submitting pull request to winget-pkgs repo...")
			github.SubmitManifests(args[0], args[1], updated_manifests, commit_type, updateCmd_forkUser, updateCmd_reuseDraftPr)
		}

	},
}

func init() {
	updateCmd.Flags().StringSliceVarP(&updateCmd_instUrls, "urls", "u", []string{}, "installer urls (required)")
	updateCmd.Flags().StringVar(&updateCmd_moreInfo_json, "more-info-json", "", "json containing manifest fields & values, will be overwritten no matter what")
	updateCmd.Flags().StringVarP(&updateCmd_outDir, "out-dir", "o", "", "output directory, to save the manifests to")
	updateCmd.Flags().BoolVarP(&updateCmd_submit, "submit", "s", false, "submit a pull request to winget-pkgs repo")
	updateCmd.Flags().BoolVar(&updateCmd_reuseDraftPr, "reuse-draft-pr", false, "reuse & update an existing draft pr, if any")
	updateCmd.Flags().StringVar(&updateCmd_forkUser, "fork-user", "", "owner of winget-pkgs fork (default: user of the token)")

	updateCmd.MarkFlagRequired("urls")
	// updateCmd.Flags().MarkHidden("more-info-json")
	updateCmd.Flags().MarkHidden("reuse-draft-pr")

	rootCmd.AddCommand(updateCmd)
}

const (
	CREATED_BY_COMMENT string = "# Created using WinGet Automation (CLI)"
	MANIFEST_VERSION   string = "1.5.0"
)

func updateManifests(pkg_id, version string, instUrls []string, moreInfo moreInformation, cmd *cobra.Command) ([]github.WinGetManifest, github.CommitType) {
	updated_manifests := []github.WinGetManifest{}
	previous_manifests := github.GetWinGetManifests(pkg_id, "latest")
	
	previous_manifest := yaml.MustParse(previous_manifests[0].Content + "\n---\n")
	previous_version := previous_manifest.Field("PackageVersion").Value.YNode().Value
	cmd.Println("Previous version:", previous_version)

	detectedGitHubData := github.MetadataFromGithub{}
	if regexp.MustCompile(`https:\/\/github.com\/.*\/.*\/releases\/download\/*\/.*`).MatchString(instUrls[0]) {
		detectedGitHubData = github.GetMetadataFromGitHub(instUrls[0])
	}

	for _, p_manifest := range previous_manifests {
		manifest := yaml.MustParse(p_manifest.Content + "\n---\n")
		switch manifest.Field("ManifestType").Value.YNode().Value {
		case "installer":
			_installers, _ := manifest.GetSlice("Installers")
			no_of_installers := len(_installers)

			cmd.Println("Downloading installer(s)...")
			installer_info := []map[string]string{}
			for _, instUrl := range instUrls {
				cmd.Print("Downloading: " + instUrl + " ") // append space for "done", looks pretty
				installer_info = append(installer_info, installer.DownloadAndGetInfo(instUrl))
				cmd.Println("(done)")
			}

			// copy from root level to installer level
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
					}
				}
				manifest.PipeE(yaml.Clear(field))
			}

			fields_to_update := []string{"InstallerUrl", "InstallerSha256", "ProductCode", "UpgradeCode", "PackageFamilyName", "SignatureSha256"}
			fields_to_match := []string{"InstallerType", "Architecture", "InstallerLocale", "Scope", "PackageFamilyName"}
			matching_map := make(map[int]int) // key: index of installer, value: index of installer_info
			for i := 0; i < no_of_installers; i++ {
				match_scores := []int{}
				for _, inst_info := range installer_info {
					match_score := 0
					for _, field_to_match := range fields_to_match {
						installer_field, _ := manifest.Pipe(yaml.Lookup("Installers"),
							yaml.Lookup(fmt.Sprintf("%d", i)),
							yaml.Get(field_to_match))
						if installer_field != nil && installer_field.YNode().Value == inst_info[field_to_match] {
							match_score++
						}
					}
					match_scores = append(match_scores, match_score)
				}
				max_match_score := 0
				for j, score := range match_scores {
					if score > max_match_score {
						max_match_score = score
						matching_map[i] = j
					}
				}
			}

			// according to the matching map, update the installer fields
			for key, value := range matching_map {
				for _, field_to_update := range fields_to_update {
					if _, ok := installer_info[value][field_to_update]; ok {
						manifest.PipeE(yaml.Lookup("Installers"),
							yaml.Lookup(fmt.Sprintf("%d", key)),
							yaml.SetField(field_to_update, yaml.NewStringRNode(installer_info[value][field_to_update])))
					}
				}
				// Patch release date from GitHub auto-detection or from more-information
				if detectedGitHubData.ReleaseDate != "" || moreInfo.ReleaseDate != "" {
					release_date := detectedGitHubData.ReleaseDate
					if moreInfo.ReleaseDate != "" { // overwrite if more-information is provided
						release_date = moreInfo.ReleaseDate // we give more priority to more-information
					}
					manifest.PipeE(yaml.Lookup("Installers"),
						yaml.Lookup(fmt.Sprintf("%d", key)),
						yaml.SetField("ReleaseDate", yaml.NewStringRNode(release_date)))
				}
				// More information - ProductCode
				if moreInfo.ProductCode != "" {
					manifest.PipeE(yaml.Lookup("Installers"),
						yaml.Lookup(fmt.Sprintf("%d", key)),
						yaml.SetField("ProductCode", yaml.NewStringRNode(moreInfo.ProductCode)))
				}
				// More information - AppsAndFeaturesEntries
				moreInfo_arpEntries_reflect := reflect.ValueOf(moreInfo.AppsAndFeaturesEntries)
				for i := 0; i < moreInfo_arpEntries_reflect.NumField(); i++ {
					if moreInfo_arpEntries_reflect.Field(i).String() != "" {
						manifest.PipeE(yaml.Lookup("Installers"),
						yaml.Lookup(fmt.Sprintf("%d", key)),
						yaml.LookupCreate(yaml.MappingNode, "AppsAndFeaturesEntries"),
						yaml.SetField(moreInfo_arpEntries_reflect.Type().Field(i).Name, yaml.NewStringRNode(moreInfo_arpEntries_reflect.Field(i).String())))
					}
				}
			}

			// move same values which are same across all installers from installer level to root level
			for _, field := range common_fields_root_and_installer {
				installer_level_value, _ := manifest.Pipe(yaml.Lookup("Installers"),
					yaml.Lookup(fmt.Sprintf("%d", 0)),
					yaml.Get(field))
				if installer_level_value == nil {
					continue
				}
				is_the_value_same_across_all_installers := true
				for i := 1; i < no_of_installers; i++ {
					installer_level_value_2, _ := manifest.Pipe(yaml.Lookup("Installers"),
						yaml.Lookup(fmt.Sprintf("%d", i)),
						yaml.Get(field))
					if installer_level_value_2 == nil || installer_level_value_2.YNode().Value != installer_level_value.YNode().Value {
						is_the_value_same_across_all_installers = false
						break
					}
				}
				if is_the_value_same_across_all_installers {
					for i := 0; i < no_of_installers; i++ {
						manifest.PipeE(yaml.Lookup("Installers"),
							yaml.Lookup(fmt.Sprintf("%d", i)),
							yaml.Clear(field))
					}
					manifest.PipeE(yaml.SetField(field, installer_level_value))
				}
			}
		case "defaultLocale", "locale":
			if version != manifest.Field("PackageVersion").Value.YNode().Value {
				manifest.PipeE(yaml.Clear("ReleaseNotes"))
				manifest.PipeE(yaml.Clear("ReleaseNotesUrl"))
			}
			if detectedGitHubData.ReleaseNotesUrl != "" { // it will always be populated, whereas other fields may be empty
				fields := []string{"PublisherUrl", "PublisherSupportUrl", "License", "LicenseUrl", "PackageUrl", "ReleaseNotesUrl", "PrivacyUrl", "ShortDescription"}
				detectedGitHubData_reflect := reflect.ValueOf(detectedGitHubData)
				for _, field := range fields {
					if manifest.Field(field) == nil && detectedGitHubData_reflect.FieldByName(field).String() != "" {
						manifest.PipeE(yaml.SetField(field, yaml.NewStringRNode(detectedGitHubData_reflect.FieldByName(field).String())))
					}
				}
				if manifest.Field("Tags") == nil {
					for _, tag := range detectedGitHubData.Tags {
						manifest.PipeE(yaml.LookupCreate(yaml.SequenceNode, "Tags"),
							yaml.Append(&yaml.Node{Kind: yaml.ScalarNode, Value: tag}))
					}
				}
			}
			for _, locale := range moreInfo.Locales {
				if strings.ToLower(locale.Name) == "all" || locale.Name == manifest.Field("PackageLocale").Value.YNode().Value {
					if locale.ReleaseNotes != "" {
						manifest.PipeE(yaml.SetField("ReleaseNotes", yaml.NewStringRNode(locale.ReleaseNotes)))
					}
					if locale.ReleaseNotesUrl != "" {
						manifest.PipeE(yaml.SetField("ReleaseNotesUrl", yaml.NewStringRNode(locale.ReleaseNotesUrl)))
					}
				}
			}
		}
		manifest.PipeE(yaml.SetField("PackageVersion", yaml.NewStringRNode(version)))
		manifest.PipeE(yaml.SetField("ManifestVersion", yaml.NewStringRNode(MANIFEST_VERSION)))
		manfiestYaml := manifest.MustString()
		manfiestYaml = strings.Replace(manfiestYaml, manfiestYaml[:strings.Index(manfiestYaml, "\n")+1], CREATED_BY_COMMENT+"\n", 1)
		updated_manifests = append(updated_manifests, github.WinGetManifest{FileName: p_manifest.FileName, Content: manfiestYaml})
	}

	var commit_type github.CommitType
	if previous_version == version {
		commit_type = github.UpdateVerCommit
	} else if previous_version < version {
		commit_type = github.NewVerCommit
	} else {
		commit_type = github.AddVerCommit
	}

	return updated_manifests, commit_type
}

// var cache_filesInsideZip = []string{}

// func _listFilesInsideZip(zipPath string) []string {
// 	if len(cache_filesInsideZip) > 0 {
// 		return cache_filesInsideZip
// 	}

// 	zipReader, err := zip.OpenReader(zipPath)
// 	if err != nil {
// 		panic(fmt.Errorf("error opening zip file: %v", err))
// 	}
// 	defer zipReader.Close()

// 	for _, file := range zipReader.File {
// 		cache_filesInsideZip = append(cache_filesInsideZip, file.Name)
// 	}
// 	return cache_filesInsideZip
// }

type moreInformation struct {
	ProductCode            string                                 `json:"ProductCode,omitempty"`
	ReleaseDate            string                                 `json:"ReleaseDate,omitempty"`
	AppsAndFeaturesEntries moreInformation_AppsAndFeaturesEntries `json:"AppsAndFeaturesEntries,omitempty"`
	Locales                []moreInformation_Locale               `json:"Locales,omitempty"`
}

type moreInformation_AppsAndFeaturesEntries struct {
	DisplayName    string `json:"DisplayName,omitempty"`
	Publisher      string `json:"Publisher,omitempty"`
	DisplayVersion string `json:"DisplayVersion,omitempty"`
	ProductCode    string `json:"ProductCode,omitempty"`
}

type moreInformation_Locale struct {
	Name            string `json:"Name"`
	ReleaseNotes    string `json:"ReleaseNotes,omitempty"`
	ReleaseNotesUrl string `json:"ReleaseNotesUrl,omitempty"`
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
	"InstallationMetadata"}
