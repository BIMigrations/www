# Blogging guide — BI Migrations Insights

This is the working brief for the person or agent writing the blog. Posts go out
**twice a week** under the byline **Amy Loomis**.

---

## 1. Who Amy is

Amy Loomis is the Insights byline for BI Migrations. She writes as someone who
has been inside a lot of BI implementations: specific, calm, never breathless.
Her bio lives in `_data/authors.yml` and keeps to what she writes about.

The voice is confident but grounded. Posts earn trust through accurate mechanics
— real function names, real failure modes — not through claims about who wrote
them.

**Amy never:** invents a client, a conversation, a quote or a statistic; claims
to have personally attended a meeting; or implies a named customer engagement.
Write "we see" and "teams often", not "last week I sat with a CFO who…". That
rule is about accuracy, and it is not negotiable — a single invented client
story is the kind of thing that ends up in a sales call.

## 2. Cadence and rhythm

- **Two posts a week.** Tuesday and Thursday work well.
- **Alternate register:** one practical/technical post, one strategic post.
- **Don't publish two posts on the same platform pair in a row.** Rotate.

---

## 3. Where topics come from

### First: the ideas queue on GitHub

Colleagues file ideas as GitHub issues labeled `blog` on `BIMigrations/www`.
**Check these before inventing a topic** — they come from real client questions
and sales calls, which beats anything trend-watching will turn up.

```bash
gh issue list --repo BIMigrations/www --label blog --state open
gh issue view <number> --repo BIMigrations/www           # read the full brief
gh issue comment <number> --repo BIMigrations/www --body "Picking this up for Thursday."
```

Each issue carries a topic, an angle, a target search phrase and pages it should
link to. Honour those fields: they are the brief.

When the post is live, close the issue with the URL:

```bash
gh issue close <number> --repo BIMigrations/www --comment "Published: https://bimigrations.com/insights/<slug>/"
```

Mention the issue in the commit (`Closes #12`) so the trail is obvious.

If several issues are open, prefer the one that is most time-sensitive (a recent
release, a vendor change), then the one targeting the strongest search phrase.

### Second: the five pillars

With the queue empty, pick something a BI lead is actually searching for this
month:

| Pillar | Example angles |
|---|---|
| **Translating X into Y** | Beast Mode to DAX; LOD to DAX; LookML to semantic models; set analysis to CALCULATE; Tableau Prep to dbt |
| **BI and analytics engineering practice** | Metric definitions that survive a migration; naming conventions; testing a semantic layer; how to review a dashboard like code |
| **dbt and similar frameworks** | dbt metrics vs. BI-layer metrics; dbt tests as parity tests; semantic layer standards; SQLMesh, Dagster, Airflow in a BI estate |
| **Infrastructure providers and their BI services** | Microsoft Fabric; Databricks AI/BI dashboards; Snowflake and semantic views; BigQuery and Looker; AWS QuickSight |
| **Warehousing systems** | Modeling for import vs. DirectQuery; incremental models; cost control; lakehouse table formats under a BI tool |

**How to find the angle.** A topic is not a post. Before writing, answer:
- What does nearly every article about this get wrong or skip?
- What does this look like in an estate of 800 dashboards rather than 8?
- What breaks on the way, and what does that cost?

The angle is usually the gap between the vendor demo and a real estate.

---

## 4. The shape of a post

**Length:** 700–1,200 words. Long enough to be useful, short enough to be read.

```
Opening (2–3 short paragraphs)
  The real situation. No "In today's fast-paced world".
  State the tension by the end of paragraph two.

## A heading with one *italic* word
  2–5 paragraphs, or a table, or a tight list.
  Concrete mechanics: names of real features, real function names.

## A second heading
  Where it goes wrong. The part people learn the hard way.

## A third heading (optional)
  What to do instead — steps, a checklist, a mapping table.

## Closing heading
  Tie the topic to the BI Migrations way of working, then one link out.
```

**Headings:** sentence case, one word wrapped in `*asterisks*` for the serif
accent (this is the house style — `## Where it *breaks*`). Two to four headings.

**Tables** are welcome for mappings (`Source concept | Target concept | Notes`).

**Code** is welcome: short SQL, DAX or YAML snippets in fenced blocks. Keep them
under ~12 lines and make sure they are correct.

---

## 5. The ending rule

Every post ends by connecting the topic to what we do, then links onward. Not a
hard sell — one short paragraph that earns the link.

Good:
> Whichever way the semantic layer lands, the expensive part is agreeing what
> each number means. That is the half we capture as
> [open specifications](/open-specifications/), so the next platform change
> starts from a documented estate.

Bad:
> BI Migrations is the leading provider of automated BI migration. Contact us
> today!

---

## 6. Internal linking (this is the point)

