/**
 * Auralis — Aura Coach relay
 *
 * A tiny Cloudflare Worker that stands between the iOS app and OpenAI so the
 * API key never ships inside the app binary.
 *
 * The app POSTs:   { "system": "…", "messages": [ { "role": "user", "content": "…" } ] }
 * The Worker returns: { "reply": "…" }
 *
 * Any non-2xx response makes the app fall back to its on-device coach, so an
 * empty balance, a rate limit or an outage degrades invisibly for the user.
 *
 * Secrets (set with `wrangler secret put`, never in this file):
 *   OPENAI_API_KEY   — required
 *   APP_SHARED_TOKEN — optional; if set, requests must send a matching
 *                      X-Auralis-Token header.
 *
 * See docs/CoachRelay-Setup.md for deployment steps.
 */

const MODEL = "gpt-4o-mini";       // inexpensive and plenty for short coaching replies
const MAX_TOKENS = 260;            // caps cost per reply
const MAX_MESSAGES = 10;           // caps cost per request
const MAX_CHARS_PER_MESSAGE = 2000;
const MAX_SYSTEM_CHARS = 4000;

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    // Optional shared token. Raises the bar against strangers burning your quota.
    if (env.APP_SHARED_TOKEN) {
      if (request.headers.get("X-Auralis-Token") !== env.APP_SHARED_TOKEN) {
        return json({ error: "unauthorized" }, 401);
      }
    }

    if (!env.OPENAI_API_KEY) {
      // Misconfigured: tell the app to fall back rather than hang.
      return json({ error: "not_configured" }, 503);
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: "bad_request" }, 400);
    }

    const system = String(payload?.system ?? "").slice(0, MAX_SYSTEM_CHARS);
    const incoming = Array.isArray(payload?.messages) ? payload.messages : [];

    const messages = incoming
      .slice(-MAX_MESSAGES)
      .map((m) => ({
        role: m?.role === "user" ? "user" : "assistant",
        content: String(m?.content ?? "").slice(0, MAX_CHARS_PER_MESSAGE),
      }))
      .filter((m) => m.content.length > 0);

    if (messages.length === 0) {
      return json({ error: "empty_conversation" }, 400);
    }

    const body = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      temperature: 0.85,
      presence_penalty: 0.3,
      messages: system ? [{ role: "system", content: system }, ...messages] : messages,
    };

    let upstream;
    try {
      upstream = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify(body),
      });
    } catch {
      return json({ error: "upstream_unreachable" }, 502);
    }

    // 401 bad key · 429 rate limited · 402/quota · 5xx outage.
    // All of these become a non-2xx here, and the app quietly goes on-device.
    if (!upstream.ok) {
      return json({ error: "upstream_error", status: upstream.status }, 502);
    }

    let data;
    try {
      data = await upstream.json();
    } catch {
      return json({ error: "upstream_malformed" }, 502);
    }

    const reply = data?.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      return json({ error: "empty_reply" }, 502);
    }

    return json({ reply });
  },
};
