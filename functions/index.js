const crypto = require('crypto');

const { onCall, HttpsError } = require('firebase-functions/v2/https');

const { defineSecret } = require('firebase-functions/params');

const { initializeApp } = require('firebase-admin/app');

const { getAuth } = require('firebase-admin/auth');

const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const { getMessaging } = require('firebase-admin/messaging');

const { logger } = require('firebase-functions');

const nodemailer = require('nodemailer');



initializeApp();



const smtpHost = defineSecret('SMTP_HOST');

const smtpPort = defineSecret('SMTP_PORT');

const smtpUser = defineSecret('SMTP_USER');

const smtpPass = defineSecret('SMTP_PASS');

const smtpFrom = defineSecret('SMTP_FROM');

const resendApiKey = defineSecret('RESEND_API_KEY');



const OTP_TTL_MS = 10 * 60 * 1000;

const RESEND_COOLDOWN_MS = 60 * 1000;

const MAX_SENDS_PER_HOUR = 5;

const MAX_VERIFY_ATTEMPTS = 8;

const CREATOR_EMAIL = 'nbs27933@gmail.com';

const BROADCAST_TOPIC = 'all_users';

const MAX_BROADCASTS_PER_HOUR = 5;

const MAX_BROADCAST_TITLE = 80;

const MAX_BROADCAST_BODY = 280;



function normalizeEmail(email) {

  return String(email || '').trim().toLowerCase();

}



function otpDocId(email) {

  return crypto.createHash('sha256').update(normalizeEmail(email)).digest('hex');

}



function hashCode(code, email) {

  return crypto.createHash('sha256').update(`${normalizeEmail(email)}:${code}`).digest('hex');

}



function generateCode() {

  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');

}



function emailCopy(lang, code) {

  const appName = 'Mneem';

  switch (lang) {

    case 'en':

      return {

        subject: `${appName} — verification code`,

        text:

          `Your verification code: ${code}\n\n` +

          `Enter this code in the app. The code expires in 10 minutes.\n\n` +

          `If you did not create an account, ignore this email.`,

        html:

          `<p>Your verification code:</p>` +

          `<p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p>` +

          `<p>Enter this code in the app. Expires in 10 minutes.</p>` +

          `<p style="color:#888">If you did not create an account, ignore this email.</p>`,

      };

    case 'de':

      return {

        subject: `${appName} — Bestätigungscode`,

        text:

          `Dein Bestätigungscode: ${code}\n\n` +

          `Gib den Code in der App ein. Er läuft in 10 Minuten ab.\n\n` +

          `Wenn du kein Konto erstellt hast, ignoriere diese E-Mail.`,

        html:

          `<p>Dein Bestätigungscode:</p>` +

          `<p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p>` +

          `<p>Gib den Code in der App ein. Läuft in 10 Minuten ab.</p>` +

          `<p style="color:#888">Wenn du kein Konto erstellt hast, ignoriere diese E-Mail.</p>`,

      };

    case 'ru':

    default:

      return {

        subject: `${appName} — код подтверждения`,

        text:

          `Код подтверждения: ${code}\n\n` +

          `Введи этот код в приложении. Код действует 10 минут.\n\n` +

          `Если ты не регистрировался — просто проигнорируй письмо.`,

        html:

          `<p>Код подтверждения:</p>` +

          `<p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p>` +

          `<p>Введи код в приложении. Действует 10 минут.</p>` +

          `<p style="color:#888">Если ты не регистрировался — проигнорируй письмо.</p>`,

      };

  }

}



function hasSmtpConfig() {

  const host = smtpHost.value();

  const user = smtpUser.value();

  const pass = smtpPass.value();

  return Boolean(host && user && pass);

}



function hasResendConfig() {

  return Boolean(resendApiKey.value());

}



function createTransport() {

  const host = smtpHost.value();

  const user = smtpUser.value();

  const pass = smtpPass.value();

  if (!host || !user || !pass) {

    throw new HttpsError(

      'failed-precondition',

      'Email service is not configured. Set SMTP_HOST, SMTP_USER, SMTP_PASS secrets.',

    );

  }

  const port = Number(smtpPort.value() || '587');

  return nodemailer.createTransport({

    host,

    port,

    secure: port === 465,

    requireTLS: port === 587,

    auth: { user, pass },

    tls: { minVersion: 'TLSv1.2' },

  });

}



