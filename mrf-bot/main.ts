import { chromium, devices } from 'playwright';
import dailySet from './daily-set';
import desktopEdgeSearches from './desktop-edge-searches';
import mobileSearches from './mobile-searches';
import moreActivities from './more-activities';
import punchCards from './punch-cards';
import { Config, GoogleTrendsApiResult, RewardsInfo } from './types';
import { platform } from 'os';
import { join } from 'node:path';
import { loginAndSaveSession, tryRestoringSession } from './session-manager';
import nodemailer from 'nodemailer';

(async () => {
  const accounts: Config = process.env.CI
    ? JSON.parse(process.env.MRF_ACCOUNTS!)
    : require(join(__dirname, './accounts.json'));
  const browser = await chromium.launch({
    channel: 'msedge',
    headless: false,
    args: platform() === 'linux' ? ['--no-sandbox'] : [],
  });

  for (const account of Object.entries(accounts)) {
    const page = await browser.newPage({ ...devices['Desktop Edge'] });

    if (!(await tryRestoringSession(page, account[0])))
      await loginAndSaveSession(page, account[0], account[1]); // page, email, password

    const getRewardsInfo = async (): Promise<RewardsInfo> => {
      await page.goto('https://rewards.bing.com/api/getuserinfo?type=1');
      await page.waitForSelector('body');
      return await page.evaluate(
        () => JSON.parse(document.body.innerText)['dashboard'],
      );
    };

    // mobile searches
    await mobileSearches(
      page,
      browser,
      getRewardsInfo,
      await getSearchQueries(),
    );

    // desktop searches + edge bonus
    await desktopEdgeSearches(page, getRewardsInfo, await getSearchQueries());

    // daily set
    await dailySet(page, getRewardsInfo);

    // more activities
    await moreActivities(page, getRewardsInfo);

    // quests and punch cards
    await punchCards(page, getRewardsInfo);

    // send email, when running on CI :)
    if (process.env.CI && process.env.MRF_EMAIL && process.env.MRF_EMAIL_PASS) {
      await page.goto('https://rewards.bing.com/dashboard');
      // workaround for page.screenshot({ fullPage: true }) not working
      await page.evaluate(() => {
        const body = document.querySelector('body');
        const style = document.createElement('style');
        style.innerHTML = `body { height: auto !important; width: auto !important; }, .hide { display: none !important; }`;
        body?.appendChild(style);
        return document.querySelector('body')?.innerHTML;
      });
      nodemailer
        .createTransport({
          host: 'smtp.gmail.com',
          port: 465,
          secure: true,
          auth: {
            user: process.env.MRF_EMAIL,
            pass: process.env.MRF_EMAIL_PASS,
          },
        })
        .sendMail({
          from: process.env.MRF_EMAIL,
          to: process.env.MRF_EMAIL,
          subject: '🎉 mrf-bot completed successfully!',
          html: `Hello,<br><br>
          🎉 Congratulations! 🎉<br><br>
          mrf-bot completed successfully for ${account[0]}!<br><br>
          Logs: ${
            process.env.CI
              ? `https://github.com/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}`
              : 'No logs available.'
          }<br><br>
          Regards,<br>
          mrf-bot`.replace(/\s{10}/g, ''),
          attachments: [
            {
              filename: 'screenshot.jpeg',
              content: await page.locator('body').screenshot({ type: 'jpeg' }),
            },
          ],
        });
    }

    console.log(`${account[0]} - completed successfully!`);
    await page.close();
  }

  console.log('Done!');
  await browser.close();
})();

let lastUsedDate = new Date().getDate() - Math.ceil(Math.random() * 10);
async function getSearchQueries(): Promise<string[]> {
  let searchQueries: string[] = [];

  while (searchQueries.length < 35) {
    const apiResponse = await (
      await fetch(
        `https://trends.google.com/trends/api/dailytrends?ed=${new Date(
          new Date().setDate(lastUsedDate--),
        )
          .toISOString()
          .slice(0, 10)
          .replace(/-/g, '')}&geo=US`,
      )
    ).text();

    const apiResult: GoogleTrendsApiResult = JSON.parse(
      apiResponse.slice(apiResponse.indexOf('{')),
    );

    apiResult.default.trendingSearchesDays[0].trendingSearches.map(
      (trendingSearch) =>
        searchQueries.push(
          trendingSearch.title.query,
          ...trendingSearch.relatedQueries.map(
            (relatedQuery) => relatedQuery.query,
          ),
        ),
    );
  }

  return searchQueries;
}
