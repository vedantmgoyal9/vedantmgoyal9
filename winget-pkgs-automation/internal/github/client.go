package github

import (
	"context"
	"os"

	"github.com/google/go-github/v54/github"
	"golang.org/x/oauth2"
)

var github_client *github.Client
var github_client_user string

func init() {
	ctx := context.Background()

	if val, ok := os.LookupEnv("GITHUB_TOKEN"); !ok || len(val) != 40 {
		panic("GITHUB_TOKEN environment variable is not set.")
	} else {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: val},
		)
		tc := oauth2.NewClient(ctx, ts)
		github_client = github.NewClient(tc)
		if user, _, err := github_client.Users.Get(context.Background(), ""); err != nil {
			panic("Invalid Github token")
		} else {
			github_client_user = user.GetLogin()
		}
	}
}