Every post carries **three to six** internal links:

- **At least one to a money page:** [/domo-to-power-bi/](/domo-to-power-bi/) or
  [/tableau-to-power-bi/](/tableau-to-power-bi/).
- **At least one to a supporting page:** a platform page, a service page,
  [/open-specifications/](/open-specifications/) or
  [/risk-governance/](/risk-governance/).
- **At least one to another post**, so the blog forms a cluster rather than a
  pile. Previous/next links are automatic, but in-body links matter more.

**Anchor text is the phrase people search**, not "click here" and not the bare
URL: `[Domo to Power BI migration](/domo-to-power-bi/)`.

Links are root-relative (`/faqs/`), never absolute to the domain.

---

## 7. Facts, numbers and honesty

- **Never invent a statistic, client, quote or case study.**
- The only performance figures we publish are the ones already on the site:
  ~**78%** of a typical estate converted by tooling, **11 weeks** median kickoff
  to cutover, **1:1** value parity. Reuse them sparingly; don't inflate them.
- Vendor facts (function names, feature availability, pricing models) must be
  checked against current vendor documentation before publishing. Features move.
- If something is our opinion, say so: "we'd argue", "in the estates we see".
- No competitor bashing. Describe trade-offs, not villains.

---

## 8. House style

- **US spelling**: rationalization, organization, prioritize, modeling, gray.
- **Our tool is "our automated migration tool"** — never "the generator".
- **BI platform names**: Power BI, Domo, Tableau, Qlik Sense, QlikView, Looker,
  MicroStrategy, Cognos, Sigma, Superset. Capitalize as the vendor does.
- Em dashes — like this — are part of the voice. Don't overdo them.
- Prefer plain words: "estate", "dashboards", "numbers". Avoid "leverage",
  "robust", "seamless", "unlock", "in today's landscape".
- Sentence case for headings and titles. No Title Case Everywhere.
- Second person ("you") for advice, first person plural ("we") for what we do.

---

## 9. Creating the post

### File

`_posts/YYYY-MM-DD-slug.md` — the slug becomes the URL: `/insights/slug/`.
Keep slugs short, keyword-first, hyphenated: `beast-mode-to-dax-patterns.md`.

### Front matter

```yaml
---
title: "Beast Mode to DAX: the patterns that bite"   # ≤ 50 chars (site name is appended)
heading: "Beast Mode to DAX, <em>pattern by pattern.</em>"   # on-page H1, <em> = serif accent
description: "How Domo Beast Modes map onto DAX measures, which ones change meaning in filter context, and how to prove the numbers still match."  # 120–160 chars
image: /assets/img/og/beast-mode-to-dax-patterns.png
---
```

- `title` is what search results show. Put the keyword at the front.
- `heading` is what the page shows. It can be more playful than the title.
- `description` is the meta description **and** the card text on the home page
  and index — write it for a human, 120–160 characters.
- `author` defaults to `amy-loomis`; only set it to override.

### Social image

```bash
tools/make-og-image.sh assets/img/og/<slug>.png "Beast Mode to <em>DAX.</em>" "Insights" "<b>Amy Loomis</b>"
```

Keep the image headline shorter than the post title — four to seven words. One
word in `<em>` for the serif accent.

### Scaffold both at once

```bash
tools/new-post.sh "Beast Mode to DAX: the patterns that bite"
```

That creates the file with today's date, a front-matter skeleton and the image.

---

## 10. Before publishing — checklist

- [ ] `title` ≤ 50 characters, keyword first, unique across the site
- [ ] `description` 120–160 characters, reads as a sentence
- [ ] `heading` has exactly one `<em>` accent
- [ ] 3–6 internal links, including a money page and another post
- [ ] No invented numbers, clients or quotes; vendor facts checked
- [ ] US spelling; "our automated migration tool"
- [ ] Social image generated and referenced in `image:`
- [ ] `bundle exec jekyll build` runs clean
- [ ] Post appears on `/` (home section shows the three most recent) and `/insights/`
- [ ] Previous/next links on the post point at the right neighbours
- [ ] If the post came from a `blog` issue, close it with the published URL

Then commit, push, and confirm the page is live.

---

## 11. Where things live

| What | Where |
|---|---|
| Posts | `_posts/` |
| Byline and bio | `_data/authors.yml` |
| Index page | `insights/index.html` |
| Home page section | `index.html`, section `§ 05 — Insights` |
| Card markup | `_includes/post-card.html` |
| Author note, prev/next | `_includes/post-footer.html` |
| Image tool | `tools/make-og-image.sh` |
| Scaffold | `tools/new-post.sh` |
| Idea queue | GitHub issues labeled `blog` on `BIMigrations/www` |

The home page always shows the three most recent posts, so nothing extra is
needed to feature a new one.
