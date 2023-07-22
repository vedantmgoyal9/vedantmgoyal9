import { Page } from 'playwright';
import { RewardsInfo } from './types';
import quizSolver from './quiz-solver';

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

      console.log(`\x20- ${task.title} [${card.parentPromotion.title}]`); // second-level log
      if (task.promotionType === 'quiz')
        await quizSolver(page, task.destinationUrl);
      else if (task.promotionType === 'urlreward') {
        await page.goto('https://rewards.bing.com/');
        await page.click(`text=${task.title}`);
        await page.waitForTimeout(7000); // wait for 7 seconds, just randomly 😂😶‍🌫️
      }

      if (
        card.childPromotions[index + 1].description.match(
          /[Ww]ait 24 hours or more after completing [Dd]ay [0-9]/g,
        )
      ) {
        console.log('\x20\x20-We have to wait for 24 hours... 😴'); // third-level log
        break;
      }
    }

    rewardsInfo = await getRewardsInfo();
  }
};
