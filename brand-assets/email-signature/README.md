# Email signature

| File | What it is |
|---|---|
| `signature.html` | Abi Chatterjee's signature, **logo embedded as base64** |
| `signature-template.html` | Same, with `{{PLACEHOLDERS}}` for everyone else |
| `signature-hosted.html` | Variant that loads the logo from the website |
| `logo-email.png` | The logo on its own (392x79), for clients that want a file |
| `signature.txt` | Plain-text version |

## Installing it

**However you install it, paste the _rendered_ signature, not the HTML source.**
Open the file in a browser, select everything (Cmd/Ctrl-A), copy, then paste
into the signature box.

**Outlook (Windows desktop)** — paste into File → Options → Mail → Signatures.
Outlook saves the image into its own signature folder and attaches it to each
message, so recipients never see the "click to download pictures" prompt. This
is the behaviour we want, and it is why pasting matters.

**Outlook (web / new Outlook)** — Settings → Mail → Compose and reply → paste.

**Gmail** — Settings → See all settings → General → Signature → paste. Gmail
re-hosts the image on its own servers automatically.

**Apple Mail** — Mail → Settings → Signatures, paste, then untick "Always match
my default message font".

## About embedded images

The logo is a base64 `data:` URI, so the HTML carries the image itself. Worth
knowing how clients treat that:

| Client | Behaviour |
|---|---|
| Apple Mail, iOS Mail | Renders `data:` URIs directly |
| Outlook desktop | Does **not** render `data:` URIs in HTML it imports. Pasting the rendered signature sidesteps this: Outlook embeds the image as an attachment instead |
| Gmail | Strips `data:` URIs from imported HTML, but pastes fine and re-hosts the image |

So: paste it, and every client ends up with a local or attached copy. If you
ever hand-edit the Outlook signature file (`%APPDATA%\Microsoft\Signatures`),
drop `logo-email.png` into the matching `_files` folder and point the `img` tag
at it rather than using base64.

The image is 392x79 and displayed at 196x40, so it stays sharp on high-density
screens, and it is under 2KB.

## Why it sits on a white card

Mail clients handle dark mode inconsistently: some invert colors, some leave the
signature on a dark background, which turns near-black text invisible. Its own
light background keeps it legible and the brand colors accurate everywhere.

Layout: lockup and strapline on the left, a hairline divider, then the person's
details on the right.

## Making one for someone else

Copy `signature-template.html` and replace:

| Placeholder | Example |
|---|---|
| `{{FULL NAME}}` | Jane Okafor |
| `{{JOB TITLE}}` | Migration lead |
| `{{EMAIL}}` | jane@bimigrations.com (appears twice: link and label) |
| `{{PHONE DISPLAY}}` | +44 7700 900123 |
| `{{PHONE E164}}` | +447700900123 (no spaces, for the tel: link) |

Keep the layout, colors and strapline as they are so signatures match across the
team. If someone has no phone number, delete that whole line rather than leaving
it blank.
