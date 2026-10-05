#!/usr/bin/env bash
# Render a 1200x630 social/blog card.
#   tools/make-og-image.sh <output.png> "<Title, <em>accent</em> allowed>" ["Kicker"] ["Byline"]
# Example:
#   tools/make-og-image.sh assets/img/og/my-post.png "Why estates <em>drift.</em>" "Insights" "<b>Amy Loomis</b>"
set -euo pipefail
OUT="$1"; TITLE="${2:-}"; KICKER="${3:-Insights}"; BYLINE="${4:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
PROFILE="$(mktemp -d)"
urlenc() { python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }
URL="file://$ROOT/tools/og-template.html?title=$(urlenc "$TITLE")&kicker=$(urlenc "$KICKER")&byline=$(urlenc "$BYLINE")"
rm -f "$ROOT/$OUT"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$PROFILE" \
  --window-size=1200,630 --virtual-time-budget=6000 --screenshot="$ROOT/$OUT" "$URL" >/dev/null 2>&1 &
PID=$!
for _ in $(seq 1 30); do [ -s "$ROOT/$OUT" ] && break; sleep 1; done
sleep 1; kill $PID 2>/dev/null || true; sleep 1; rm -rf "$PROFILE" 2>/dev/null || true
[ -s "$ROOT/$OUT" ] && echo "wrote $OUT" || { echo "failed to render $OUT" >&2; exit 1; }
