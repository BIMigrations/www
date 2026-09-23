# www

Public-facing website of BI Migrations — a Jekyll site.

## Develop

```bash
bundle install
bundle exec jekyll serve
```

Then open http://localhost:4000.

## Structure

| Path | What it is |
|---|---|
| `index.html` | Home page (hero, manifesto, before/after reveal, method, scan CTA) |
| `_layouts/default.html` | HTML shell: fonts, favicon, theme bootstrap, SEO |
| `_layouts/page.html` | Shared sub-page layout: hero, breadcrumbs, content + "On this page", CTA band |
| `_includes/` | Header (nav, platform dropdown, mobile menu), footer, cards, FAQ, CTA, form attributes |
| `_data/nav.yml` | **All navigation** — top nav, footer sitemap, legal links, mobile "more" groups |
| `_data/platforms.yml` | Featured platforms (drives the dropdown, menu and `/platforms/`) |
| `_data/routes.yml` | Migration routes (Domo → Power BI, Tableau → Power BI, …) — drives the nav, home section, footer and related links |
| `_data/faqs.yml` | Questions on `/faqs/` |
| `_data/gform.yml` | Google Form ID and field mapping for the contact and scan forms |
| `platforms/` | `/platforms/` and one page per featured platform |
| `services/` | Estate assessment, full migration, rationalisation, engagement models |
| `_posts/` | Insights articles (`/insights/<slug>/`) |
| `_guides/` | Migration guides (`/migration-guides/<slug>/`) |
| `_case_studies/` | Case studies (`/case-studies/<slug>/`) — see the template below |
| `*.md` at the root | About, open specifications, risk & governance, FAQs, careers, partners, security, privacy, terms |
| `contact.html`, `404.html` | Contact form and not-found page |
| `assets/css/main.css` | Theme tokens and all styles (breakpoints at 1000px and 760px) |
| `assets/js/main.js` | Theme, menu, hero field, marquee, compare slider, carousel, dock, table of contents |

## Adding content

- **A page:** create a Markdown file with front matter (`title`, `heading` — HTML allowed, use `<em>` for the serif accent — `description`, `permalink`). The `page` layout is applied automatically. Use `{% include cards.html items=page.<list> %}` for card grids.
- **An insight:** add `_posts/YYYY-MM-DD-slug.md` with `title`, `heading` and `description`.
- **A migration guide:** add `_guides/<slug>.md` with `from`, `to`, `crumb` and `order`.
- **A case study:** copy `_case_studies/example-case-study.md`, fill it in, and set `published: true` once the client has approved it. Until then `/case-studies/` shows an explanatory empty state.
- **Navigation:** edit `_data/nav.yml`. Keep the top nav short — new pages belong in the footer groups and `menu_more`.

## SEO

- **Keyword landing pages:** `/domo-to-power-bi/` and `/tableau-to-power-bi/` are the money pages. The migration guides are their informational companions, with deliberately different titles, and link back to them.
- **Internal links:** routes in `_data/routes.yml` appear in the nav dropdown, mobile menu, home page, footer and `/platforms/`. Contextual links use the exact phrases ("Domo to Power BI migration", "Tableau to Power BI migration").
- **Metadata:** `jekyll-seo-tag` writes titles, descriptions, canonicals and Open Graph/Twitter tags. Keep `title` ≤ 50 characters (the site name is appended) and `description` ≤ 160. Use `lead` for a longer visible intro.
- **Structured data** (`_includes/schema.html`): Organization (home), BreadcrumbList (sub-pages), FAQPage (any page with `faqs` front matter, and `/faqs/`), Service (pages with `service`), TechArticle (guides).
- **Crawling:** `sitemap.xml` and `robots.txt` come from `jekyll-sitemap`; set `sitemap: false` or `noindex: true` in front matter to exclude a page.
- **Share images:** `assets/img/og/` (1200×630). Set `image:` in front matter for a page-specific one.
- **Search Console:** add the verification token under `webmaster_verifications` in `_config.yml`, then submit `https://bimigrations.com/sitemap.xml`.

GitHub Pages builds this site with its standard (legacy) Jekyll build, so only whitelisted plugins run.

## Forms

The home-page scan form and `/contact/` submit to the Google Form configured in
`_data/gform.yml`, which is what triggers the notification email.

- `assets/js/main.js` intercepts the submit and posts the fields to the form's
  `formResponse` endpoint with `fetch(..., { mode: 'no-cors' })`, then swaps the
  form for a thank-you panel. Without JavaScript the form posts natively and the
  visitor lands on Google's own confirmation page.
- Field names in the markup **are** the Google entry IDs, pulled from
  `_data/gform.yml`, so a form change means editing that one file.
- To find the IDs: open the form and read `FB_PUBLIC_LOAD_DATA_[1][1]` in the
  console — each question's ID is `item[4][0][0]`. The built-in email question is
  `emailAddress`, not an `entry.*` field.
- Every form has a hidden honeypot field; submissions that fill it are dropped
  silently.
- The form has no Message question yet, so the message typed on `/contact/` is
  appended to the interest answer. Add a paragraph question called "Message" and
  put its entry ID in `_data/gform.yml` to give it its own column.

## Responsive behaviour

- **≤ 1000px** — the pill nav collapses to a full-screen menu with the primary links, platform chips, grouped secondary links, theme switch and scan CTA. Sub-pages drop the sticky "On this page" sidebar.
- **≤ 760px** — dedicated mobile layouts: vertical particle funnel in the hero, swipeable manifesto cards, touch-friendly before/after, stacking method cards, a floating scan dock, single-column cards and forms.

Hover styles are gated behind `@media (hover: hover)`, and `prefers-reduced-motion` stops the marquee, particle animation and sweep.

## Build

```bash
bundle exec jekyll build   # outputs to _site/
```
