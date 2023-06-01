import { createNodeMiddleware, createProbot, Context, Probot } from 'probot';

/**
 * This is the main entrypoint to your Probot app
 */
function probotApp(app: Probot) {
  // Your code here
  app.log.info('Yay, the app was loaded!');

  app.on(
    'pull_request.opened',
    async (context: Context<'pull_request.opened'>) => {
      if (
        context.payload.pull_request.user.login === 'dependabot[bot]' &&
        context.payload.repository.name === 'winget-releaser'
      ) {
        await context.octokit.pulls.removeRequestedReviewers(
          context.pullRequest(),
        );
        return await context.octokit.pulls.merge(
          context.pullRequest({
            merge_method: 'squash',
          }),
        );
    }
  );

  app.on(
    'pull_request.closed',
    async (context: Context<'pull_request.closed'>) => {
      // check if the PR was merged or closed without merging
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