async function sendViaResend({ to, subject, text, html }) {

  const apiKey = resendApiKey.value();

  if (!apiKey) {

    throw new HttpsError(

      'failed-precondition',

      'Email service is not configured. Set RESEND_API_KEY or SMTP secrets.',

    );

  }

  const from = smtpFrom.value() || 'Mneem <onboarding@resend.dev>';

  const response = await fetch('https://api.resend.com/emails', {

    method: 'POST',

    headers: {

      Authorization: `Bearer ${apiKey}`,

      'Content-Type': 'application/json',

    },

    body: JSON.stringify({ from, to: [to], subject, text, html }),

  });

  if (!response.ok) {

    const body = await response.text();

    logger.error('Resend API error', { status: response.status, body });

    throw new HttpsError('internal', 'Could not send verification email. Try again later.');

  }

}



async function sendVerificationEmail({ to, subject, text, html }) {

  if (hasResendConfig()) {

    await sendViaResend({ to, subject, text, html });

    return;

  }

  if (!hasSmtpConfig()) {

    throw new HttpsError(

      'failed-precondition',

      'Email service is not configured. Set SMTP_HOST, SMTP_USER, SMTP_PASS secrets.',

    );

  }

  const from = smtpFrom.value() || smtpUser.value();

  const transport = createTransport();

  try {

    await transport.sendMail({ from, to, subject, text, html });

  } catch (err) {

    logger.error('SMTP send failed', { message: err.message, code: err.code });

    throw new HttpsError(

      'internal',

      'Could not send verification email. Check SMTP settings or try again later.',

    );

  }

}



async function assertAuthed(request) {

  if (!request.auth?.uid) {

    throw new HttpsError('unauthenticated', 'Sign in required.');

  }

  const user = await getAuth().getUser(request.auth.uid);

  if (!user.email) {

    throw new HttpsError('failed-precondition', 'Account has no email.');

  }

  if (user.emailVerified) {

    throw new HttpsError('already-exists', 'Email is already verified.');

  }

  return user;

}



const sendSecrets = [smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, resendApiKey];



exports.sendEmailVerificationCode = onCall(

  {

    region: 'europe-west1',

    secrets: sendSecrets,

  },

  async (request) => {

    const user = await assertAuthed(request);

    const lang = ['ru', 'en', 'de'].includes(request.data?.lang) ? request.data.lang : 'ru';

    const email = normalizeEmail(user.email);

    const db = getFirestore();

    const ref = db.collection('email_otps').doc(otpDocId(email));

    const now = Date.now();



    const snap = await ref.get();

    const prev = snap.data() || {};

    const hourBucket = Math.floor(now / (60 * 60 * 1000));

    const sendCount =

      prev.sendHourBucket === hourBucket ? Number(prev.sendCount || 0) : 0;

    if (sendCount >= MAX_SENDS_PER_HOUR) {

      throw new HttpsError('resource-exhausted', 'Too many codes sent. Try again later.');

    }

    const lastSentAt = Number(prev.lastSentAt || 0);

    if (now - lastSentAt < RESEND_COOLDOWN_MS) {

      const waitSec = Math.ceil((RESEND_COOLDOWN_MS - (now - lastSentAt)) / 1000);

      throw new HttpsError('resource-exhausted', `Wait ${waitSec}s before requesting a new code.`);

    }



    const code = generateCode();

    const copy = emailCopy(lang, code);

    await sendVerificationEmail({

      to: email,

      subject: copy.subject,

      text: copy.text,

      html: copy.html,

    });



    await ref.set({

      uid: user.uid,

      email,

      codeHash: hashCode(code, email),

      expiresAt: now + OTP_TTL_MS,

      attempts: 0,

      lastSentAt: now,

      sendHourBucket: hourBucket,

      sendCount: sendCount + 1,

      updatedAt: FieldValue.serverTimestamp(),

    });



    logger.info('Verification code sent', { email: `${email[0]}***`, uid: user.uid });

    return { ok: true, expiresInSec: Math.floor(OTP_TTL_MS / 1000) };

  },

);



