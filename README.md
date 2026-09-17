# www

Public-facing website of BITransition — a Jekyll site.

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
| `_data/faqs.yml` | Questions on `/faqs/` |
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

## Forms

The home-page scan form and `/contact/` post to `form_endpoint` in `_config.yml` (for example, a Formspree URL). While it's empty, the forms don't submit.

## Responsive behaviour

- **≤ 1000px** — the pill nav collapses to a full-screen menu with the primary links, platform chips, grouped secondary links, theme switch and scan CTA. Sub-pages drop the sticky "On this page" sidebar.
- **≤ 760px** — dedicated mobile layouts: vertical particle funnel in the hero, swipeable manifesto cards, touch-friendly before/after, stacking method cards, a floating scan dock, single-column cards and forms.

Hover styles are gated behind `@media (hover: hover)`, and `prefers-reduced-motion` stops the marquee, particle animation and sweep.

## Build

```bash
bundle exec jekyll build   # outputs to _site/
```
