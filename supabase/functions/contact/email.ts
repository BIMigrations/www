import type { Normalized } from "./validate.ts";

export interface Meta {
  ip: string;
  userAgent: string;
  origin: string;
  receivedAt: string;
}

const esc = (s: string): string =>
  s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string)
  );

export function notificationSubject(d: Normalized): string {
  const who = d.company || d.domain;
  return d.form === "scan"
    ? `Estate scan request — ${who}`
    : `Enquiry — ${d.name}, ${who}`;
}

export function notificationText(d: Normalized, meta: Meta): string {
  const rows: Array<[string, string]> = [
    ["Name", d.name],
    ["Email", d.email],
    ["Company", d.company],
    ["Platform", d.platform],
    ["Interest", d.interest],
    ["Form", d.form],
    ["Page", d.page],
  ];
  const lines = rows.filter(([, v]) => v).map(([k, v]) => `${k}: ${v}`);
  return [
    ...lines,
    "",
    d.message ? `Message:\n${d.message}` : "(no message)",
    "",
    "—",
    `Received: ${meta.receivedAt}`,
    `IP: ${meta.ip}`,
    `Origin: ${meta.origin}`,
    `User agent: ${meta.userAgent}`,
    "",
    "Checked by the contact function: work domain, real name, non-spam message.",
  ].join("\n");
}

export function notificationHtml(d: Normalized, meta: Meta): string {
  const row = (label: string, value: string) =>
    value
      ? `<tr><td style="padding:6px 18px 6px 0;color:#5F6570;font-size:13px;white-space:nowrap;vertical-align:top">${esc(label)}</td>` +
        `<td style="padding:6px 0;color:#0A0C10;font-size:14px;font-weight:600">${esc(value)}</td></tr>`
      : "";

  return `<div style="font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;background:#F1EEE6;padding:28px">
  <div style="max-width:620px;margin:0 auto;background:#fff;border:1px solid #E9E5DB;border-radius:16px;padding:28px">
    <div style="font-size:11px;font-weight:700;letter-spacing:1.6px;text-transform:uppercase;color:#0B7F6B">
      ${d.form === "scan" ? "Estate scan request" : "New enquiry"}
    </div>
    <div style="font-size:22px;font-weight:700;letter-spacing:-0.3px;color:#0A0C10;padding:6px 0 18px">
      ${esc(d.name || d.email)}
    </div>
    <table cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;width:100%">
      ${row("Email", d.email)}
      ${row("Company", d.company)}
      ${row("Platform", d.platform)}
      ${row("Interest", d.interest)}
      ${row("Page", d.page)}
    </table>
    ${
    d.message
      ? `<div style="margin-top:18px;padding-top:18px;border-top:1px solid #E9E5DB">
           <div style="font-size:11px;font-weight:700;letter-spacing:1.4px;text-transform:uppercase;color:#5F6570;padding-bottom:8px">Message</div>
           <div style="font-size:14px;line-height:1.65;color:#3A3D44;white-space:pre-wrap">${esc(d.message)}</div>
         </div>`
      : ""
  }
    <div style="margin-top:20px;padding-top:14px;border-top:1px solid #E9E5DB;font-size:11px;line-height:1.7;color:#8A8A8A">
      ${esc(meta.receivedAt)} &nbsp;·&nbsp; ${esc(meta.ip)} &nbsp;·&nbsp; ${esc(meta.origin)}<br>
      ${esc(meta.userAgent.slice(0, 160))}
    </div>
  </div>
</div>`;
}

export function autoReplySubject(): string {
  return "Thanks — we've got your enquiry";
}

export function autoReplyText(d: Normalized): string {
  const hi = d.firstName ? `Hi ${d.firstName},` : "Hi,";
  return [
    hi,
    "",
    "Thanks for getting in touch with BI Migrations. Your enquiry has reached us and a real person will reply, usually within one working day.",
    "",
    "If it helps in the meantime:",
    "· How a migration works: https://bimigrations.com/#method",
    "· What a free estate scan involves: https://bimigrations.com/services/estate-assessment/",
    "· Common questions: https://bimigrations.com/faqs/",
    "",
    "Just reply to this email if you want to add anything.",
    "",
    "— BI Migrations",
    "https://bimigrations.com",
  ].join("\n");
}

export function autoReplyHtml(d: Normalized): string {
  const hi = d.firstName ? `Hi ${esc(d.firstName)},` : "Hi,";
  return `<div style="font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;background:#F1EEE6;padding:32px">
  <div style="max-width:560px;margin:0 auto;background:#fff;border:1px solid #E9E5DB;border-radius:16px;padding:32px">
    <p style="margin:0 0 24px;font-size:13px;font-weight:700;letter-spacing:1.4px;text-transform:uppercase;color:#0A0C10">
      BI <span style="color:#9A9A9A;font-weight:400">/</span> Migrations
    </p>
    <p style="margin:0 0 16px;font-size:22px;font-weight:700;letter-spacing:-0.3px;color:#0A0C10">${hi}</p>
    <p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#3A3D44">
      Thanks for getting in touch. Your enquiry has reached us, and a real person will reply, usually within one working day.
    </p>
    <p style="margin:0 0 8px;font-size:15px;line-height:1.6;color:#3A3D44">In the meantime:</p>
    <p style="margin:0 0 20px;font-size:15px;line-height:1.9;color:#3A3D44">
      <a href="https://bimigrations.com/#method" style="color:#0B7F6B">How a migration works</a><br>
      <a href="https://bimigrations.com/services/estate-assessment/" style="color:#0B7F6B">What a free estate scan involves</a><br>
      <a href="https://bimigrations.com/faqs/" style="color:#0B7F6B">Common questions</a>
    </p>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#3A3D44">Just reply to this email if you want to add anything.</p>
    <p style="margin:24px 0 0;padding-top:16px;border-top:1px solid #E9E5DB;font-size:13px;color:#6F7278">
      BI Migrations, LLC · <a href="https://bimigrations.com" style="color:#0B7F6B">bimigrations.com</a>
    </p>
  </div>
</div>`;
}