exports.verifyEmailVerificationCode = onCall(

  { region: 'europe-west1' },

  async (request) => {

    const user = await assertAuthed(request);

    const rawCode = String(request.data?.code || '').trim();

    if (!/^\d{6}$/.test(rawCode)) {

      throw new HttpsError('invalid-argument', 'Enter the 6-digit code from your email.');

    }



    const email = normalizeEmail(user.email);

    const db = getFirestore();

    const ref = db.collection('email_otps').doc(otpDocId(email));

    const snap = await ref.get();

    if (!snap.exists) {

      throw new HttpsError('not-found', 'No active code. Request a new one.');

    }

    const data = snap.data();

    if (data.uid !== user.uid) {

      throw new HttpsError('permission-denied', 'Code does not match this account.');

    }



    const now = Date.now();

    if (now > Number(data.expiresAt || 0)) {

      await ref.delete();

      throw new HttpsError('deadline-exceeded', 'Code expired. Request a new one.');

    }



    const attempts = Number(data.attempts || 0);

    if (attempts >= MAX_VERIFY_ATTEMPTS) {

      await ref.delete();

      throw new HttpsError('resource-exhausted', 'Too many attempts. Request a new code.');

    }



    const expected = data.codeHash;

    const actual = hashCode(rawCode, email);

    if (expected !== actual) {

      await ref.update({ attempts: attempts + 1 });

      throw new HttpsError('invalid-argument', 'Wrong code. Check the email and try again.');

    }



    await getAuth().updateUser(user.uid, { emailVerified: true });

    await ref.delete();

    return { ok: true };

  },

);



async function assertCreator(request) {

  if (!request.auth?.uid) {

    throw new HttpsError('unauthenticated', 'Sign in required.');

  }

  const user = await getAuth().getUser(request.auth.uid);

  const email = normalizeEmail(user.email);

  if (email !== CREATOR_EMAIL) {

    throw new HttpsError('permission-denied', 'Creator access only.');

  }

  return user;

}



/** Creator-only push to all users subscribed to [all_users] FCM topic. */

exports.sendCreatorBroadcastPush = onCall(

  { region: 'europe-west1' },

  async (request) => {

    const user = await assertCreator(request);

    const title = String(request.data?.title || '').trim().slice(0, MAX_BROADCAST_TITLE);

    const body = String(request.data?.body || '').trim().slice(0, MAX_BROADCAST_BODY);

    if (!title) {

      throw new HttpsError('invalid-argument', 'Title is required.');

    }

    if (!body) {

      throw new HttpsError('invalid-argument', 'Message text is required.');

    }



    const db = getFirestore();

    const metaRef = db.collection('admin_meta').doc('broadcasts');

    const now = Date.now();

    const hourBucket = Math.floor(now / (60 * 60 * 1000));

    const metaSnap = await metaRef.get();

    const meta = metaSnap.data() || {};

    const sendCount =

      meta.sendHourBucket === hourBucket ? Number(meta.sendCount || 0) : 0;

    if (sendCount >= MAX_BROADCASTS_PER_HOUR) {

      throw new HttpsError(

        'resource-exhausted',

        'Broadcast limit reached. Try again later.',

      );

    }



    const messageId = await getMessaging().send({

      topic: BROADCAST_TOPIC,

      notification: { title, body },

      data: {

        type: 'creator_broadcast',

        title,

        body,

      },

      android: {

        priority: 'high',

        notification: {

          channelId: 'mnemonik_broadcast',

          sound: 'notification_alert',

        },

      },

      apns: {

        payload: {

          aps: {

            sound: 'default',

            alert: { title, body },

          },

        },

      },

    });



    await metaRef.set(

      {

        sendHourBucket: hourBucket,

        sendCount: sendCount + 1,

        lastBroadcastAtMs: now,

        lastTitle: title,

        lastBody: body,

        lastMessageId: messageId,

        updatedAt: FieldValue.serverTimestamp(),

      },

      { merge: true },

    );



    await db.collection('creator_broadcast_logs').add({

      uid: user.uid,

      email: normalizeEmail(user.email),

      title,

      body,

      messageId,

      topic: BROADCAST_TOPIC,

      createdAtMs: now,

      createdAt: FieldValue.serverTimestamp(),

    });



    logger.info('Creator broadcast sent', {

      uid: user.uid,

      messageId,

      titleLength: title.length,

      bodyLength: body.length,

    });



    return { ok: true, messageId, topic: BROADCAST_TOPIC };

  },

);

