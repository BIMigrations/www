import type { Normalized } from "./validate.ts";
import { LOGO_CID } from "./logo.ts";

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
    : `Inquiry — ${d.name}, ${who}`;
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
      ${d.form === "scan" ? "Estate scan request" : "New inquiry"}
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
  return "Thanks — we've got your inquiry";
}

export function autoReplyText(d: Normalized): string {
  const hi = d.firstName ? `Hi ${d.firstName},` : "Hi,";
  return [
    hi,
    "",
    "Thanks for getting in touch with BI Migrations. Your inquiry has reached us, and a real person will reply, usually within one working day.",
    "",
    "What happens next:",
    "1. We reply to set up a short call about your estate and goals.",
    "2. You send a read-only metadata export. We'll send instructions for your platform.",
    "3. We return the scan: your inventory, what's still used, and what we'd retire.",
    "",
    "No platform access required. Mutual NDA as standard.",
    "",
    "In the meantime:",
    "· How a migration works: https://bimigrations.com/#method",
    "· What a free estate scan involves: https://bimigrations.com/services/estate-assessment/",
    "· Common questions: https://bimigrations.com/faqs/",
    "",
    "Just reply to this email if you want to add anything.",
    "",
    "BI Migrations, LLC",
    "https://bimigrations.com",
  ].join("\n");
}

export function autoReplyHtml(d: Normalized): string {
  const hi = d.firstName ? `Hi ${esc(d.firstName)},` : "Hi,";
  const step = (n: string, text: string) =>
    `<tr>
      <td style="padding:0 14px 14px 0;vertical-align:top;width:26px">
        <div style="font-size:12px;font-weight:700;letter-spacing:1px;color:#0B7F6B;line-height:1.5">${n}</div>
      </td>
      <td style="padding:0 0 14px 0;vertical-align:top;font-size:14px;line-height:1.6;color:#3A3D44">${text}</td>
    </tr>`;

  return `<div style="margin:0;padding:32px 16px;background-color:#F1EEE6;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">
  <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" width="560" style="border-collapse:collapse;width:560px;max-width:100%;margin:0 auto">
    <tr>
      <td style="background-color:#FFFFFF;border:1px solid #E9E5DB;border-radius:16px;padding:34px 36px">

        <img src="cid:${LOGO_CID}" width="180" height="36" alt="BI Migrations"
             style="display:block;width:180px;height:36px;border:0;outline:none;text-decoration:none">

        <div style="height:1px;background-color:#E9E5DB;margin:24px 0 26px;font-size:0;line-height:0">&nbsp;</div>

        <h1 style="margin:0 0 14px;font-size:26px;line-height:1.2;font-weight:700;letter-spacing:-0.5px;color:#0A0C10">${hi}</h1>

        <p style="margin:0 0 22px;font-size:15px;line-height:1.65;color:#3A3D44">
          Thanks for getting in touch. Your inquiry has reached us, and a real person will reply &mdash; usually within one working day.
        </p>

        <div style="background-color:#F7F5F0;border-radius:12px;padding:20px 22px 8px;margin:0 0 22px">
          <div style="font-size:11px;font-weight:700;letter-spacing:1.4px;text-transform:uppercase;color:#5F6570;padding-bottom:14px">What happens next</div>
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;width:100%">
            ${step("01", "<strong style=\"color:#0A0C10\">We reply</strong> to set up a short call about your estate and goals.")}
            ${step("02", "<strong style=\"color:#0A0C10\">You send a read-only metadata export.</strong> We'll send instructions for your platform.")}
            ${step("03", "<strong style=\"color:#0A0C10\">We return the scan</strong>: your inventory, what's still used, and what we'd retire.")}
          </table>
          <div style="font-size:12px;line-height:1.6;color:#6F7278;padding:4px 0 14px">No platform access required. Mutual NDA as standard.</div>
        </div>

        <p style="margin:0 0 10px;font-size:15px;line-height:1.65;color:#3A3D44">While you wait:</p>
        <p style="margin:0 0 24px;font-size:15px;line-height:2;color:#3A3D44">
          <a href="https://bimigrations.com/#method" style="color:#0B7F6B;text-decoration:none">How a migration works &rarr;</a><br>
          <a href="https://bimigrations.com/services/estate-assessment/" style="color:#0B7F6B;text-decoration:none">What a free estate scan involves &rarr;</a><br>
          <a href="https://bimigrations.com/faqs/" style="color:#0B7F6B;text-decoration:none">Common questions &rarr;</a>
        </p>

        <p style="margin:0;font-size:15px;line-height:1.65;color:#3A3D44">
          Just reply to this email if you want to add anything.
        </p>

        <div style="margin-top:26px;padding-top:18px;border-top:1px solid #E9E5DB;font-size:12px;line-height:1.7;color:#8A8A8A">
          BI Migrations, LLC &nbsp;·&nbsp; <a href="https://bimigrations.com" style="color:#0B7F6B;text-decoration:none">bimigrations.com</a><br>
          Automating migrations from BI platforms and data warehouses
        </div>

      </td>
    </tr>
  </table>
</div>`;
}
