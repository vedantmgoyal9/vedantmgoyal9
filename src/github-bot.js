const { execSync } = require('child_process');
const { writeFileSync } = require('fs');
/**
 * This is the main entrypoint to your Probot app
 * @param {import('probot').Probot} app
 */
module.exports = (app) => {
  // Your code here
  app.log.info('Yay, the app was loaded!');

  app.on('push', async (context) => {
    // Update wpa-packages.md (currently maintained packages)
    if (
      [
        ...context.payload.head_commit.added,
        ...context.payload.head_commit.modified,
        ...context.payload.head_commit.removed,
      ].some((file) => /^src\/winget-pkgs-automation\/.*/g.test(file))
    ) {
      app.log.info('-----------');
      app.log.info('Updating wpa-packages.md');
      writeFileSync(
        `${__dirname}/../docs/docs/wpa-packages.md`,
        [
          '---',
          'id: wpa-packages',
          'title: Currently maintained packages',
          'sidebar_label: 📦 Packages',
          '---',
        ].join('\n')
      );
      execSync(
        `"\`n" | Out-File -Append -Encoding UTF8 -FilePath ${__dirname}/../docs/docs/wpa-packages.md;
         Get-ChildItem . -Recurse -File | Get-Content -Raw | Where-Object {
          (Test-Json -Json $_ -SchemaFile ../schema.json -ErrorAction Ignore) -eq $true
         } | ConvertFrom-Json | Where-Object {
          $_.SkipPackage -eq $false
         } | Select-Object -ExpandProperty Identifier | Sort-Object | ForEach-Object {
          "- [$_](https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/src/winget-pkgs-automation/packages/$($_.Substring(0,1).ToLower())/$($_.ToLower()).json)"
         } | Out-File -Append -Encoding UTF8 -FilePath ${__dirname}/../docs/docs/wpa-packages.md`,
        { shell: 'pwsh', cwd: `${__dirname}/winget-pkgs-automation/packages` }
      );
      execSync(
        `git commit -m \"docs(wpa): update wpa-packages.md\" -- wpa-packages.md`,
        {
          cwd: `${__dirname}/../docs/docs`,
        }
      );
      execSync(
        `git push https://x-access-token:${await context.github.auth({
          type: 'installation',
        }).token}@github.com/vedantmgoyal2009/vedantmgoyal2009.git`,
        {
          cwd: `${__dirname}/../docs`,
        }
      );
    }
  });

  app.on('issue_comment.created', async (context) => {
    // command: /approve-and-merge
    if (context.payload.comment.body.includes('/approve-and-merge')) {
      app.log.info('-----------');
      app.log.info('command: /approve-and-merge');
      app.log.info('issue/pull_request: ' + context.payload.issue.number);
      context.octokit.pulls.removeRequestedReviewers({
        owner: context.payload.repository.owner.login,
        repo: context.payload.repository.name,
        pull_number: context.payload.issue.number,
        reviewers: ['vedantmgoyal2009'],
      });
      context.octokit.pulls.createReview({
        owner: context.payload.repository.owner.login,
        repo: context.payload.repository.name,
        pull_number: context.payload.issue.number,
        event: 'APPROVE',
      });
      context.octokit.pulls.merge({
        owner: context.payload.repository.owner.login,
        repo: context.payload.repository.name,
        pull_number: context.payload.issue.number,
        merge_method: 'squash',
      });
    }

    // command: /label-and-merge
    // if (context.payload.comment.body.includes('/label-and-merge')) {
    //   app.log.info('-----------');
    //   app.log.info('command: /label-and-merge');
    //   app.log.info('issue/pull_request: ' + context.payload.issue.number);
    //   let labels = context.payload.comment.body
    //     .replace(/\/label-and-merge\s/g, '')
    //     .split(' ');
    //   app.log.info('labels: ' + labels);
    //   context.octokit.issues.addLabels({
    //     owner: context.payload.repository.owner.login,
    //     repo: context.payload.repository.name,
    //     issue_number: context.payload.issue.number,
    //     labels: labels,
    //   });
    //   context.octokit.pulls.removeRequestedReviewers({
    //     owner: context.payload.repository.owner.login,
    //     repo: context.payload.repository.name,
    //     pull_number: context.payload.issue.number,
    //     reviewers: ['vedantmgoyal2009'],
    //   });
    //   context.octokit.pulls.createReview({
    //     owner: context.payload.repository.owner.login,
    //     repo: context.payload.repository.name,
    //     pull_number: context.payload.issue.number,
    //     event: 'APPROVE',
    //   });
    //   context.octokit.pulls.merge({
    //     owner: context.payload.repository.owner.login,
    //     repo: context.payload.repository.name,
    //     pull_number: context.payload.issue.number,
    //     merge_method: 'squash',
    //   });
    // }
  });
};
