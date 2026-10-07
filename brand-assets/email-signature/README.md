# Email signature

| File | What it is |
|---|---|
| `signature.html` | Abi Chatterjee's signature, ready to paste |
| `signature-template.html` | Same layout with `{{PLACEHOLDERS}}` for everyone else |
| `signature.txt` | Plain-text version, for clients set to plain text |

The logo loads from `https://bimigrations.com/brand-assets/png/bimigrations-mark-128.png`,
so it appears for recipients without being an attachment. Keep that file in place.

## Installing it

**Gmail (web)** — open `signature.html` in a browser, select the whole signature
(Cmd/Ctrl-A), copy, then Settings → See all settings → General → Signature →
paste. Don't paste the file's source code; paste the rendered version.

**Apple Mail** — Mail → Settings → Signatures, create one, then paste the
rendered signature in. Untick "Always match my default message font".

**Outlook (web)** — Settings → Mail → Compose and reply → paste into the
signature box.

**Outlook (Windows desktop)** — paste into File → Options → Mail → Signatures.
Outlook ignores `border-radius`, so the card shows square corners there. Nothing
else changes.

## Why it sits on a white card

Mail clients handle dark mode inconsistently: some invert colors, some leave the
signature untouched on a dark background, which turns near-black text invisible.
Giving the signature its own light background keeps it legible and keeps the
brand colors accurate everywhere. It's the standard approach for this reason.

## Making one for someone else

Copy `signature-template.html` and replace:

| Placeholder | Example |
|---|---|
| `{{FULL NAME}}` | Jane Okafor |
| `{{JOB TITLE}}` | Migration lead |
| `{{EMAIL}}` | jane@bimigrations.com (appears twice: link and label) |
| `{{PHONE DISPLAY}}` | +44 7700 900123 |
| `{{PHONE E164}}` | +447700900123 (no spaces, for the tel: link) |

Keep the layout, colors and tagline as they are so signatures match across the
team. If someone has no phone number, delete that whole line rather than leaving
it blank.
