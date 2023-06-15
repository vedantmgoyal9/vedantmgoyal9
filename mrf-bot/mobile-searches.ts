import { Browser, devices, Page } from 'playwright';
import { RewardsInfo } from './types';

export default async (
  page: Page,
  browser: Browser,
  getRewardsInfo: () => Promise<RewardsInfo>,
  searchQueries: string[],
) => {
  let rewardsInfo = await getRewardsInfo();
  if (rewardsInfo.userStatus.counters.mobileSearch[0].complete) return;
  console.log('Completing mobile searches...');
  const mobilePage = await browser.newPage({ ...devices['iPhone 13 Pro Max'] });
  await mobilePage.context().addCookies(await page.context().cookies());
  let count = 0;
  while (!rewardsInfo.userStatus.counters.mobileSearch[0].complete) {
    await mobilePage.goto(
      `https://www.bing.com/search?q=${searchQueries.splice(0, 1)[0]}`,
    );
    await mobilePage.waitForTimeout(Math.floor(Math.random() * 6000) + 4000); // wait random time between 4 and 10 seconds
    if ((count += 1) % 5 === 0)
      // refresh rewards info every 5 searches
      rewardsInfo = await getRewardsInfo();
  }

  await mobilePage.close();
};
