package github

type CommitType string

const (
	NewVerCommit    CommitType = "New version"
	UpdateVerCommit CommitType = "Update version"
	AddVerCommit    CommitType = "Add version"
	RmVerCommit     CommitType = "Remove"
	NewLocaleCommit CommitType = "New locale"
)

type WinGetManifest struct {
	FileName string
	Content  string
}

type DetectedDataFromGithub struct {
	PublisherUrl        string
	PublisherSupportUrl string
	License             string
	LicenseUrl          string
	PackageUrl          string
	ReleaseDate         string
	ReleaseNotesUrl     string
	ReleaseNotes        string
	PrivacyUrl          string
	Tags                []string
	ShortDescription    string
}
