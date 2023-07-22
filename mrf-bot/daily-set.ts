import { Page } from 'playwright';
import quizSolver from './quiz-solver';
import { RewardsInfo } from './types';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
) => {
  let rewardsInfo = await getRewardsInfo();
  let dateKey = Object.keys(rewardsInfo.dailySetPromotions).filter((key) => 
    // get current date in form of 06/23/2023 (mm/dd/yyyy) and compare it with the date key
    key === new Date().toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' })
  )[0];

  console.log(`Doing daily set... [${dateKey}]`);
  while (
    rewardsInfo.dailySetPromotions[dateKey].some((task) => !task.complete)
  ) {
    for (const task of rewardsInfo.dailySetPromotions[dateKey]) {
      if (task.complete) continue;

      console.log(`\x20- ${task.title}`); // second-level log
      if (task.promotionType === 'quiz' && task.title !== 'Daily poll')
        await quizSolver(page, task.destinationUrl);
      else if (task.promotionType === 'quiz' && task.title === 'Daily poll') {
        await page.goto(task.destinationUrl);
        await page.click('.bt_poll .btOption');
        await page.waitForSelector('text=You earned 10 Microsoft Rewards points');
      }
      else if (task.promotionType === 'urlreward') {
        await page.goto('https://rewards.bing.com/');
        await page.click(`text=${task.title}`);
        await page.waitForTimeout(7000); // wait for 7 seconds, just randomly 😂😶‍🌫️
      }
    }

    rewardsInfo = await getRewardsInfo();
  }
};
