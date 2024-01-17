import type { VercelRequest, VercelResponse } from '@vercel/node';
import { chromium } from 'playwright';

export default async function (req: VercelRequest, res: VercelResponse) {
    const { text, from, to } = req.query;

    if (!text || !from || !to) {
        res.status(400)
        res.setHeader('Content-Type', 'text/plain')
        res.send('Missing query parameters')
        return
    }

    const browser = await chromium.connectOverCDP(`wss://chrome.browserless.io?token=${process.env.BLESS_TKN}`);
    const page = await browser.newPage()
    await page.goto(`https://translate.google.com/?sl=${from}&tl=${to}&text=${text}&op=translate`)

    await page.waitForSelector('span[jsname="W297wb"]')
    const result = await page.$eval('span[jsname="W297wb"]', (el) => el.textContent)

    await page.close()
    await browser.close()

    res.status(200)
    res.setHeader('Content-Type', 'text/plain')
    res.send(result)
}
