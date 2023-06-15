import { Page } from 'playwright';
import { join } from 'node:path';
import { writeFileSync } from 'node:fs';

export async function login(page: Page, email: string, _password: string) {
  console.log(`Logging in as ${email}...`);
  await page.goto('https://rewards.bing.com/');
  await page.click('text=Sign in');
  await page.fill('input[type="email"]', email);
  await page.click('input[type="submit"]');
  await page.click('text=Other ways to sign in');
  await page.click('text=Windows Hello or a security key');
  // wait for 'stay signed in' checkbox to appear
  await page.waitForSelector('text=Stay signed in?');
  await page.click('input[type="submit"]');
  console.log(`Successfully logged in as ${email}.`);
}

export async function tryRestoringSession(page: Page, email: string) {
  const sessionCookiesJson = join(__dirname, `./session-${email}.json`);
  console.log(`Trying to restore session for ${email}.`);
  try {
    const sessionCookies = require(sessionCookiesJson);
    await page.context().addCookies(sessionCookies);
    console.log(`Restored session for ${email}`);
    await page.goto('https://rewards.bing.com/');
    return true;
  }
  catch (e) {
    console.log(`No session found for ${email}`);
    return false;
  }
}

export async function saveSession(page: Page, email: string) {
  const sessionCookies = await page.context().cookies();
  const sessionCookiesJson = join(__dirname, `./session-${email}.json`);

  writeFileSync(sessionCookiesJson, JSON.stringify(sessionCookies, null, 2));
  console.log(`Saved session for ${email}.`);
}