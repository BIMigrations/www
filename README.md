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

## Build

```bash
bundle exec jekyll build   # outputs to _site/
```
