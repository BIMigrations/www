#!/usr/bin/env bash
# Scaffold a blog post and its social image.
#   tools/new-post.sh "Beast Mode to DAX: the patterns that bite" [image-headline]
# See docs/blogging-guide.md for the rules that matter.
set -euo pipefail
TITLE="${1:?Usage: tools/new-post.sh \"Post title\" [\"Image headline\"]}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATE="$(date +%F)"
SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
FILE="$ROOT/_posts/$DATE-$SLUG.md"
IMG="assets/img/og/$SLUG.png"
ART="${2:-$TITLE}"

[ -e "$FILE" ] && { echo "$FILE already exists" >&2; exit 1; }
cat > "$FILE" <<POST
---
title: "$TITLE"
heading: "$TITLE"
description: ""
image: /$IMG
---

TODO: opening — the real situation, tension stated by the end of paragraph two.

## First heading with one *accent*

TODO

## Where it *breaks*

TODO

## What this means for your *estate*

TODO — tie back to how we work, then one link out, e.g.
[open specifications](/open-specifications/) or
[Domo to Power BI migration](/domo-to-power-bi/).
POST

"$ROOT/tools/make-og-image.sh" "$IMG" "$ART" "Insights" "<b>Amy Loomis</b>"
echo "created _posts/$DATE-$SLUG.md  ->  /insights/$SLUG/"
echo "next: fill in description (120-160 chars), heading (<em>accent</em>), and the body"
