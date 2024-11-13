import chromium from '@sparticuz/chromium-min';
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { initializeApp } from 'firebase/app';
import { doc, getDoc, getFirestore } from 'firebase/firestore/lite';
import { getStorage } from 'firebase/storage';
/*
Error: Named export 'RemoteAuth' not found. The requested module 'whatsapp-web.js' is a CommonJS module, which may not support all module.exports as named exports.
CommonJS modules can always be imported via the default export, for example using:

import pkg from 'whatsapp-web.js';
const { Client, RemoteAuth } = pkg;
*/
import WAWebJS, { Client } from 'whatsapp-web.js';
import { FirebaseStorageStore } from 'wwebjs-firebase-storage';

const app = initializeApp({
  apiKey: process.env.FB_API_KEY,
  projectId: process.env.FB_PROJECT_ID,
  storageBucket: process.env.FB_STORAGE_BUCKET,
});
// initializeAppCheck(app, {
//   provider: new ReCaptchaV3Provider(''),
//   isTokenAutoRefreshEnabled: true,
// });
const database = doc(
  getFirestore(app),
  process.env.WA_FB_CLN!,
  process.env.WA_FB_DOC!,
);

export default async (req: VercelRequest, res: VercelResponse) => {
  const { to, msg, auth: authKey } = req.query;
  if (!to || !msg || !authKey) {
    return res.status(400).send('Missing parameters.').end();
  }

  // send message to given user if the auth key is valid else send an error message
  const authInDatabase = (await getDoc(database)).data()![`${req.query.to}`];
  if (authInDatabase === authKey) {
    const wa = new Client({
      authStrategy: new WAWebJS.RemoteAuth({
        store: new FirebaseStorageStore({
          firebaseStorage: getStorage(app),
        }),
        backupSyncIntervalMs: 60000, // 1 minute
      }),
      qrMaxRetries: 3,
      puppeteer: {
        executablePath: await chromium.executablePath(
          (
            await (
              await fetch(
                'https://api.github.com/repos/Sparticuz/chromium/releases/latest',
              )
            ).json()
          ).assets.find((asset: { name: string }) =>
            asset.name.endsWith('pack.tar'),
          ).browser_download_url,
        ),
        args: chromium.args,
        headless: true,
        defaultViewport: chromium.defaultViewport,
      },
    });
    wa.on(
      'qr',
      async () =>
        await fetch(`https://ntfy.sh/${process.env.WA_NTFY}`, {
          method: 'POST', // PUT works too
          body: `${await wa.requestPairingCode(process.env.WA_NO!, true)}${process.env.VERCEL ? ';' : ''}`,
        }),
    );
    wa.on(
      'ready',
      async () =>
        await wa.sendMessage(`${req.query.to}@c.us`, `${req.query.msg}`, {
          sendSeen: false,
        }),
    );
    await wa.initialize();

    // prettier-ignore
    res.status(200).send(`
      <b>Status</b>: Successful <br>
      <b>To</b>: +${req.query.to} <br>
      <b>Message</b>: ${req.query.msg}
    `).end();
  } else if (authInDatabase !== authKey && authInDatabase != undefined) {
    res.status(403).send('Authentication key is invalid.').end();
  } else {
    res.status(404).send('User is not registered.').end();
  }
};
