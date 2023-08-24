import { createNodeMiddleware, createProbot, Context, Probot } from 'probot';
import { request } from 'https';

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
              /Looks like [-@/a-zA-Z]+ is up-to-date now, so this is no longer needed\./g,
            ].some((regex) => regex.test(comment.body || '')),
        )
      ) {
        const requestedReviewers =
          await context.octokit.pulls.listRequestedReviewers(
            context.pullRequest(),
          );
        if (requestedReviewers.data.users.length > 0)
          await context.octokit.pulls.removeRequestedReviewers(
            context.pullRequest({
              reviewers: requestedReviewers.data.users.map(
                (user) => user.login,
              ),
            }),
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
      if (
        context.payload.pull_request.user.login === 'dependabot[bot]' &&
        context.payload.repository.name === 'winget-releaser'
      ) {
        const requestedReviewers =
          await context.octokit.pulls.listRequestedReviewers(
            context.pullRequest(),
          );
        if (requestedReviewers.data.users.length > 0)
          await context.octokit.pulls.removeRequestedReviewers(
            context.pullRequest({
              reviewers: requestedReviewers.data.users.map(
                (user) => user.login,
              ),
            }),
          );
        const req = request({
          hostname: 'api.github.com',
          path: `/repos/${context.payload.repository.full_name}/pulls/${context.payload.number}/reviews`,
          method: 'POST',
          headers: {
            authorization: `token ${process.env.GITHUB_PAT}`,
            accept: 'application/vnd.github.v3+json',
            'User-Agent': `probot/${app.version}`, // the same is used by context.octokit
          },
        });
        req.write(
          JSON.stringify({
            event: 'APPROVE',
            body:
              '@dependabot squash and merge\n' +
              '###### 🍏 Approved 🥗 automagically 🔮 by 🤖 @vedantmgoyal2009-bot 🥳😉ヾ(≧▽≦*)o',
          }),
        );
        req.end();
      }
    },
  );
}

export default createNodeMiddleware(probotApp, {
  probot: createProbot(),
  webhooksPath: '/api/github-bot',
});
