import { Page } from 'playwright';
import quizSolver from './quiz-solver';
import { PromotionInfo, RewardsInfo } from './types';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
) => {
  let rewardsInfo = await getRewardsInfo();
  console.log('Doing more activities...');

  const filterCondition = (task: PromotionInfo) =>
    ['quiz', 'urlreward'].includes(task.promotionType) &&
    !task.complete &&
    !task.description.includes('Bing app') &&
    !task.title.includes('Scan receipts') &&
    !/rewards.(bing|microsoft).com\/redeem/g.test(task.destinationUrl)

  while (rewardsInfo.morePromotions.some((task) => filterCondition(task))) {
    for (const task of rewardsInfo.morePromotions.filter((task) =>
      filterCondition(task),
    )) {
      // if (task.complete) continue;
      console.log(`\x20- ${task.title}`); // second-level log
      if (task.promotionType === 'quiz')
        await quizSolver(page, task.destinationUrl);
      else if (task.promotionType === 'urlreward') {
        await page.goto('https://rewards.bing.com/');
        await page.click(`text=${task.title}`);
        await page.waitForTimeout(7000); // wait for 7 seconds, just randomly 😂😶‍🌫️
      }
    }

    rewardsInfo = await getRewardsInfo();
  }
};
