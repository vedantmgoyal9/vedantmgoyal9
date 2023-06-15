import { Page } from 'playwright';

export default async (page: Page, quizUrl: string) => {
  const selectors = {
    supersonicQuiz:
      '#currentQuestionContainer .b_cards[iscorrectoption=True]:not(.btsel)',
    thisOrThatQuiz: '#currentQuestionContainer .btOptionCard',
    turbochargeQuiz: '#currentQuestionContainer .rqOption:not(.optionDisable)',
    bingQuizOption:
      '#ListOfQuestionAndAnswerPanes div[id^=QuestionPane]:not(.wk_hideCompulsary) .wk_choicesInstLink',
    bingQuizNextQuesBtn:
      '#ListOfQuestionAndAnswerPanes div[id^=AnswerPane]:not(.b_hide) input[type=submit]',
  };

  await page.goto(quizUrl);
  await (
    await page.$('body > div.simpleSignIn > div.signInOptions > span > a')
  )?.click();
  await page.waitForLoadState('domcontentloaded')

  // start playing button
  await page.click('#rqStartQuiz', { timeout: 5000 });

  // this/that quiz (10 questions - 1 answer each - 2 ans. choices - 50 points)
  while (await page.$(selectors.thisOrThatQuiz)) {
    const answerChoices = await page.$$(selectors.thisOrThatQuiz);
    const correctAnsHash = await page.evaluate(
      // @ts-ignore - it is defined, ts is dumb, lol 😂
      () => window.rewardsQuizRenderInfo.correctAnswer,
    );
    const _G_IG = await page.evaluate(
      () =>
        // @ts-ignore - it is defined, ts is dumb, lol 😂
        window._G.IG,
    );
    answerChoices
      .find(
        async (choice) =>
          (await choice.getAttribute('data-option'))!
            .split('')
            .reduce(
              (acc, curr) => acc + curr.charCodeAt(0),
              parseInt(_G_IG.substr(_G_IG.length - 2), 16),
            )
            .toString() === correctAnsHash,
      )
      ?.click();
    await page.waitForSelector(selectors.thisOrThatQuiz);
  }

  // for supersonic quizzes (3 questions - 5 answers each - 30 points)
  while (await page.$(selectors.supersonicQuiz)) {
    await page.click(selectors.supersonicQuiz);
    await page.waitForSelector(selectors.supersonicQuiz);
  }

  // for turbocharge quizzes (3 questions - 1 answer each - 30 points)
  while (await page.$(selectors.turbochargeQuiz)) {
    const correctAnswer = await page.evaluate(
      // @ts-ignore - it is defined, ts is dumb, lol 😂
      () => window.rewardsQuizRenderInfo.correctAnswer,
    );
    await page.click(
      `${selectors.turbochargeQuiz} [data-option="${correctAnswer}"]`,
    );
    await page.waitForSelector(selectors.turbochargeQuiz);
  }

  // test your smarts, entertainment, and news quizzes (3/5/7 questions - 1 ans. - 10 points)
  while (await page.$(selectors.bingQuizOption)) {
    await page.click(selectors.bingQuizOption);
    await page.waitForSelector(selectors.bingQuizNextQuesBtn);
    await page.click(selectors.bingQuizNextQuesBtn);
    await page.waitForSelector(selectors.bingQuizOption);
  }
};
