// deno test supabase/functions/contact/validate_test.ts
import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validate, type Submission } from "./validate.ts";

const good: Submission = {
  form: "contact",
  name: "Jane Okafor",
  email: "jane.okafor@acme-analytics.com",
  company: "Acme Analytics",
  platform: "Tableau",
  interest: "A full migration",
  message: "We run about 400 Tableau workbooks and are scoping a move to Power BI next quarter.",
};

const reasonsOf = (s: Submission) => validate(s).reasons.join(",");

Deno.test("accepts a well-formed enquiry", () => {
  const r = validate(good);
  assertEquals(r.ok, true);
  assertEquals(r.data?.firstName, "Jane");
  assertEquals(r.data?.lastName, "Okafor");
  assertEquals(r.data?.domain, "acme-analytics.com");
});

Deno.test("rejects consumer mailboxes", () => {
  for (const email of ["jane@gmail.com", "jane@outlook.com", "jane@proton.me", "jane@qq.com"]) {
    const r = validate({ ...good, email });
    assertEquals(r.ok, false, email);
    assertStringIncludes(r.reasons.join(","), "email:public");
  }
});

Deno.test("rejects disposable mailboxes", () => {
  const r = validate({ ...good, email: "jane@mailinator.com" });
  assertEquals(r.ok, false);
  assertStringIncludes(r.reasons.join(","), "email:disposable");
});

Deno.test("allows consumer mailboxes when explicitly enabled", () => {
  assertEquals(validate({ ...good, email: "jane@gmail.com" }, { allowPublicDomains: true }).ok, true);
});

Deno.test("requires a first and last name", () => {
  assertStringIncludes(reasonsOf({ ...good, name: "Jane" }), "name:single-token");
  assertStringIncludes(reasonsOf({ ...good, name: "" }), "name:empty");
});

Deno.test("rejects junk names", () => {
  assertStringIncludes(reasonsOf({ ...good, name: "asdfgh qwerty" }), "name:mashed");
  assertStringIncludes(reasonsOf({ ...good, name: "Jane123 Okafor" }), "name:digits");
  assertStringIncludes(reasonsOf({ ...good, name: "Jane http://spam.ru" }), "name:");
  assertStringIncludes(reasonsOf({ ...good, name: "Jaaaaane Okafor" }), "name:mashed");
});

Deno.test("accepts names with accents, hyphens and initials", () => {
  for (const name of ["José Álvarez", "Anne-Marie O'Neill", "J. Okafor", "Łukasz Nowak"]) {
    assertEquals(validate({ ...good, name }).ok, true, name);
  }
});

Deno.test("rejects spam messages", () => {
  assertStringIncludes(
    reasonsOf({ ...good, message: "We offer SEO services and quality backlinks for your website." }),
    "message:phrase",
  );
  assertStringIncludes(
    reasonsOf({ ...good, message: "Visit https://a.ru https://b.ru https://c.ru now for details ok" }),
    "message:links",
  );
  assertStringIncludes(reasonsOf({ ...good, message: "asdkj hsdfkj wqrqw zxcvbn qwrqwr zzzxcv" }), "message:");
  assertStringIncludes(reasonsOf({ ...good, message: "short" }), "message:too-short");
});

Deno.test("catches the honeypot and the time trap", () => {
  assertStringIncludes(reasonsOf({ ...good, website: "http://spam" }), "honeypot");
  const now = Date.now();
  const fast = validate({ ...good, renderedAt: now - 500 }, { now });
  assertEquals(fast.ok, false);
  assertStringIncludes(fast.reasons.join(","), "too-fast");
  assertEquals(validate({ ...good, renderedAt: now - 20_000 }, { now }).ok, true);
});

Deno.test("scan form needs only a work email", () => {
  const r = validate({ form: "scan", email: "ops@acme-analytics.com", interest: "Free estate scan (home page)" });
  assertEquals(r.ok, true);
  assertEquals(r.data?.form, "scan");
});

Deno.test("never leaks internal reasons into user-facing errors", () => {
  const r = validate({ ...good, email: "jane@gmail.com" });
  assertEquals(r.errors.some((e) => e.includes(":")), false);
});
