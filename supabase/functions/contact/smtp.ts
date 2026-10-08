/**
 * Minimal SMTP client: connect, STARTTLS, AUTH LOGIN, send, quit.
 *
 * Written by hand because denomailer fails with "BadResource: Bad resource ID"
 * when it upgrades the socket on this runtime. This keeps the STARTTLS dance
 * explicit, reports which command failed, and has no dependencies.
 */

export interface SmtpConfig {
  hostname: string;
  port: number;
  username: string;
  password: string;
  /** give up on the whole conversation after this long */
  timeoutMs?: number;
}

export interface InlineImage {
  cid: string;
  filename: string;
  contentType: string;
  base64: string;
}

export interface MailMessage {
  from: string;
  to: string[];
  subject: string;
  text: string;
  html: string;
  replyTo?: string;
  inlineImage?: InlineImage;
}

export class SmtpError extends Error {
  constructor(public stage: string, message: string) {
    super(`${stage}: ${message}`);
    this.name = "SmtpError";
  }
}

const CRLF = "\r\n";
const enc = new TextEncoder();
const dec = new TextDecoder();

/** "Name <a@b.com>" -> "a@b.com" */
export function addressOf(value: string): string {
  const m = value.match(/<([^>]+)>/);
  return (m ? m[1] : value).trim();
}

/** RFC 2047 for non-ASCII headers. */
function encodeHeader(value: string): string {
  // deno-lint-ignore no-control-regex
  return /^[\x00-\x7F]*$/.test(value)
    ? value
    : `=?UTF-8?B?${btoa(String.fromCharCode(...enc.encode(value)))}?=`;
}

function b64Wrap(b64: string, width = 76): string {
  const lines: string[] = [];
  for (let i = 0; i < b64.length; i += width) lines.push(b64.slice(i, i + width));
  return lines.join(CRLF);
}

function b64Utf8(text: string): string {
  return b64Wrap(btoa(String.fromCharCode(...enc.encode(text))));
}

function boundary(tag: string): string {
  return `=_${tag}_${crypto.randomUUID().replace(/-/g, "")}`;
}

export function buildMessage(msg: MailMessage): string {
  const alt = boundary("alt");
  const rel = boundary("rel");
  const headers = [
    `From: ${msg.from}`,
    `To: ${msg.to.join(", ")}`,
    ...(msg.replyTo ? [`Reply-To: ${msg.replyTo}`] : []),
    `Subject: ${encodeHeader(msg.subject)}`,
    `Date: ${new Date().toUTCString()}`,
    `Message-ID: <${crypto.randomUUID()}@bimigrations.com>`,
    "MIME-Version: 1.0",
  ];

  const alternative = [
    `--${alt}`,
    'Content-Type: text/plain; charset="utf-8"',
    "Content-Transfer-Encoding: base64",
    "",
    b64Utf8(msg.text),
    "",
    `--${alt}`,
    'Content-Type: text/html; charset="utf-8"',
    "Content-Transfer-Encoding: base64",
    "",
    b64Utf8(msg.html),
    "",
    `--${alt}--`,
  ].join(CRLF);

  if (!msg.inlineImage) {
    return [
      ...headers,
      `Content-Type: multipart/alternative; boundary="${alt}"`,
      "",
      alternative,
    ].join(CRLF);
  }

  const img = msg.inlineImage;
  return [
    ...headers,
    `Content-Type: multipart/related; boundary="${rel}"`,
    "",
    `--${rel}`,
    `Content-Type: multipart/alternative; boundary="${alt}"`,
    "",
    alternative,
    "",
    `--${rel}`,
    `Content-Type: ${img.contentType}; name="${img.filename}"`,
    "Content-Transfer-Encoding: base64",
    `Content-ID: <${img.cid}>`,
    `Content-Disposition: inline; filename="${img.filename}"`,
    "",
    b64Wrap(img.base64),
    "",
    `--${rel}--`,
  ].join(CRLF);
}

/** Lines starting with "." must be escaped inside DATA. */
function dotStuff(body: string): string {
  return body.split(CRLF).map((l) => (l.startsWith(".") ? "." + l : l)).join(CRLF);
}

