/**
 * BI Migrations: demo-video viewing log.
 *
 * The website posts one small JSON event per milestone (text/plain, so it is a simple CORS
 * request that can also leave through sendBeacon when the tab closes). This function validates it
 * and stores a row in public.video_events. It never returns detail to the caller.
 *
 * Privacy: no raw IP is stored. Country comes from the edge network's country header, and a salted
 * hash of the IP (secret VIDEO_IP_SALT) is kept only to rate-limit and count distinct networks.
 *
 * Deploy:  supabase functions deploy video-events --no-verify-jwt
 * Secrets: supabase secrets set VIDEO_IP_SALT="<long random string>"
 */
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const IP_SALT = Deno.env.get("VIDEO_IP_SALT") ?? "";
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ??
  "https://bimigrations.com,https://www.bimigrations.com,http://localhost:4321")
  .split(",").map((s) => s.trim()).filter(Boolean);

const MAX_BODY_BYTES = 4_000;
const RATE_LIMIT = { max: 120, windowMs: 10 * 60 * 1000 };
const EVENTS = new Set(["video_start", "video_progress", "video_complete", "video_summary"]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VIDEO_ID = /^[a-z0-9][a-z0-9-]{0,59}$/;
const BOT = /bot|crawl|spider|headless|lighthouse|pagespeed|preview|monitor/i;

function cors(origin: string): Record<string, string> {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0] ?? "*";
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}
const reply = (status: number, origin: string) => new Response(null, { status, headers: cors(origin) });

const int = (v: unknown, max: number): number | null => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.max(0, Math.min(max, Math.round(n))) : null;
};
const flag = (v: unknown): boolean | null => (v === undefined || v === null ? null : v === 1 || v === true || v === "1");
const text = (v: unknown, max: number): string | null => {
  const s = typeof v === "string" ? v.trim().slice(0, max) : "";
  return s || null;
};

function deviceOf(ua: string): string {
  if (/ipad|tablet/i.test(ua)) return "tablet";
  if (/mobi|iphone|android/i.test(ua)) return "mobile";
  return "desktop";
}

async function hashIp(ip: string): Promise<string | null> {
  if (!IP_SALT || !ip || ip === "unknown") return null;
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(IP_SALT + ip));
  return Array.from(new Uint8Array(buf)).slice(0, 16).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function overLimit(ipHash: string | null): Promise<boolean> {
  if (!ipHash) return false;
  const since = new Date(Date.now() - RATE_LIMIT.windowMs).toISOString();
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/video_events?select=id&ip_hash=eq.${ipHash}&created_at=gte.${encodeURIComponent(since)}`,
      { headers: { apikey: SERVICE_KEY, authorization: `Bearer ${SERVICE_KEY}`, Prefer: "count=exact", Range: "0-0" } },
    );
    const total = res.headers.get("content-range")?.split("/")[1];
    await res.body?.cancel();
    return !!total && total !== "*" && Number(total) >= RATE_LIMIT.max;
  } catch {
    return false;
  }
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin") ?? "";
  if (req.method === "OPTIONS") return reply(204, origin);
  if (req.method !== "POST") return reply(405, origin);
  if (origin && !ALLOWED_ORIGINS.includes(origin)) return reply(403, origin);
  if (!SUPABASE_URL || !SERVICE_KEY) return reply(500, origin);

  const ua = req.headers.get("user-agent") ?? "";
  if (BOT.test(ua)) return reply(204, origin); // accepted and ignored: no bot rows

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return reply(413, origin);
  let b: Record<string, unknown>;
  try {
    b = JSON.parse(raw);
  } catch {
    return reply(400, origin);
  }

  const event = String(b.event ?? "");
  const visitor = String(b.visitor_id ?? "");
  const session = String(b.session_id ?? "");
  const videoId = String(b.video_id ?? "");
  if (!EVENTS.has(event) || !UUID.test(visitor) || !UUID.test(session) || !VIDEO_ID.test(videoId)) {
    return reply(400, origin);
  }

  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";
  const ipHash = await hashIp(ip);
  if (await overLimit(ipHash)) return reply(429, origin);

  const p = (typeof b.params === "object" && b.params !== null ? b.params : {}) as Record<string, unknown>;
  const utm = typeof b.utm === "object" && b.utm !== null
    ? Object.fromEntries(
      Object.entries(b.utm as Record<string, unknown>).slice(0, 5).map(([k, v]) => [k.slice(0, 20), String(v).slice(0, 100)]),
    )
    : null;

  const row = {
    event,
    video_id: videoId,
    visitor_id: visitor,
    session_id: session,
    video_duration: int(p.video_duration, 36000),
    video_percent: int(p.video_percent, 100),
    watched_seconds: int(p.watched_seconds, 36000),
    percent_watched: int(p.percent_watched, 100),
    max_position_seconds: int(p.max_position_seconds, 36000),
    play_count: int(p.play_count, 1000),
    completed: flag(p.completed),
    engagement: text(p.engagement, 20),
    captions_on: flag(p.captions_on),
    muted: flag(p.muted),
    page: text(b.page, 200),
    referrer: text(b.referrer, 300),
    utm,
    screen: text(b.screen, 20),
    device: deviceOf(ua),
    country: text(req.headers.get("cf-ipcountry"), 2),
    ip_hash: ipHash,
    user_agent: ua.slice(0, 300) || null,
  };

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/video_events`, {
      method: "POST",
      headers: {
        apikey: SERVICE_KEY,
        authorization: `Bearer ${SERVICE_KEY}`,
        "content-type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(row),
    });
    if (!res.ok) console.warn(JSON.stringify({ event: "video_insert_failed", status: res.status }));
    await res.body?.cancel();
  } catch (err) {
    console.warn(JSON.stringify({ event: "video_insert_failed", error: String(err) }));
  }
  return reply(204, origin);
});
