/**
 * Postgres-backed rate limiting and submission log, over PostgREST.
 *
 * Edge isolates don't share memory, so an in-process counter barely limits
 * anything. This keeps the count in the database instead. Every call fails
 * soft: if the database is unreachable we still deliver the mail.
 */
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TABLE = "contact_submissions";

export const storeEnabled = (): boolean => Boolean(SUPABASE_URL && SERVICE_KEY);

const headers = () => ({
  "apikey": SERVICE_KEY,
  "authorization": `Bearer ${SERVICE_KEY}`,
  "content-type": "application/json",
});

export interface SubmissionRow {
  ip: string;
  status: "accepted" | "rejected";
  reasons: string[];
  email?: string;
  domain?: string;
  name?: string;
  company?: string;
  platform?: string;
  interest?: string;
  message?: string;
  page?: string;
  user_agent?: string;
  form?: string;
}

/** How many submissions this IP made inside the window; null if unavailable. */
export async function recentCount(ip: string, windowMs: number): Promise<number | null> {
  if (!storeEnabled() || ip === "unknown") return null;
  const since = new Date(Date.now() - windowMs).toISOString();
  const url = `${SUPABASE_URL}/rest/v1/${TABLE}` +
    `?select=id&ip=eq.${encodeURIComponent(ip)}&created_at=gte.${encodeURIComponent(since)}`;
  try {
    const res = await fetch(url, {
      headers: { ...headers(), Prefer: "count=exact", Range: "0-0" },
    });
    if (!res.ok) return null;
    // content-range looks like "0-0/12"
    const total = res.headers.get("content-range")?.split("/")[1];
    await res.body?.cancel();
    return total && total !== "*" ? Number(total) : null;
  } catch {
    return null;
  }
}

export async function logSubmission(row: SubmissionRow): Promise<void> {
  if (!storeEnabled()) return;
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${TABLE}`, {
      method: "POST",
      headers: { ...headers(), Prefer: "return=minimal" },
      body: JSON.stringify({ ...row, message: row.message?.slice(0, 5000) }),
    });
    if (!res.ok) {
      console.warn(JSON.stringify({ event: "log_failed", status: res.status }));
    }
    await res.body?.cancel();
  } catch (err) {
    console.warn(JSON.stringify({ event: "log_failed", error: String(err) }));
  }
}
