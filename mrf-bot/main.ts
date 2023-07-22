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

(async () => {
  const accounts: Config = process.env.CI ? JSON.parse(process.env.MRF_ACCOUNTS!) : require(join(__dirname, './accounts.json'));
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
    await desktopEdgeSearches(
      page,
      getRewardsInfo,
      await getSearchQueries(),
    );

    // daily set
    await dailySet(page, getRewardsInfo);

    // quests and punch cards
    await punchCards(page, getRewardsInfo);

    // more activities
    await moreActivities(page, getRewardsInfo);

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
