import { chromium, devices } from 'playwright';
import dailySet from './daily-set';
import desktopEdgeSearches from './desktop-edge-searches';
import mobileSearches from './mobile-searches';
import moreActivities from './more-activities';
import punchCards from './punch-cards';
import { Config, GoogleTrendsApiResult, RewardsInfo } from './types';
import { platform } from 'os';
import { join } from 'node:path';
import { login, saveSession, tryRestoringSession } from './session-manager';

(async () => {
  const accounts: Config = require(join(__dirname, 'config.json'));
  const browser = await chromium.launch({
    channel: 'msedge',
    headless: false,
    chromiumSandbox: platform() === 'linux',
  });

  for (const account of Object.entries(accounts)) {
    const page = await browser.newPage({ ...devices['Desktop Edge'] });
    const lastUsedDate = new Date().getDate();

    if (!(await tryRestoringSession(page, account[0]))) {
      await login(page, account[0], account[1]); // page, email, password
      await saveSession(page, account[0]); // page, email
    }

    const getRewardsInfo = async (): Promise<RewardsInfo> => {
      await page.goto('https://rewards.bing.com/api/getuserinfo');
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
      await getSearchQueries(lastUsedDate),
    );

    // desktop searches + edge bonus
    await desktopEdgeSearches(
      page,
      getRewardsInfo,
      await getSearchQueries(lastUsedDate),
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

async function getSearchQueries(lastUsedDate: number): Promise<string[]> {
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
