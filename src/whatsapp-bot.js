require('dotenv').config();
import { randomBytes } from 'crypto';
const server = require('express')();
import { generate } from 'qrcode-terminal';
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc, updateDoc } from 'firebase/firestore/lite';
import { Client, LocalAuth } from 'whatsapp-web.js';
const wa = new Client({
  authStrategy: new LocalAuth(),
  puppeteer: { headless: true },
});

// initialize server
server.listen(process.env.PT, () => {
  console.log('Server started successfully');
});

// intialize whatsapp
wa.initialize();
wa.on('qr', (qr) => {
  generate(qr, { small: true });
});
wa.on('authenticated', () => {
  console.log('Session authentication successful or restored.');
});
wa.on('auth_failure', (err) => {
  console.error(err);
});
wa.on('ready', () => {
  console.log('WhatsApp Bot is ready!');
});

// initialize firesbase and get the firestore document
const app = initializeApp({
  apiKey: process.env.FRBE_KY,
  authDomain: process.env.FRBE_DMN,
  projectId: process.env.FRBE_PJID,
});
const firestore = getFirestore(app);
const database = doc(firestore, process.env.FRBE_CLN, process.env.FRBE_DC);

// authenticate new users and give them a unique key
wa.on('message', (message) => {
  if (message.body === process.env.FRBE_RG_MG) {
    const auth = randomBytes(16).toString('hex');
    wa.sendMessage(message.from, `Authentication key: ${auth}`);
    updateDoc(database, { [`${message.from.split('@')[0]}`]: auth }).then(
      function () {
        console.log('+' + message.from.split('@')[0] + ' has been registered.');
      }
    );
  }
});

// start listening on server and send the message to the user
// if the authentication key is valid else send an error message
server.get(process.env.FRBE_LN_PH, (req, res) => {
  if (!req.query.sendto || !req.query.text || !req.query.auth) {
    res.status(418);
    res.send('Missing parameters.');
    return;
  }
  getDoc(database).then((doc) => {
    const authInDatabase = doc.data()[`${req.query.sendto}`];
    if (authInDatabase === req.query.auth) {
      wa.sendMessage(`${req.query.sendto}@c.us`, `${req.query.text}`).then(
        () => {
          res.status(200);
          res.send(`
            <b>Status</b>: Successful <br>
            <b>To</b>: +${req.query.sendto} <br>
            <b>Message</b>: ${req.query.text}
          `);
        }
      );
    } else if (
      authInDatabase != req.query.auth &&
      authInDatabase != undefined
    ) {
      res.status(418);
      res.send('Authentication key is invalid.');
    } else {
      res.status(418);
      res.send('User is not registered.');
    }
  });
});
