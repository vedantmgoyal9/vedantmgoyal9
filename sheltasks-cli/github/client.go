package github

import (
	"context"
	"os"

	"github.com/google/go-github/v58/github"
)

var github_client *github.Client
var github_client_user string

func init() {
	if val, ok := os.LookupEnv("GITHUB_TOKEN"); !ok || val == "" {
		panic("GITHUB_TOKEN environment variable is not set.")
	} else {
		github_client = github.NewClient(nil).WithAuthToken(val)
		if user, _, err := github_client.Users.Get(context.Background(), ""); err != nil {
			panic("GitHub token is expired or invalid.")
		} else {
			github_client_user = user.GetLogin()
		}
	}
}
