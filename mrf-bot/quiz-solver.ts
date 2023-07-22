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
  await page.waitForTimeout(7000); // wait for 7 seconds, just randomly 😂😶‍🌫️
  let questionNumber = 1;

  // start playing button
  await (await page.$('text=Start playing'))?.click();

  // this/that quiz (10 questions - 1 answer each - 2 ans. choices - 50 points)
  while (await page.$(selectors.thisOrThatQuiz)) {
    console.log(`\x20\x20\x20- Question ${questionNumber++}`); // third-level log
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
      )!.click();
    try {
      await page.waitForSelector(selectors.thisOrThatQuiz);
    } catch (err) {
      break; // quiz is over, no more questions
    }
  }

  // for supersonic quizzes (3 questions - 5 answers each - 30 points)
  let answerChoice = 1;
  while (await page.$(selectors.supersonicQuiz)) {
    if (answerChoice === 6) {
      answerChoice = 1;
      questionNumber++;
    }
    console.log(`\x20\x20\x20- Question ${questionNumber}/3 [${answerChoice++}/5]`); // third-level log
    await page.click(selectors.supersonicQuiz);
    try {
      await page.waitForSelector(selectors.supersonicQuiz);
    } catch (err) {
      break; // quiz is over, no more questions
    }
  }

  // for turbocharge quizzes (3 questions - 1 answer each - 30 points)
  while (await page.$(selectors.turbochargeQuiz)) {
    console.log(`\x20\x20\x20- Question ${questionNumber++}`); // third-level log
    const correctAnswer = await page.evaluate(
      // @ts-ignore - it is defined, ts is dumb, lol 😂
      () => window.rewardsQuizRenderInfo.correctAnswer,
    );
    await page.click(
      `${selectors.turbochargeQuiz}[data-option="${correctAnswer}"]`,
    );
    try {
      await page.waitForSelector(selectors.turbochargeQuiz);
    } catch (err) {
      break; // quiz is over, no more questions
    }
  }

  // test your smarts, entertainment, and news quizzes (3/5/7 questions - 1 ans. - 10 points)
  while (await page.$(selectors.bingQuizOption)) {
    console.log(`\x20\x20\x20- Question ${questionNumber++}`); // third-level log
    await page.click(selectors.bingQuizOption);
    await (await page.waitForSelector(selectors.bingQuizNextQuesBtn)).click();
    try {
      await page.waitForSelector(selectors.bingQuizOption);
    } catch (err) {
      break; // quiz is over, no more questions
    }
  }
};
