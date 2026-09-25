# Aura Coach relay — setup

> **Status: live.** The relay is deployed at
> `https://auralis-coach.ksbpstech.workers.dev` with `OPENAI_API_KEY` stored as
> an encrypted Cloudflare secret, and the URL is wired into
> `AuraEnergyRevealed/Services/CoachRelay.swift`. Verified end to end on
> 25 Sep 2026: a live request returned a real model reply, and the failure
> paths (empty body, malformed JSON, wrong method) all return non-2xx so the
> app falls back to its on-device coach.
>
> The rest of this document is kept for reference and for rebuilding the relay.

The app never contains your OpenAI key. Instead it calls a small relay you own,
and the key lives there as a secret. This takes about ten minutes, once, and
costs nothing on Cloudflare's free plan.

**Never paste your OpenAI key into the app, into this repo, or into a chat.**
It only ever goes into the Cloudflare secret box in step 4.

---

## Before you start

Set a spending cap on your OpenAI account first — this is the single most
important safety step.

1. Go to **platform.openai.com → Settings → Billing → Limits**.
2. Set a **monthly budget** you're comfortable with (for example $25).
3. Set a **notification threshold** lower than that (for example $15).

If the budget is reached, OpenAI stops serving requests, the relay returns an
error, and the app silently falls back to its on-device coach. Nobody sees a
broken screen — that behaviour is built in and tested.

---

## Deploy the relay (no terminal needed)

1. **Create a free Cloudflare account** at <https://dash.cloudflare.com/sign-up>.

2. In the sidebar choose **Compute (Workers) → Create → Start with Hello World →
   Deploy**. Name it `auralis-coach`.

3. Click **Edit code**. Delete everything in the editor, then paste the entire
   contents of [`relay/worker.js`](../relay/worker.js) from this repo. Click
   **Deploy**.

4. Open the Worker's **Settings → Variables and Secrets → Add**.
   - Type: **Secret**
   - Name: `OPENAI_API_KEY`
   - Value: *your OpenAI key*

   Click **Deploy**. Cloudflare encrypts it; it is never readable again from the
   dashboard, and it never reaches the app.

5. Copy the Worker's URL from the Worker overview page. It looks like:

   ```
   https://auralis-coach.<your-subdomain>.workers.dev
   ```

6. Send **only that URL** back to me. I'll paste it into
   `AuraEnergyRevealed/Services/CoachRelay.swift` as:

   ```swift
   static let endpointString = "https://auralis-coach.<your-subdomain>.workers.dev"
   ```

---

## Optional: lock the relay to your app

Anyone who finds the URL could use your quota. To reduce that risk:

1. Add a second secret named `APP_SHARED_TOKEN` with any long random string.
2. Tell me, and I'll have the app send it as an `X-Auralis-Token` header.

This is not perfect — a determined person can still read the token out of any
iOS app — but it stops casual abuse. Combined with the OpenAI spend cap and the
per-request limits in the Worker (short replies, max 10 messages of history),
your exposure stays small.

---

## Checking it works

Paste this into a terminal, replacing the URL:

```bash
curl -X POST https://auralis-coach.<your-subdomain>.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"system":"You are a warm wellness companion.","messages":[{"role":"user","content":"I feel scattered today."}]}'
```

A healthy relay replies with `{"reply":"..."}`.
Anything else means the app will use its on-device coach — which is a safe
state, not a broken one.

---

## What happens when things go wrong

| Situation | What the person using the app sees |
|---|---|
| OpenAI balance empty / budget hit | A normal reply, written on-device |
| Rate limited or OpenAI outage | A normal reply, written on-device |
| Phone is offline | A normal reply, written on-device |
| Relay URL not set yet | A normal reply, written on-device |
| Relay slow (> 12 seconds) | A normal reply, written on-device |

In every case the conversation continues and no error is shown. This matters
during App Review: a reviewer testing the coach with an empty balance still
sees a fully working feature.
