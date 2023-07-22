import { Page } from 'playwright';
import { RewardsInfo } from './types';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
  searchQueries: string[],
) => {
  let rewardsInfo = await getRewardsInfo();
  console.log('Completing desktop + edge searches...');

  // sign in if not already signed in
  await page.goto(`https://www.bing.com/search?q=${searchQueries.splice(0, 1)[0]}`);
  await (await page.$('input#id_s'))?.click()
  await page.waitForTimeout(3000); // wait for 3 seconds, just randomly 😶‍🌫️😁

  let count = 0;
  while (
    !rewardsInfo.userStatus.counters.pcSearch[0].complete ||
    !rewardsInfo.userStatus.counters.pcSearch[1].complete
  ) {
    await page.goto(
      `https://www.bing.com/search?q=${searchQueries.splice(0, 1)[0]}`,
    );
    await page.waitForTimeout(Math.floor(Math.random() * 6000) + 4000); // wait random time between 4 and 10 seconds
    if ((count += 1) % 5 === 0)
      // refresh rewards info every 5 searches
      rewardsInfo = await getRewardsInfo();
  }
};
