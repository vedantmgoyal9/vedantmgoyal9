import { Page } from 'playwright';
import { RewardsInfo } from './types';
import quizAndPolls from './quiz-solver';

export default async (
  page: Page,
  getRewardsInfo: () => Promise<RewardsInfo>,
) => {
  let rewardsInfo = await getRewardsInfo();
  console.log('Doing quests and punch cards...');
  for (const card of rewardsInfo.punchCards) {
    if (
      !card.parentPromotion.promotionType
        .split(',')
        .every((type) => ['urlreward', 'quiz'].includes(type)) ||
      card.parentPromotion.complete
    )
      continue;

    for (let index = 0; index < card.childPromotions.length; index++) {
      const task = card.childPromotions[index];

      if (task.complete) continue;

      if (task.promotionType === 'quiz')
        await quizAndPolls(page, task.destinationUrl);
      else if (task.promotionType === 'urlreward') {
        await page.goto(task.destinationUrl);
        await page.waitForLoadState('domcontentloaded');
      }

      if (
        card.childPromotions[index + 1].description.match(
          /[Ww]ait 24 hours or more after completing [Dd]ay [0-9]/g,
        )
      )
        break;
    }
    rewardsInfo = await getRewardsInfo();
  }
};
