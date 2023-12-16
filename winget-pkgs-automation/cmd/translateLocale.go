/*
Copyright © 2023 Vedant
*/
package cmd

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/vedantmgoyal2009/vedantmgoyal2009/winget-pkgs-automation/internal/github"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

// translateLocaleCmd represents the translateLocale command
var translateLocaleCmd = &cobra.Command{
	Use:     "translate-locale",
		Aliases: []string{"trans", "translate", "tl"},
		Short:   "Translate a locale for a package into your language",
		Run: func(cmd *cobra.Command, args []string) {
			pkg_id := args[0]
			version := args[1]
			toLocale := args[2]
			forkUser := args[3]

			var en_us_manifest_raw string
			manifests := github.GetWinGetManifests(pkg_id, version)
			for _, manifest := range manifests {
				if manifest.FileName == pkg_id+".locale.en-US.yaml" {
					en_us_manifest_raw = manifest.Content
					break
				}
			}

			manifest := yaml.MustParse(en_us_manifest_raw)
			manifest.Pipe(yaml.SetField("PackageLocale", yaml.NewStringRNode(toLocale)))

			translate := func(value string) string {
				res, err := http.Get("https://winget.vercel.app/api/translate?text=" + url.QueryEscape(value) + "&from=en-US&to=" + toLocale)
				if err != nil {
					panic(fmt.Errorf("error getting translation for %s: %s", value, err))
				}
				defer res.Body.Close()
				body, err := io.ReadAll(res.Body)
				if err != nil {
					panic(fmt.Errorf("error reading response body: %s", err))
				}
				return string(body)
			}
			fieldsToTranslate := []string{"Tags", "Author", "License", "Copyright", "ShortDescription", "Description", "ReleaseNotes"}
			for _, field := range fieldsToTranslate {
				if field == "Tags" {
					continue
				}
				if value := manifest.Field(field).Value.YNode().Value; value != "" {
					// manifest.Pipe(yaml.Lookup(field, strconv.Itoa(i)), yaml.Set(yaml.NewStringRNode(translate(tag.(string)))))
					manifest.Pipe(yaml.SetField(field, yaml.NewStringRNode(translate(value))))
				}
			}

			fmt.Println(manifest.MustString())
			localeManifest := []github.WinGetManifest{{FileName: pkg_id + ".locale." + toLocale + ".yaml", Content: manifest.MustString()}}
			// prompt for confirmation
			response, err := bufio.NewReader(os.Stdin).ReadString('\n')
			if err != nil {
				log.Fatal(err)
			}
			response = strings.ToLower(strings.TrimSpace(response))
			if response != "y" && response != "yes" {
				log.Fatal("Aborted")
				os.Exit(1)
			}
			github.SubmitManifests(pkg_id, version, localeManifest, github.NewLocaleCommit, forkUser)
		},
}

func init() {
	rootCmd.AddCommand(translateLocaleCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// translateLocaleCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// translateLocaleCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
