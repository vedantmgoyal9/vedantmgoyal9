import { Page } from 'playwright';
import quizSolver from './quiz-solver';
import { RewardsInfo } from './types';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
) => {
  let rewardsInfo = await getRewardsInfo();
  let dateKey = Object.keys(rewardsInfo.dailySetPromotions)[0];
  console.log(`Doing daily set... [${dateKey}]`);
  while (
    rewardsInfo.dailySetPromotions[dateKey].some((task) => !task.complete)
  ) {
    for (const task of rewardsInfo.dailySetPromotions[dateKey]) {
      if (task.complete) continue;
      if (task.promotionType === 'quiz' && task.title !== 'Daily poll')
        await quizSolver(page, task.destinationUrl);
      else if (task.promotionType === 'quiz' && task.title === 'Daily poll') {
        await page.goto(task.destinationUrl);
        await page.click('.bt_poll .btOption');
        await page.waitForSelector('text=You earned 10 Microsoft Rewards points');
      }
      else if (task.promotionType === 'urlreward') {
        await page.goto(task.destinationUrl);
        await page.waitForLoadState('domcontentloaded');
      }
    }
    rewardsInfo = await getRewardsInfo();
  }
};
