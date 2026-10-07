# Brand assets

| File | Use |
|---|---|
| `bimigrations-logo.svg` | **Full lockup, light backgrounds — use this one by default** |
| `bimigrations-logo-dark.svg` | Full lockup, dark backgrounds |
| `bimigrations-mark.svg` | Cube only, light backgrounds — favicons, avatars, app icons |
| `bimigrations-mark-dark.svg` | Cube only, dark backgrounds |
| `bimigrations-logo-text.svg` | Lockup with live (editable) text, light backgrounds |
| `bimigrations-logo-dark-text.svg` | Lockup with live text, dark backgrounds |

The two lockups marked **outlined** (`bimigrations-logo.svg` and its dark twin)
have the wordmark converted to paths, so they render identically everywhere with
no font installed. Send those to printers, partners and press.

The `-text` versions keep the wordmark as real text: handy if you need to edit
the words or restyle them, but they need Archivo installed to render correctly.

## PNG versions

`png/` holds transparent-background PNGs rendered from the same SVGs:

| Pattern | Sizes |
|---|---|
| `png/bimigrations-logo[-dark]-<width>.png` | 2400, 1200, 600 px wide |
| `png/bimigrations-mark[-dark]-<size>.png` | 1024, 512, 256, 128, 64 px square |

Use the SVGs wherever they're accepted — they stay sharp at any size. Reach for
a PNG when a tool won't take SVG (some slide decks, email signatures, social
profiles, app stores). Pick a size at least as large as it will be displayed.

To render more sizes:

```bash
tools/svg-to-png.sh brand-assets/bimigrations-logo.svg brand-assets/png/bimigrations-logo-900.png 900
```

## Colors

| Role | Light backgrounds | Dark backgrounds |
|---|---|---|
| Ink (cube top, wordmark) | `#0A0C10` | `#F3F0E8` |
| Amber (cube left) | `#C7681B` | `#FFB16A` |
| Teal (cube right) | `#0B7F6B` | `#19E0B8` |
| Slash | `#5F6570` | `#6F7278` |

## Using them

- **Clear space:** keep at least the height of the cube's top face (about a
  quarter of the mark's height) clear on every side.
- **Minimum size:** 24px tall for the mark, 120px wide for the lockup. Below
  that, use the mark alone.
- **Don't** recolor the faces, rotate the cube, add effects, stretch the
  lockup, or rebuild the wordmark in another typeface.
- **Backgrounds:** use the dark variants on anything darker than mid-gray. On
  photos, place the lockup on a solid panel rather than directly on the image.

## The wordmark typeface

The wordmark is **Archivo Bold** (Google Fonts), uppercase, 0.1em letter-spacing,
with the slash in Archivo Regular. In the default lockups the letters are already
outlined, so nothing needs installing.

If you rebuild the lockup from the `-text` versions, keep those settings, and
outline the text again before sending the file out.
