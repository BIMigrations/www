#!/bin/sh
# Estate Scanner installer for macOS and Linux.
#
#   curl -fsSL https://bimigrations.com/downloads/estatescanner/install.sh | sh
#
# Finds Python 3.11+ (or installs one for you, no administrator rights needed),
# installs the latest Estate Scanner into ~/.estate-scanner, then starts it.
# Run it again any time: it updates to the latest version and starts the app.
#
# Settings (all optional, mostly for testing and support):
#   ESTATE_SCANNER_BASE       where latest.txt and the wheel are downloaded from
#   ESTATE_SCANNER_HOME       install folder (default ~/.estate-scanner)
#   ESTATE_SCANNER_CHECK=1    install, run the self-test, do not open the app
#   ESTATE_SCANNER_FORCE_UV=1 ignore any Python already on the machine
#   ESTATE_SCANNER_NO_LAUNCH=1 install only

# Everything lives in main() so a truncated download runs nothing at all.
main() {
  set -eu
  BASE="${ESTATE_SCANNER_BASE:-https://bimigrations.com/downloads/estatescanner}"
  HOME_DIR="${ESTATE_SCANNER_HOME:-$HOME/.estate-scanner}"
  VENV="$HOME_DIR/venv"
  OS="$(uname -s)"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$HOME_DIR"

  say() { printf '%s\n' "$*"; }
  die() { printf '\nEstate Scanner could not be installed: %s\n' "$*" >&2; exit 1; }
  have() { command -v "$1" >/dev/null 2>&1; }

  have curl || die "curl is needed and was not found."

  say "Looking up the latest Estate Scanner ..."
  curl -fsSL "$BASE/latest.txt" -o "$TMP/latest.txt" || die "could not reach $BASE/latest.txt (check your internet connection)."
  field() { sed -n "s/^$1=//p" "$TMP/latest.txt" | head -n 1; }
  VERSION="$(field version)"; WHEEL="$(field wheel)"; SHA="$(field sha256)"
  [ -n "$VERSION" ] && [ -n "$WHEEL" ] && [ -n "$SHA" ] || die "the version information at $BASE/latest.txt is incomplete."

  # --- Python 3.11 or newer ------------------------------------------------
  usable() {  # $1 = interpreter: new enough, and can make a venv with pip
    "$1" -c 'import sys, venv, ensurepip; sys.exit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1
  }
  PY=""
  if [ "${ESTATE_SCANNER_FORCE_UV:-}" != "1" ]; then
    for name in python3.13 python3.12 python3.11 python3; do
      p="$(command -v "$name" 2>/dev/null || true)"
      [ -n "$p" ] || continue
      # macOS's /usr/bin/python3 is a stub that pops up the developer tools installer.
      [ "$OS" = "Darwin" ] && [ "$p" = "/usr/bin/python3" ] && continue
      if usable "$p"; then PY="$p"; break; fi
    done
  fi
  if [ -z "$PY" ]; then
    say "No suitable Python found. Installing Python 3.12 into $HOME_DIR/python (no administrator rights needed) ..."
    export UV_UNMANAGED_INSTALL="$HOME_DIR/uv"
    curl -fsSL https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || die "could not download the Python installer (uv) from astral.sh."
    export UV_PYTHON_INSTALL_DIR="$HOME_DIR/python"
    "$HOME_DIR/uv/uv" python install 3.12 >/dev/null 2>&1 || die "could not install Python 3.12."
    PY="$("$HOME_DIR/uv/uv" python find 3.12)"
    usable "$PY" || die "the Python that was installed ($PY) does not work."
  fi
  say "Using Python at $PY"

  # --- private environment -------------------------------------------------
  if [ -x "$VENV/bin/python" ] && ! usable "$VENV/bin/python"; then rm -rf "$VENV"; fi
  [ -x "$VENV/bin/python" ] || "$PY" -m venv "$VENV" || die "could not create a Python environment in $VENV."

  if [ "$(cat "$VENV/.installed-version" 2>/dev/null || true)" != "$VERSION" ]; then
    say "Downloading Estate Scanner $VERSION ..."
    curl -fsSL "$BASE/$WHEEL" -o "$TMP/$WHEEL" || die "could not download $BASE/$WHEEL."
    if have sha256sum; then GOT="$(sha256sum "$TMP/$WHEEL" | cut -d' ' -f1)"; else GOT="$(shasum -a 256 "$TMP/$WHEEL" | cut -d' ' -f1)"; fi
    [ "$GOT" = "$SHA" ] || die "the download is corrupt (checksum mismatch). Try again."
    say "Installing (about a minute the first time) ..."
    "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check --upgrade "$TMP/$WHEEL[ui,domo]" \
      || die "installing the app's libraries failed (see the messages above)."
    printf '%s\n' "$VERSION" > "$VENV/.installed-version"
  else
    say "Estate Scanner $VERSION is already installed."
  fi

  # --- a command for next time ---------------------------------------------
  mkdir -p "$HOME_DIR/bin"
  cat > "$HOME_DIR/bin/estate-scanner" <<LAUNCHER
#!/bin/sh
# Starts Estate Scanner. Re-run the installer to update it.
exec "$VENV/bin/python" -m estate_scanner "\${@:-ui}"
LAUNCHER
  chmod +x "$HOME_DIR/bin/estate-scanner"

  # --- the browser used for the Domo sign-in -------------------------------
  has_chrome=0
  if [ "$OS" = "Darwin" ]; then
    [ -d "/Applications/Google Chrome.app" ] || [ -d "/Applications/Microsoft Edge.app" ] && has_chrome=1
  else
    for b in google-chrome google-chrome-stable microsoft-edge microsoft-edge-stable; do have "$b" && has_chrome=1; done
  fi
  if [ "$has_chrome" = "0" ]; then
    if [ "$OS" = "Darwin" ]; then
      say "Note: install Google Chrome or Microsoft Edge before you sign in to your BI platform."
    else
      say "No Chrome or Edge found; downloading Chromium for the sign-in window (about 200 MB) ..."
      "$VENV/bin/python" -m playwright install chromium >/dev/null 2>&1 \
        || say "Note: could not download Chromium. Install Google Chrome, then run this again."
    fi
  fi

  say ""
  say "Installed. To start it again later run:  $HOME_DIR/bin/estate-scanner"
  say "Your scan data is kept in ~/.estate-scanner (estate.db). Nothing is sent anywhere except to your BI platform."

  [ "${ESTATE_SCANNER_NO_LAUNCH:-}" = "1" ] && exit 0
  if [ "${ESTATE_SCANNER_CHECK:-}" = "1" ]; then exec "$VENV/bin/python" -m estate_scanner ui --check; fi
  say "Starting Estate Scanner ..."
  # Linux desktops rarely have a webview toolkit installed; use the browser there.
  if [ "$OS" = "Linux" ]; then exec "$VENV/bin/python" -m estate_scanner ui --browser; fi
  exec "$VENV/bin/python" -m estate_scanner ui
}

main "$@"
