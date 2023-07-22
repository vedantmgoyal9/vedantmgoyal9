import { Page } from 'playwright';
import { join } from 'node:path';
import { existsSync, writeFileSync } from 'node:fs';

export async function loginAndSaveSession(
  page: Page,
  email: string,
  _password: string,
) {
  console.log(`Logging in as ${email}...`);
  await page.goto('https://rewards.bing.com/');
  await page.click('text=Sign in');
  await page.fill('input[type="email"]', email);
  await page.click('input[type="submit"]');
  await page.click('text=Other ways to sign in');
  await page.click('text=Windows Hello or a security key');
  await page.waitForSelector('text=Stay signed in?');
  await page.click('input[type="submit"]');
  console.log(`Successfully logged in as ${email}.`);

  // save session, if running locally, but not in CI
  if (!process.env.CI) {
    const sessionCookies = await page.context().cookies();
    const sessionCookiesJson = join(__dirname, `./sessions.json`);
    let existingAccounts = {};
    if (existsSync(sessionCookiesJson))
      existingAccounts = require(sessionCookiesJson);
    writeFileSync(
      sessionCookiesJson,
      JSON.stringify({ ...existingAccounts, [email]: sessionCookies }),
    );
    console.log(`Saved session for ${email}.`);
  }
}

export async function tryRestoringSession(page: Page, email: string) {
  console.log(`Trying to restore session for ${email}.`);
  try {
    const sessionCookies = process.env.CI
      ? JSON.parse(process.env.MRF_SESSIONS!)
      : require(join(__dirname, './sessions.json'));
    await page.context().addCookies(sessionCookies[email]);
    console.log(`Restored session for ${email}`);
    await page.goto('https://rewards.bing.com/');
    return true;
  } catch (e) {
    console.log(`No session found for ${email}`);
    return false;
  }
}
