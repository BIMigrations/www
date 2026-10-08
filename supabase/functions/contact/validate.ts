/**
 * Submission validation for the BI Migrations contact endpoint.
 *
 * Pure functions, no I/O, so they can be unit tested (see validate_test.ts).
 * Rules are deliberately strict: this endpoint exists because the old form
 * collected too much junk.
 */

export type FormKind = "contact" | "scan";

export interface Submission {
  form?: FormKind;
  name?: string;
  email?: string;
  company?: string;
  platform?: string;
  interest?: string;
  message?: string;
  /** honeypot — must stay empty */
  website?: string;
  /** ms since epoch when the form was rendered, for the time trap */
  renderedAt?: number | string;
  page?: string;
}

export interface Normalized {
  form: FormKind;
  name: string;
  firstName: string;
  lastName: string;
  email: string;
  domain: string;
  company: string;
  platform: string;
  interest: string;
  message: string;
  page: string;
}

export interface ValidationResult {
  ok: boolean;
  /** shown to the person filling the form */
  errors: string[];
  /** logged for us, never returned to the browser */
  reasons: string[];
  data?: Normalized;
}

/** Free/consumer mailbox providers. Enquiries must come from a work domain. */
export const PUBLIC_EMAIL_DOMAINS = new Set([
  "gmail.com", "googlemail.com", "yahoo.com", "yahoo.co.uk", "yahoo.co.in", "yahoo.fr",
  "yahoo.de", "ymail.com", "rocketmail.com", "hotmail.com", "hotmail.co.uk", "hotmail.fr",
  "outlook.com", "outlook.in", "live.com", "live.co.uk", "msn.com", "passport.com",
  "aol.com", "aim.com", "icloud.com", "me.com", "mac.com", "proton.me", "protonmail.com",
  "pm.me", "gmx.com", "gmx.de", "gmx.net", "web.de", "mail.com", "email.com", "usa.com",
  "zoho.com", "zohomail.com", "yandex.com", "yandex.ru", "ya.ru", "mail.ru", "bk.ru",
  "inbox.ru", "list.ru", "qq.com", "163.com", "126.com", "sina.com", "sohu.com",
  "naver.com", "daum.net", "hanmail.net", "rediffmail.com", "sify.com", "indiatimes.com",
  "fastmail.com", "fastmail.fm", "hushmail.com", "tutanota.com", "tuta.io", "mailfence.com",
  "comcast.net", "verizon.net", "att.net", "sbcglobal.net", "bellsouth.net", "cox.net",
  "btinternet.com", "sky.com", "virginmedia.com", "talktalk.net", "ntlworld.com",
  "blueyonder.co.uk", "orange.fr", "wanadoo.fr", "free.fr", "laposte.net", "libero.it",
  "virgilio.it", "tiscali.it", "t-online.de", "freenet.de", "bluewin.ch", "telenet.be",
  "ziggo.nl", "xs4all.nl", "optonline.net", "earthlink.net", "juno.com", "netzero.net",
]);

/** Throwaway inbox providers. */
export const DISPOSABLE_EMAIL_DOMAINS = new Set([
  "mailinator.com", "guerrillamail.com", "guerrillamail.info", "sharklasers.com",
  "10minutemail.com", "tempmail.com", "temp-mail.org", "throwawaymail.com", "yopmail.com",
  "trashmail.com", "getnada.com", "dispostable.com", "maildrop.cc", "mintemail.com",
  "fakeinbox.com", "spamgourmet.com", "mytemp.email", "moakt.com", "emailondeck.com",
  "burnermail.io", "33mail.com", "tempr.email", "mohmal.com", "anonaddy.me", "simplelogin.com",
]);

const SPAM_PHRASES = [
  "seo service", "seo services", "search engine optimi", "backlink", "link building",
  "guest post", "domain authority", "first page of google", "rank your website",
  "web design service", "app development service", "hire developers", "dedicated developers",
  "crypto", "bitcoin", "forex", "casino", "betting", "loan offer", "investment opportunity",
  "make money", "work from home", "viagra", "pharmacy", "escort", "adult traffic",
  "increase your sales", "lead generation service", "buy leads", "email list", "database of",
  "telegram me", "whatsapp me", "click here now", "limited time offer", "act now",
];

