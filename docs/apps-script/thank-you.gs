/**
 * BI Migrations — auto-reply to people who submit the website contact form.
 *
 * Setup (about 3 minutes):
 *   1. Open the Google Form → ⋮ (top right) → "Script editor".
 *   2. Replace the placeholder code with this file, and edit CONFIG below.
 *   3. Save, then in the left sidebar: Triggers → Add trigger
 *        function: onFormSubmit · source: From form · type: On form submit
 *   4. Authorise when prompted (it needs permission to send mail as you).
 *
 * The reply is sent from the Google account that owns the script. To send from
 * an alias such as hello@bimigrations.com, first add it in Gmail under
 * Settings → Accounts → "Send mail as", then set CONFIG.fromAlias to it.
 */

var CONFIG = {
  fromName: 'BI Migrations',
  fromAlias: '',                  // e.g. 'hello@bimigrations.com' (must be a verified Gmail alias)
  replyTo: '',                    // where replies should land; blank = the script owner's address
  subject: 'Thanks — we’ve got your inquiry',
  siteUrl: 'https://bimigrations.com',
  logoUrl: 'https://bimigrations.com/brand-assets/email-signature/logo-email.png',
  internalCopy: '',               // optional: also BCC this address on every auto-reply

  // Question titles on the form. Update these if you rename a question.
  questions: {
    email: 'Email Address',
    name: 'Full Name',
    company: 'Company',
    platform: 'Current BI Platform',
    interest: 'What are you looking for?'
  }
};

function onFormSubmit(e) {
  try {
    var answers = readAnswers(e);
    var email = (answers[CONFIG.questions.email] || '').trim();

    if (!isEmail(email)) {
      console.warn('No usable email address in this response; skipping auto-reply.');
      return;
    }

    var firstName = (answers[CONFIG.questions.name] || '').trim().split(/\s+/)[0];
    var options = {
      name: CONFIG.fromName,
      htmlBody: htmlBody(firstName, answers),
      inlineImages: logoImage()
    };
    if (CONFIG.fromAlias) options.from = CONFIG.fromAlias;
    if (CONFIG.replyTo) options.replyTo = CONFIG.replyTo;
    if (CONFIG.internalCopy) options.bcc = CONFIG.internalCopy;

    GmailApp.sendEmail(email, CONFIG.subject, textBody(firstName, answers), options);
    console.log('Auto-reply sent to ' + email);
  } catch (err) {
    console.error('Auto-reply failed: ' + err);
  }
}

