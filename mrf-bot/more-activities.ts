import { Page } from 'playwright';
import quizSolver from './quiz-solver';
import { PromotionInfo, RewardsInfo } from './types';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
) => {
  let rewardsInfo = await getRewardsInfo();
  const filterCondition = (task: PromotionInfo) =>
    ['quiz', 'urlreward'].includes(task.promotionType) &&
    !task.complete &&
    !task.description.includes('Bing app') &&
    !task.title.includes('Scan receipts') &&
    !task.destinationUrl.startsWith('https://rewards.microsoft.com/redeem');

  console.log('Doing more activities...');
  while (rewardsInfo.morePromotions.some((task) => filterCondition(task))) {
    for (const task of rewardsInfo.morePromotions.filter((task) =>
      filterCondition(task),
    )) {
      // if (task.complete) continue;
      if (task.promotionType === 'quiz')
        await quizSolver(page, task.destinationUrl);
      else if (task.promotionType === 'urlreward') {
        await page.goto(task.destinationUrl);
        await page.waitForLoadState('domcontentloaded');
      }
    }
    rewardsInfo = await getRewardsInfo();
  }
};
