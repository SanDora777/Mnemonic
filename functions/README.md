# Email OTP (Cloud Functions)

Sends a 6-digit verification code when users register or sign in with an unverified email.

## Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Email delivery (required for 6-digit codes)

Choose **one** option.

### Option A — Resend (recommended)

1. Create an API key at [resend.com](https://resend.com).
2. Verify your sender domain (or use `onboarding@resend.dev` for testing).
3. Set secrets:

```bash
firebase functions:secrets:set RESEND_API_KEY SMTP_FROM
```

| Secret | Example |
|--------|---------|
| `RESEND_API_KEY` | `re_...` |
| `SMTP_FROM` | `Mneem <noreply@yourdomain.com>` |

### Option B — SMTP (Gmail, etc.)

```bash
firebase functions:secrets:set SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS SMTP_FROM
```

| Secret | Example |
|--------|---------|
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` | `your@gmail.com` |
| `SMTP_PASS` | [App Password](https://myaccount.google.com/apppasswords) |
| `SMTP_FROM` | `Mneem <your@gmail.com>` |

Without Resend/SMTP secrets, the app falls back to Firebase’s **verification link** email (no 6-digit code).
