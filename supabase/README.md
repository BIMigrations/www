# Supabase backend

## `contact` edge function

Receives the website's contact and estate-scan forms, validates them, and emails
the team. Replaces the Google Form, which collected too much junk.

### What it checks

| Check | Rule |
|---|---|
| Honeypot | the hidden `website` field must be empty |
| Time trap | at least `MIN_FILL_SECONDS` (default 3) between form render and submit |
| Rate limit | 5 submissions per IP per 10 minutes |
| Email | valid syntax, not a consumer mailbox (Gmail, Outlook, Proton, QQ…), not disposable |
| Name | first **and** last name, letters only, no keyboard mash, accents and hyphens fine |
| Company | length and junk check, optional |
| Message | 20–5000 chars, max 2 links, no marketing phrases, not shouting, not gibberish |

The estate-scan form only needs a work email; the contact form needs name and
message too.

Rejections return **422** with plain-English messages. The precise reason is
logged, never returned, so a spammer can't tune against the rules.

### Deploying

```bash
supabase link --project-ref <your-project-ref>
supabase functions deploy contact --no-verify-jwt
```

`--no-verify-jwt` matters: the website posts anonymously, with no Supabase auth
token.

### Secrets

Set these once, from the SMTP credentials file. **Never commit them.**

```bash
supabase secrets set \
  SMTP_HOST="<endpoint from the credentials file>" \
  SMTP_PORT="587" \
  SMTP_USER="<username>" \
  SMTP_PASS="<password>"
```

Inquiries go to **abi@bimigrations.com and les@bimigrations.com** by default.
Set the `MAIL_TO` secret (comma-separated) only to change that list.

Optional settings:

| Variable | Default | Purpose |
|---|---|---|
| `AUTO_REPLY` | `true` | send the sender a thank-you |
| `ALLOWED_ORIGINS` | the live site plus `localhost:4321` | CORS allowlist |
| `MIN_FILL_SECONDS` | `3` | time trap threshold |
| `ALLOW_PUBLIC_DOMAINS` | `false` | accept Gmail etc. — testing only |
| `MAIL_TO` | `abi@`, `les@bimigrations.com` | where inquiries land, comma-separated |

Two senders, both verified in SES:

| Variable | Default | Used for |
|---|---|---|
| `MAIL_FROM_NOTIFY` | `BI Migrations <abhishek@gritsa.com>` | the inquiry notification to the team |
| `MAIL_FROM_REPLY` | `BI Migrations <abi@bimigrations.com>` | the thank-you to the person who wrote in |

The notification is sent from gritsa.com because bimigrations.com publishes
DMARC `p=quarantine` while its SPF doesn't list Amazon SES, so mail sent as
`@bimigrations.com` through SES is quarantined on arrival. gritsa.com publishes
`p=none`, so it gets through. Fixing bimigrations.com's SPF and DKIM is the
proper remedy — see the deliverability note below.

## Deliverability

Until `bimigrations.com` authorizes SES, anything sent as `@bimigrations.com`
(including the auto-reply) can be quarantined by the recipient:

1. Add SES to SPF: `v=spf1 include:_spf-usg2.ppe-hosted.com include:secureserver.net include:amazonses.com ~all`
2. Verify the **domain** `bimigrations.com` in SES (us-east-1) and add the three
   DKIM CNAMEs it issues. Today only the address is verified, with DKIM off.

### Testing it

```bash
# should succeed
curl -i -X POST "$FN_URL" -H 'content-type: application/json' \
  -d '{"form":"contact","name":"Jane Okafor","email":"jane@acme-analytics.com",
       "company":"Acme Analytics","message":"We run 400 Tableau workbooks and are scoping a move."}'

# should be rejected: consumer mailbox
curl -i -X POST "$FN_URL" -H 'content-type: application/json' \
  -d '{"form":"contact","name":"Jane Okafor","email":"jane@gmail.com","message":"We are scoping a migration project."}'
```

### Unit tests

```bash
deno test supabase/functions/contact/validate_test.ts
```

Covers the validation rules with no network or SMTP involved.
