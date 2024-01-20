import { createNodeMiddleware, createProbot, Context, Probot } from 'probot';

/**
 * This is the main entrypoint to your Probot app
 */
function probotApp(app: Probot) {
  // Your code here
  app.log.info('Yay, the app was loaded!');

  app.on(
    'pull_request.closed',
    async (context: Context<'pull_request.closed'>) => {
      if (
        'dependabot[bot]' === context.payload.pull_request.user.login &&
        (await context.octokit.issues.listComments(context.issue())).data.find(
          (comment) =>
            [
              /Superseded by #([0-9]+)/g,
              /Looks like [-@/.a-zA-Z]+ is up-to-date now, so this is no longer needed\./g,
              /Looks like [-@/.a-zA-Z]+ is updatable in another way, so this is no longer needed\./g,
              /Looks like these dependencies are updatable in another way, so this is no longer needed\./g,
              /Looks like [-@/.a-zA-Z]+ is no longer a dependency, so this is no longer needed\./g,
            ].some((regex) => regex.test(comment.body || '')),
        )
      ) {
        await context.octokit.pulls.removeRequestedReviewers(
          context.pullRequest({ reviewers: ['vedantmgoyal2009'] }),
        );
        return await context.octokit.issues.lock(
          context.issue({ lock_reason: 'resolved' }),
        );
      }

      if (context.payload.pull_request.merged === true) {
        // lock conversation on the PR
        return await context.octokit.issues.lock(
          context.issue({ lock_reason: 'resolved' }),
        );
      }
    },
  );

  app.on(
    'pull_request.opened',
    async (context: Context<'pull_request.opened'>) => {
      if (context.payload.pull_request.user.login === 'dependabot[bot]') {
        return await fetch(
          `https://api.github.com/repos/${context.payload.repository.full_name}/pulls/${context.payload.number}/reviews`,
          {
            method: 'POST',
            headers: {
              authorization: `token ${process.env.GITHUB_PAT}`,
              accept: 'application/vnd.github.v3+json',
              'User-Agent': `probot/${app.version}`, // the same is used by context.octokit
            },
            body: JSON.stringify({
              event: 'APPROVE',
              body:
                '@dependabot squash and merge\n' +
                '###### 🍏 Approved 🥗 automagically 🔮 by 🤖 @vedantmgoyal2009-bot 😉ヾ(≧▽≦*)o 🥳',
            }),
          },
        );
      }

      if (context.payload.pull_request.user.login === 'allcontributors[bot]') {
        await context.octokit.issues.addLabels(
          context.issue({ labels: ['documentation'] }),
        );
        await context.octokit.pulls.removeRequestedReviewers(
          context.pullRequest({ reviewers: ['vedantmgoyal2009'] }),
        );
        return await context.octokit.pulls.merge(
          context.pullRequest({ merge_method: 'squash' }),
        );
      }
    },
  );
}

export default createNodeMiddleware(probotApp, {
  probot: createProbot(),
  webhooksPath: '/api/github-bot',
});
