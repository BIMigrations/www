#!/usr/bin/env bash
# Rasterize an SVG to a transparent PNG at a given pixel width.
#   tools/svg-to-png.sh <input.svg> <output.png> <width>
# Height follows the SVG's own aspect ratio.
set -euo pipefail
SRC="$1"; OUT="$2"; W="$3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }

# read the viewBox to work out the height
read -r VB_W VB_H <<<"$(python3 - "$SRC" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
m=re.search(r'viewBox="([\d.\-]+) +([\d.\-]+) +([\d.\-]+) +([\d.\-]+)"', s)
print(m.group(3), m.group(4))
PY
)"
H=$(python3 -c "print(round($W * $VB_H / $VB_W))")

TMP="$(mktemp -d)"
cp "$SRC" "$TMP/art.svg"
cat > "$TMP/page.html" <<HTML
<!doctype html><meta charset="utf-8">
<style>html,body{margin:0;padding:0;background:transparent}img{display:block;width:${W}px;height:${H}px}</style>
<img src="art.svg">
HTML
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$TMP/profile" \
  --default-background-color=00000000 --force-device-scale-factor=1 \
  --window-size="$W,$H" --virtual-time-budget=5000 \
  --screenshot="$ROOT/$OUT" "file://$TMP/page.html" >/dev/null 2>&1 &
PID=$!
for _ in $(seq 1 30); do [ -s "$ROOT/$OUT" ] && break; sleep 1; done
sleep 1; kill $PID 2>/dev/null || true; sleep 1; rm -rf "$TMP" 2>/dev/null || true
[ -s "$ROOT/$OUT" ] && echo "wrote $OUT (${W}x${H})" || { echo "failed: $OUT" >&2; exit 1; }
