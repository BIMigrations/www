# www

Public-facing website of BITransition — a Jekyll site.

## Develop

```bash
bundle install
bundle exec jekyll serve
```

Then open http://localhost:4000.

## Structure

- `index.html` — home page (hero, manifesto, before/after reveal, method, scan CTA)
- `soon.html` — placeholder for pages still in design (`/soon/`)
- `_layouts/default.html` — HTML shell: fonts, favicon, theme bootstrap, SEO
- `_includes/header.html`, `_includes/footer.html` — shared nav and footer
- `assets/css/main.css` — theme tokens (light/dark) and base styles
- `assets/js/main.js` — theme toggle, hero particle field, platform marquee,
  before/after slider, and the decorative grids

The design was produced in Claude Design (`.dc.html` canvases) and ported to
standard HTML/CSS/vanilla-JS here. Light is the default theme; the choice is
remembered in `localStorage`.

## Responsive behaviour

Styles are class-based in `main.css`, with breakpoints at the bottom of the file:

- **≤ 1000px** — the pill nav collapses to a menu button that opens a
  full-screen numbered menu (with the theme switch and scan CTA).
- **≤ 760px** — a dedicated mobile layout rather than a squeezed desktop:
  - Hero: the particle field runs top→bottom and converges into the teal
    "Anywhere" dot; the headline breaks to three lines.
  - Manifesto: A/B/C become swipeable scroll-snap cards.
  - Before/after: a portrait compare with touch dragging that doesn't block
    vertical scrolling, plus a one-time sweep to show it's interactive.
  - Method: steps become sticky cards that stack as you scroll.
  - A floating "Free estate scan" dock appears whenever no other scan CTA is
    on screen.

Hover styles are gated behind `@media (hover: hover)`, and
`prefers-reduced-motion` stops the marquee, particle animation and sweep.

## Build

```bash
bundle exec jekyll build   # outputs to _site/
```
