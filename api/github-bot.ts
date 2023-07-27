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
              /Looks like [@/-a-zA-Z]+ is up-to-date now, so this is no longer needed\./g,
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
}

export default createNodeMiddleware(probotApp, {
  probot: createProbot(),
  webhooksPath: '/api/github-bot',
});
