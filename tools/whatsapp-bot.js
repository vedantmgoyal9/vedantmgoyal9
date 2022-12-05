require('dotenv').config();
const { readFileSync, createWriteStream } = require('fs');
const { format } = require('util');
const { randomBytes } = require('crypto');
const { initializeApp } = require('firebase/app');
const {
  getFirestore,
  doc,
  getDoc,
  updateDoc,
} = require('firebase/firestore/lite');
const { Client, LocalAuth } = require('whatsapp-web.js');
const server = require('express')();
const log_file = createWriteStream(`${__dirname}/logs.txt`, {
  flags: 'a',
});
const wa = new Client({
  authStrategy: new LocalAuth(), // 👇 remove args when not running on linux
  puppeteer: { headless: true, args: ['--no-sandbox'] },
});

// make console.log to output to both console and log file
console.log = function (log_line) {
  log_file.write(format(log_line) + '\n');
  process.stdout.write(format(log_line) + '\n');
};

// initialize server, port is PT env variable
server.listen(process.env.PT, () => {
  console.log('Server started successfully');
});

// intialize whatsapp
wa.initialize();
wa.on('qr', (qr) => {
  process.stdout.write(qr + '\n');
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
  if (message.body === process.env.WA_RG_MG) {
    const auth = randomBytes(16).toString('hex');
    wa.sendMessage(message.from, `Authentication key: ${auth}`);
    updateDoc(database, { [`${message.from.split('@')[0]}`]: auth }).then(
      function () {
        console.log(`+${message.from.split('@')[0]} has been registered.`);
      },
    );
  }
});

// make logs available on the internet
// hide phone number on the internet, privacy is important!
server.get('/logs.txt', function (req, res) {
  res.status(200);
  res.send(
    readFileSync(`${__dirname}/logs.txt`, 'utf8')
      .replace(/(?<=\+[0-9]{3})\d+(?=;|\s)/g, 'XXXXXXXXX')
      .replace(/\n/g, '<br/>'), // replace new lines with <br/>
  );
});

// start listening on server and send the message to the user
// if the authentication key is valid else send an error message
server.get('/', (req, res) => {
  if (!req.query.to || !req.query.msg || !req.query.auth) {
    res.status(418);
    res.send('Missing parameters.');
    return;
  }
  getDoc(database).then((doc) => {
    const authInDatabase = doc.data()[`${req.query.to}`];
    if (authInDatabase === req.query.auth) {
      wa.sendMessage(`${req.query.to}@c.us`, `${req.query.msg}`).then(() => {
        res.status(200);
        res.send(`
            <b>Status</b>: Successful <br>
            <b>To</b>: +${req.query.to} <br>
            <b>Message</b>: ${req.query.msg}
          `);
        console.log(
          `To: +${req.query.to}; Message: ${req.query.msg}\n-----------`,
        );
      });
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
