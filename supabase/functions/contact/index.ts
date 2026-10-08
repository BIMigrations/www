/**
 * BI Migrations — contact endpoint.
 *
 * POST JSON (or form-encoded) from the website forms. Validates the submission
 * hard (work email domain, real first and last name, non-junk message), then
 * emails it to the team over SMTP. Optionally sends the sender an auto-reply.
 *
 * Secrets come from the function's environment — never commit them:
 *   supabase secrets set SMTP_HOST=... SMTP_PORT=587 SMTP_USER=... SMTP_PASS=... MAIL_TO=...
 */
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";
import { validate, type Submission } from "./validate.ts";
import {
  autoReplyHtml,
  autoReplySubject,
  autoReplyText,
  type Meta,
  notificationHtml,
  notificationSubject,
  notificationText,
} from "./email.ts";

const env = (key: string, fallback = ""): string => Deno.env.get(key) ?? fallback;

const SMTP_HOST = env("SMTP_HOST");
const SMTP_PORT = Number(env("SMTP_PORT", "587"));
const SMTP_USER = env("SMTP_USER");
const SMTP_PASS = env("SMTP_PASS");
// Must be an address verified in SES. abi@bimigrations.com is the verified one.
const MAIL_FROM = env("MAIL_FROM", "BI Migrations <abi@bimigrations.com>");
// Where enquiries land. Comma-separated; override with the MAIL_TO secret.
const MAIL_TO = env("MAIL_TO", "abi@bimigrations.com,les@bimigrations.com")
  .split(",").map((s) => s.trim()).filter(Boolean);
const AUTO_REPLY = env("AUTO_REPLY", "true") === "true";
const ALLOW_PUBLIC_DOMAINS = env("ALLOW_PUBLIC_DOMAINS", "false") === "true";
const MIN_FILL_SECONDS = Number(env("MIN_FILL_SECONDS", "3"));
const ALLOWED_ORIGINS = env(
  "ALLOWED_ORIGINS",
  "https://bimigrations.com,https://www.bimigrations.com,http://localhost:4321",
).split(",").map((s) => s.trim()).filter(Boolean);

const MAX_BODY_BYTES = 32_000;
const RATE_LIMIT = { max: 5, windowMs: 10 * 60 * 1000 };
const hits = new Map<string, number[]>();

function corsHeaders(origin: string): Record<string, string> {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0] ?? "*";
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

const json = (body: unknown, status: number, origin: string) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...corsHeaders(origin) },
  });

function rateLimited(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < RATE_LIMIT.windowMs);
  recent.push(now);
  hits.set(ip, recent);
  if (hits.size > 5000) {
    for (const [key, times] of hits) {
      if (times.every((t) => now - t >= RATE_LIMIT.windowMs)) hits.delete(key);
    }
  }
  return recent.length > RATE_LIMIT.max;
}

async function parseBody(req: Request): Promise<Submission | null> {
  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return null;
  const type = req.headers.get("content-type") ?? "";
  try {
    if (type.includes("application/json")) return JSON.parse(raw) as Submission;
    if (type.includes("application/x-www-form-urlencoded")) {
      return Object.fromEntries(new URLSearchParams(raw)) as Submission;
    }
    return JSON.parse(raw) as Submission; // tolerate a missing content-type
  } catch {
    return null;
  }
}

async function send(
  client: SMTPClient,
  to: string[],
  subject: string,
  text: string,
  html: string,
  replyTo?: string,
) {
  await client.send({
    from: MAIL_FROM,
    to,
    subject,
    content: text,
    html,
    ...(replyTo ? { replyTo } : {}),
  });
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin") ?? "";

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }
  if (req.method !== "POST") {
    return json({ ok: false, error: "Method not allowed" }, 405, origin);
  }
  if (origin && !ALLOWED_ORIGINS.includes(origin)) {
    console.warn(JSON.stringify({ event: "origin_rejected", origin }));
    return json({ ok: false, error: "Not allowed" }, 403, origin);
  }
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS || MAIL_TO.length === 0) {
    console.error("missing SMTP configuration");
    return json({ ok: false, error: "Server not configured" }, 500, origin);
  }

  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";
  if (rateLimited(ip)) {
    console.warn(JSON.stringify({ event: "rate_limited", ip }));
    return json(
      { ok: false, errors: ["Too many submissions. Please try again shortly."] },
      429,
      origin,
    );
  }

  const body = await parseBody(req);
  if (!body) return json({ ok: false, errors: ["Could not read that submission."] }, 400, origin);

  const result = validate(body, {
    minFillSeconds: MIN_FILL_SECONDS,
    allowPublicDomains: ALLOW_PUBLIC_DOMAINS,
  });

  if (!result.ok || !result.data) {
    console.warn(JSON.stringify({
      event: "rejected",
      ip,
      reasons: result.reasons,
      email: String(body.email ?? "").slice(0, 80),
    }));
    return json({ ok: false, errors: result.errors }, 422, origin);
  }

  const data = result.data;
  const meta: Meta = {
    ip,
    userAgent: req.headers.get("user-agent") ?? "unknown",
    origin: origin || "direct",
    receivedAt: new Date().toISOString(),
  };

  const client = new SMTPClient({
    connection: {
      hostname: SMTP_HOST,
      port: SMTP_PORT,
      tls: SMTP_PORT === 465, // 587 upgrades with STARTTLS
      auth: { username: SMTP_USER, password: SMTP_PASS },
    },
  });

  try {
    await send(
      client,
      MAIL_TO,
      notificationSubject(data),
      notificationText(data, meta),
      notificationHtml(data, meta),
      data.email,
    );

    if (AUTO_REPLY) {
      try {
        await send(
          client,
          [data.email],
          autoReplySubject(),
          autoReplyText(data),
          autoReplyHtml(data),
        );
      } catch (err) {
        // the enquiry is already with us; a failed auto-reply must not fail the request
        console.error(JSON.stringify({ event: "autoreply_failed", error: String(err) }));
      }
    }

    console.log(JSON.stringify({
      event: "accepted",
      form: data.form,
      domain: data.domain,
      ip,
      notes: result.reasons,
    }));
    return json({ ok: true }, 200, origin);
  } catch (err) {
    console.error(JSON.stringify({ event: "send_failed", error: String(err) }));
    return json(
      { ok: false, errors: ["We couldn't send that just now. Please email us directly."] },
      502,
      origin,
    );
  } finally {
    try {
      await client.close();
    } catch { /* already closed */ }
  }
});
