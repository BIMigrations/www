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
  subject: 'Thanks — we’ve got your enquiry',
  siteUrl: 'https://bimigrations.com',
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
      htmlBody: htmlBody(firstName, answers)
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
    'Thanks for getting in touch with BI Migrations. Your enquiry has reached us and a real person will reply — usually within one working day.',
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

function htmlBody(firstName, answers) {
  var ink = '#0A0C10', ink2 = '#3A3D44', teal = '#0B7F6B', line = '#E3DFD5', cream = '#F1EEE6';
  var rows = summaryRows(answers).map(function (row) {
    return '<tr>' +
      '<td style="padding:6px 16px 6px 0;color:' + ink2 + ';font-size:14px;white-space:nowrap">' + escapeHtml(row[0]) + '</td>' +
      '<td style="padding:6px 0;color:' + ink + ';font-size:14px;font-weight:600">' + escapeHtml(row[1]) + '</td>' +
      '</tr>';
  }).join('');

  return '' +
  '<div style="background:' + cream + ';padding:32px 0;font-family:Helvetica,Arial,sans-serif">' +
    '<div style="max-width:560px;margin:0 auto;background:#fff;border:1px solid ' + line + ';border-radius:16px;padding:32px">' +
      '<p style="margin:0 0 24px;font-size:13px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:' + ink + '">' +
        'BI <span style="color:#9A9A9A;font-weight:400">/</span> Migrations</p>' +
      '<p style="margin:0 0 16px;font-size:22px;font-weight:700;letter-spacing:-0.02em;color:' + ink + '">' + escapeHtml(greeting(firstName)) + '</p>' +
      '<p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:' + ink2 + '">Thanks for getting in touch. Your enquiry has reached us, and a real person will reply — usually within one working day.</p>' +
      (rows ? '<table style="margin:0 0 20px;border-collapse:collapse">' + rows + '</table>' : '') +
      '<p style="margin:0 0 8px;font-size:15px;line-height:1.6;color:' + ink2 + '">In the meantime:</p>' +
      '<p style="margin:0 0 20px;font-size:15px;line-height:1.9;color:' + ink2 + '">' +
        '<a href="' + CONFIG.siteUrl + '/#method" style="color:' + teal + '">How a migration works</a><br>' +
        '<a href="' + CONFIG.siteUrl + '/services/estate-assessment/" style="color:' + teal + '">What a free estate scan involves</a><br>' +
        '<a href="' + CONFIG.siteUrl + '/faqs/" style="color:' + teal + '">Common questions</a></p>' +
      '<p style="margin:0;font-size:15px;line-height:1.6;color:' + ink2 + '">Just reply to this email if you want to add anything.</p>' +
      '<p style="margin:24px 0 0;padding-top:16px;border-top:1px solid ' + line + ';font-size:13px;color:#6F7278">' +
        'BI Migrations, LLC · <a href="' + CONFIG.siteUrl + '" style="color:' + teal + '">bimigrations.com</a></p>' +
    '</div>' +
  '</div>';
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, function (c) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
  });
}