const URL_RE = /\b(?:https?:\/\/|www\.)\S+|\b[a-z0-9-]+\.(?:com|net|org|io|ru|cn|xyz|top|info|biz|online|site|shop)\b/gi;
const EMAIL_RE = /^[^\s@,;:<>()[\]\\"]+@[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$/i;
const NAME_TOKEN_RE = /^\p{L}[\p{L}'’.\-]*$/u;
const VOWELS = /[aeiouyàáâãäåèéêëìíîïòóôõöùúûüýÿœæ]/i;

const PLATFORMS = new Set([
  "", "domo", "power bi", "looker", "qlik sense", "qlikview", "tableau",
  "microstrategy", "cognos", "sigma", "superset", "several / other", "other",
]);

const INTERESTS = new Set([
  "", "a free estate scan", "an estate assessment", "a full migration",
  "rationalization", "partnership", "careers", "something else",
  "free estate scan (home page)",
]);

const clean = (v: unknown): string =>
  typeof v === "string" ? v.replace(/\s+/g, " ").trim() : "";

/** 4+ of the same character in a row, e.g. "aaaa" or "!!!!". */
const hasRun = (s: string, len = 4): boolean =>
  new RegExp(`(.)\\1{${len - 1},}`, "u").test(s);

/** A long letter run with no vowel at all reads as keyboard mash. */
const looksMashed = (token: string): boolean => {
  const letters = token.replace(/[^\p{L}]/gu, "");
  return letters.length >= 6 && !VOWELS.test(letters);
};

function validateName(raw: string, reasons: string[], errors: string[]): [string, string] {
  const name = clean(raw);
  if (!name) {
    errors.push("Please give your first and last name.");
    reasons.push("name:empty");
    return ["", ""];
  }
  if (name.length > 80) {
    errors.push("That name looks too long.");
    reasons.push("name:too-long");
    return ["", ""];
  }
  if (/\d/.test(name)) {
    errors.push("Names shouldn't contain numbers.");
    reasons.push("name:digits");
    return ["", ""];
  }
  if (URL_RE.test(name)) {
    URL_RE.lastIndex = 0;
    errors.push("Please give your real name.");
    reasons.push("name:url");
    return ["", ""];
  }
  URL_RE.lastIndex = 0;

  const tokens = name.split(" ").filter(Boolean);
  if (tokens.length < 2) {
    errors.push("Please give both your first and last name.");
    reasons.push("name:single-token");
    return ["", ""];
  }
  for (const token of tokens) {
    if (!NAME_TOKEN_RE.test(token)) {
      errors.push("Please give your real name.");
      reasons.push(`name:charset:${token.slice(0, 12)}`);
      return ["", ""];
    }
    // allow initials like "J." but nothing else shorter than two letters
    if (token.replace(/[.'’-]/g, "").length < 2 && !/\.$/.test(token)) {
      errors.push("Please give your full first and last name.");
      reasons.push(`name:short-token:${token}`);
      return ["", ""];
    }
    if (hasRun(token) || looksMashed(token)) {
      errors.push("Please give your real name.");
      reasons.push(`name:mashed:${token.slice(0, 12)}`);
      return ["", ""];
    }
  }
  return [tokens[0], tokens.slice(1).join(" ")];
}

function validateEmail(
  raw: string,
  reasons: string[],
  errors: string[],
  allowPublic: boolean,
): string {
  const email = clean(raw).toLowerCase();
  if (!email) {
    errors.push("Please give your work email address.");
    reasons.push("email:empty");
    return "";
  }
  if (email.length > 254 || !EMAIL_RE.test(email)) {
    errors.push("That email address doesn't look right.");
    reasons.push("email:format");
    return "";
  }
  const domain = email.slice(email.lastIndexOf("@") + 1);
  if (DISPOSABLE_EMAIL_DOMAINS.has(domain)) {
    errors.push("Please use your work email address.");
    reasons.push(`email:disposable:${domain}`);
    return "";
  }
  if (!allowPublic && PUBLIC_EMAIL_DOMAINS.has(domain)) {
    errors.push(
      "Please use your work email address rather than a personal one, so we can see which organization you're with.",
    );
    reasons.push(`email:public:${domain}`);
    return "";
  }
  return domain;
}

function validateMessage(raw: string, required: boolean, reasons: string[], errors: string[]): string {
  const message = typeof raw === "string" ? raw.trim() : "";
  if (!message) {
    if (required) {
      errors.push("Please tell us a little about what you need.");
      reasons.push("message:empty");
    }
    return "";
  }
  if (required && message.length < 20) {
    errors.push("Please give us a bit more detail, so we can reply usefully.");
    reasons.push("message:too-short");
    return "";
  }
  if (message.length > 5000) {
    errors.push("That message is too long. Please shorten it.");
    reasons.push("message:too-long");
    return "";
  }

  const urls = message.match(URL_RE) ?? [];
  URL_RE.lastIndex = 0;
  if (urls.length > 2) {
    errors.push("Please remove the links from your message.");
    reasons.push(`message:links:${urls.length}`);
    return "";
  }

  const lower = message.toLowerCase();
  const hit = SPAM_PHRASES.find((phrase) => lower.includes(phrase));
  if (hit) {
    errors.push("That message looks like marketing. If it isn't, email us directly.");
    reasons.push(`message:phrase:${hit}`);
    return "";
  }

  const letters = message.replace(/[^\p{L}]/gu, "").length;
  if (letters < message.length * 0.4) {
    errors.push("That message doesn't look like a sentence.");
    reasons.push("message:low-letter-ratio");
    return "";
  }
  const upper = message.replace(/[^A-Z]/g, "").length;
  if (message.length > 40 && upper > letters * 0.6) {
    errors.push("Please don't write in capitals.");
    reasons.push("message:shouting");
    return "";
  }
  if (hasRun(message, 6)) {
    errors.push("That message doesn't look like a sentence.");
    reasons.push("message:char-run");
    return "";
  }
  const words = message.split(/\s+/).filter(Boolean);
  if (words.length >= 6 && words.every((w) => looksMashed(w))) {
    errors.push("That message doesn't look like a sentence.");
    reasons.push("message:mashed");
    return "";
  }
  return message;
}

export interface ValidateOptions {
  /** seconds a human needs to fill the form; submissions faster than this are bots */
  minFillSeconds?: number;
  /** allow consumer mailboxes — only for testing */
  allowPublicDomains?: boolean;
  now?: number;
}

export function validate(input: Submission, opts: ValidateOptions = {}): ValidationResult {
  const {
    minFillSeconds = 3,
    allowPublicDomains = false,
    now = Date.now(),
  } = opts;

  const errors: string[] = [];
  const reasons: string[] = [];

  // Honeypot: real people never see this field.
  if (clean(input.website)) {
    reasons.push("honeypot");
    return { ok: false, errors: ["Something went wrong. Please try again."], reasons };
  }

  // Time trap: a bot posts instantly.
  const renderedAt = Number(input.renderedAt ?? 0);
  if (renderedAt > 0) {
    const elapsed = (now - renderedAt) / 1000;
    if (elapsed < minFillSeconds) {
      reasons.push(`too-fast:${elapsed.toFixed(1)}s`);
      return { ok: false, errors: ["Something went wrong. Please try again."], reasons };
    }
    if (elapsed > 60 * 60 * 24) {
      errors.push("This page was open a while. Please reload and try again.");
      reasons.push("stale-form");
    }
  }

  const form: FormKind = input.form === "scan" ? "scan" : "contact";
  const email = clean(input.email).toLowerCase();
  const domain = validateEmail(email, reasons, errors, allowPublicDomains);

  let firstName = "";
  let lastName = "";
  if (form === "contact") {
    [firstName, lastName] = validateName(input.name ?? "", reasons, errors);
  }

  const company = clean(input.company);
  if (company) {
    if (company.length > 100 || hasRun(company) || looksMashed(company)) {
      errors.push("That company name doesn't look right.");
      reasons.push("company:junk");
    }
  }

  const platform = clean(input.platform).toLowerCase();
  if (platform && !PLATFORMS.has(platform)) {
    reasons.push(`platform:unknown:${platform.slice(0, 24)}`);
  }
  const interest = clean(input.interest).toLowerCase();
  if (interest && !INTERESTS.has(interest)) {
    reasons.push(`interest:unknown:${interest.slice(0, 24)}`);
  }

  const message = validateMessage(input.message ?? "", form === "contact", reasons, errors);

  if (errors.length > 0) return { ok: false, errors, reasons };

  return {
    ok: true,
    errors: [],
    reasons,
    data: {
      form,
      name: form === "contact" ? `${firstName} ${lastName}`.trim() : "",
      firstName,
      lastName,
      email,
      domain,
      company,
      platform: clean(input.platform),
      interest: clean(input.interest),
      message,
      page: clean(input.page).slice(0, 200),
    },
  };
}
