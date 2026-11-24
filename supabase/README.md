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

## `video-events` edge function: demo-video viewing log

Optional first-party record of who watched the home-page demo video and how much. The site sends
the same events to Google Analytics 4 regardless (`video_start`, `video_progress` at 10, 25, 50,
75 and 90 percent of the film actually played, `video_complete`, `video_summary`); this adds a
queryable table in Supabase and lets a contact or scan lead be matched to what they watched.

It is **off until the endpoint is set**: while `video_endpoint` in `_config.yml` is empty, the site
stores nothing in the browser and posts nothing here.

### Switching it on, in this order

1. Apply the migration (`supabase db push`, or paste `migrations/20261124120000_video_events.sql`
   into the SQL editor). It adds `video_events`, adds `visitor_id` to `contact_submissions`, and
   creates the views `video_sessions`, `video_viewers` and `leads_who_watched`. Apply it **before**
   step 3, or form submissions carrying a visitor id will not be logged.
2. `supabase secrets set VIDEO_IP_SALT="<a long random string>"` and
   `supabase functions deploy video-events --no-verify-jwt`
3. Redeploy the `contact` function (it now records the optional `visitor_id`):
   `supabase functions deploy contact --no-verify-jwt`
4. Set `video_endpoint: "https://iiznemotvcrukeajsist.supabase.co/functions/v1/video-events"` in
   `_config.yml` and push. Add the first-party sentence to `privacy.md` in the same commit (see
   `companies/bimigrations/video-analytics-plan-2026-11-24.md` in the Amy repo for the wording).
5. Play the video on the live site, then check `select * from video_events order by id desc limit 10;`.
   Confirm `country` is filled. If it is null, the edge network is not passing `cf-ipcountry`.

### Questions it answers

```sql
select * from video_viewers order by last_seen desc;            -- one row per visitor
select engagement, count(*) from video_sessions group by 1;     -- glance / partial / most / complete
select country, count(*), avg(percent_watched) from video_sessions group by 1 order by 2 desc;
select * from leads_who_watched;                                 -- leads, with what they watched
```

What is stored: a random visitor id and session id, the event and its numbers, the page, the
referrer and UTM tags, screen size, device class, country, a salted hash of the IP and the user
agent. No raw IP, no name, no email. Bots are ignored. Rate limit: 120 events per hashed IP per
10 minutes.