class Session {
  private conn: Deno.Conn;
  private buf = "";
  private readonly deadline: number;

  constructor(conn: Deno.Conn, timeoutMs: number) {
    this.conn = conn;
    this.deadline = Date.now() + timeoutMs;
  }

  private remaining(): number {
    const left = this.deadline - Date.now();
    if (left <= 0) throw new SmtpError("timeout", "conversation took too long");
    return left;
  }

  private async withTimeout<T>(p: Promise<T>, stage: string): Promise<T> {
    let timer = 0;
    const guard = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new SmtpError(stage, "timed out")),
        this.remaining(),
      );
    });
    try {
      return await Promise.race([p, guard]);
    } finally {
      clearTimeout(timer);
    }
  }

  async read(stage: string): Promise<{ code: number; text: string }> {
    // a reply ends with "NNN <text>"; continuation lines use "NNN-"
    while (true) {
      const lines = this.buf.split(CRLF);
      const last = lines.filter((l) => l.length > 0).pop();
      if (last && /^\d{3} /.test(last)) {
        const text = this.buf.trim();
        this.buf = "";
        return { code: Number(text.slice(-text.length).match(/(\d{3}) [^\r\n]*$/)?.[1] ?? last.slice(0, 3)), text };
      }
      const chunk = new Uint8Array(4096);
      const n = await this.withTimeout(this.conn.read(chunk), stage);
      if (n === null) throw new SmtpError(stage, "server closed the connection");
      this.buf += dec.decode(chunk.subarray(0, n));
    }
  }

  async write(line: string, stage: string): Promise<void> {
    await this.withTimeout(this.conn.write(enc.encode(line + CRLF)), stage);
  }

  async expect(stage: string, ...codes: number[]): Promise<string> {
    const { code, text } = await this.read(stage);
    if (!codes.includes(code)) throw new SmtpError(stage, `server said ${text.replace(/\s+/g, " ").slice(0, 200)}`);
    return text;
  }

  async command(line: string, stage: string, ...codes: number[]): Promise<string> {
    await this.write(line, stage);
    return await this.expect(stage, ...codes);
  }

  async startTls(hostname: string): Promise<void> {
    await this.command("STARTTLS", "starttls", 220);
    this.conn = await Deno.startTls(this.conn as Deno.TcpConn, { hostname });
  }

  close(): void {
    try {
      this.conn.close();
    } catch { /* already gone */ }
  }
}

export interface SendResult {
  /** one line per step, e.g. "mail-from 250 Ok" — handy when mail vanishes */
  transcript: string[];
}

export async function sendMail(config: SmtpConfig, msg: MailMessage): Promise<SendResult> {
  const { hostname, port, username, password, timeoutMs = 20_000 } = config;
  const conn = await Deno.connect({ hostname, port });
  const session = new Session(conn, timeoutMs);
  const transcript: string[] = [];
  const note = (stage: string, reply: string) =>
    transcript.push(`${stage}: ${reply.replace(/\s+/g, " ").slice(0, 160)}`);

  try {
    note("greeting", await session.expect("greeting", 220));
    await session.command(`EHLO bimigrations.com`, "ehlo", 250);
    await session.startTls(hostname);
    await session.command(`EHLO bimigrations.com`, "ehlo-tls", 250);

    await session.command("AUTH LOGIN", "auth", 334);
    await session.command(btoa(username), "auth-user", 334);
    note("auth", await session.command(btoa(password), "auth-pass", 235));

    note("mail-from", await session.command(`MAIL FROM:<${addressOf(msg.from)}>`, "mail-from", 250));
    for (const rcpt of msg.to) {
      note(`rcpt<${addressOf(rcpt)}>`, await session.command(`RCPT TO:<${addressOf(rcpt)}>`, "rcpt-to", 250, 251));
    }

    await session.command("DATA", "data", 354);
    await session.write(dotStuff(buildMessage(msg)) + CRLF + ".", "data-body");
    note("accepted", await session.expect("data-end", 250));

    try {
      await session.command("QUIT", "quit", 221);
    } catch { /* some servers just drop the connection */ }
    return { transcript };
  } finally {
    session.close();
  }
}