/** Question title -> answer, for this submission. */
function readAnswers(e) {
  var out = {};
  if (!e || !e.response) throw new Error('No form response — run this from the trigger, not the editor.');
  e.response.getItemResponses().forEach(function (item) {
    out[item.getItem().getTitle()] = String(item.getResponse() || '');
  });
  return out;
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function greeting(firstName) {
  return firstName ? 'Hi ' + firstName + ',' : 'Hi,';
}

/** Lines summarising what they sent, so they have a record of it. */
function summaryRows(answers) {
  var q = CONFIG.questions;
  return [
    ['Company', answers[q.company]],
    ['Current BI platform', answers[q.platform]],
    ['What you asked about', answers[q.interest]]
  ].filter(function (row) { return row[1] && row[1].trim(); });
}

function textBody(firstName, answers) {
  var lines = [
    greeting(firstName),
    '',
    'Thanks for getting in touch with BI Migrations. Your inquiry has reached us, and a real person will reply, usually within one working day.',
    '',
    'If it helps in the meantime:',
    '· How a migration works: ' + CONFIG.siteUrl + '/#method',
    '· What a free estate scan involves: ' + CONFIG.siteUrl + '/services/estate-assessment/',
    '· Common questions: ' + CONFIG.siteUrl + '/faqs/',
    ''
  ];

  var rows = summaryRows(answers);
  if (rows.length) {
    lines.push('What you sent us:');
    rows.forEach(function (row) { lines.push('· ' + row[0] + ': ' + row[1]); });
    lines.push('');
  }

  lines.push('Just reply to this email if you want to add anything.', '', '— BI Migrations', CONFIG.siteUrl);
  return lines.join('\n');
}

/** The lockup, fetched once per run and attached inline so nothing is downloaded. */
function logoImage() {
  try {
    return { logo: UrlFetchApp.fetch(CONFIG.logoUrl).getBlob().setName('bimigrations.png') };
  } catch (err) {
    console.warn('Could not fetch the logo, sending without it: ' + err);
    return {};
  }
}

function htmlBody(firstName, answers) {
  var rows = summaryRows(answers).map(function (row) {
    return '<tr>' +
      '<td style="padding:4px 16px 4px 0;color:#5F6570;font-size:13px;white-space:nowrap;vertical-align:top">' + escapeHtml(row[0]) + '</td>' +
      '<td style="padding:4px 0;color:#0A0C10;font-size:14px;font-weight:600">' + escapeHtml(row[1]) + '</td>' +
      '</tr>';
  }).join('');

  var step = function (n, text) {
    return '<tr>' +
      '<td style="padding:0 14px 14px 0;vertical-align:top;width:26px"><div style="font-size:12px;font-weight:700;letter-spacing:1px;color:#0B7F6B;line-height:1.5">' + n + '</div></td>' +
      '<td style="padding:0 0 14px 0;vertical-align:top;font-size:14px;line-height:1.6;color:#3A3D44">' + text + '</td>' +
      '</tr>';
  };

  return '' +
  '<div style="margin:0;padding:32px 16px;background-color:#F1EEE6;font-family:\'Helvetica Neue\',Helvetica,Arial,sans-serif">' +
    '<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" width="560" style="border-collapse:collapse;width:560px;max-width:100%;margin:0 auto"><tr>' +
    '<td style="background-color:#FFFFFF;border:1px solid #E9E5DB;border-radius:16px;padding:34px 36px">' +
      '<img src="cid:logo" width="180" height="36" alt="BI Migrations" style="display:block;width:180px;height:36px;border:0;outline:none;text-decoration:none">' +
      '<div style="height:1px;background-color:#E9E5DB;margin:24px 0 26px;font-size:0;line-height:0">&nbsp;</div>' +
      '<h1 style="margin:0 0 14px;font-size:26px;line-height:1.2;font-weight:700;letter-spacing:-0.5px;color:#0A0C10">' + escapeHtml(greeting(firstName)) + '</h1>' +
      '<p style="margin:0 0 22px;font-size:15px;line-height:1.65;color:#3A3D44">Thanks for getting in touch. Your inquiry has reached us, and a real person will reply &mdash; usually within one working day.</p>' +
      (rows ? '<table style="margin:0 0 22px;border-collapse:collapse">' + rows + '</table>' : '') +
      '<div style="background-color:#F7F5F0;border-radius:12px;padding:20px 22px 8px;margin:0 0 22px">' +
        '<div style="font-size:11px;font-weight:700;letter-spacing:1.4px;text-transform:uppercase;color:#5F6570;padding-bottom:14px">What happens next</div>' +
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;width:100%">' +
          step('01', '<strong style="color:#0A0C10">We reply</strong> to set up a short call about your estate and goals.') +
          step('02', '<strong style="color:#0A0C10">You send a read-only metadata export.</strong> We\'ll send instructions for your platform.') +
          step('03', '<strong style="color:#0A0C10">We return the scan</strong>: your inventory, what\'s still used, and what we\'d retire.') +
        '</table>' +
        '<div style="font-size:12px;line-height:1.6;color:#6F7278;padding:4px 0 14px">No platform access required. Mutual NDA as standard.</div>' +
      '</div>' +
      '<p style="margin:0 0 10px;font-size:15px;line-height:1.65;color:#3A3D44">While you wait:</p>' +
      '<p style="margin:0 0 24px;font-size:15px;line-height:2;color:#3A3D44">' +
        '<a href="' + CONFIG.siteUrl + '/#method" style="color:#0B7F6B;text-decoration:none">How a migration works &rarr;</a><br>' +
        '<a href="' + CONFIG.siteUrl + '/services/estate-assessment/" style="color:#0B7F6B;text-decoration:none">What a free estate scan involves &rarr;</a><br>' +
        '<a href="' + CONFIG.siteUrl + '/faqs/" style="color:#0B7F6B;text-decoration:none">Common questions &rarr;</a>' +
      '</p>' +
      '<p style="margin:0;font-size:15px;line-height:1.65;color:#3A3D44">Just reply to this email if you want to add anything.</p>' +
      '<div style="margin-top:26px;padding-top:18px;border-top:1px solid #E9E5DB;font-size:12px;line-height:1.7;color:#8A8A8A">' +
        'BI Migrations, LLC &nbsp;·&nbsp; <a href="' + CONFIG.siteUrl + '" style="color:#0B7F6B;text-decoration:none">bimigrations.com</a><br>' +
        'Automating migrations from BI platforms and data warehouses' +
      '</div>' +
    '</td></tr></table>' +
  '</div>';
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, function (c) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
  });
}
