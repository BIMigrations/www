#!/bin/sh
# BIMControl installer for macOS and Linux.
#
#   curl -fsSL https://bimigrations.com/downloads/bimcontrol/install.sh | sh
#
# Finds Python 3.11 or newer (or installs one for you, with no administrator rights), installs
# BIMControl into a private environment, and starts it. Run it again any time: it updates to the
# latest version. Nothing outside ~/.bimcontrol is changed.
#
# Run as a file it can also install without the website:
#   sh install.sh             from the folder a zip unpacks to (beside latest.txt and its wheel):
#                             installs that wheel and fetches nothing from bimigrations.com
#   sh packaging/install.sh   from a checkout of the repository: installs that checkout
# Under `curl | sh` there is no file beside it, so customers never take either path.
#
# Settings (all optional, mostly for testing and support):
#   BIMCONTROL_SOURCE         install from this checkout (found on its own when run from one)
#   BIMCONTROL_BASE           where latest.txt and the wheel are downloaded from
#   BIMCONTROL_HOME           install folder (default ~/.bimcontrol; the same folder holds the app's data)
#   BIMCONTROL_CHECK=1        install, run the self-test (`ui --check`), do not open the app
#   BIMCONTROL_FORCE_UV=1     ignore any Python already on the machine
#   BIMCONTROL_UV_INSTALLER   where the Python installer (uv) is fetched from if one is needed
#   BIMCONTROL_NO_LAUNCH=1    install only

# Everything lives in main() so a truncated download runs nothing at all.
main() {
  set -eu
  BASE="${BIMCONTROL_BASE:-https://bimigrations.com/downloads/bimcontrol}"
  HOME_DIR="${BIMCONTROL_HOME:-$HOME/.bimcontrol}"
  VENV="$HOME_DIR/venv"
  UV_INSTALLER="${BIMCONTROL_UV_INSTALLER:-https://astral.sh/uv/install.sh}"
  EXTRAS="ui,powerbi,domo,warehouse"   # what packaging/start.py installs too
  OS="$(uname -s)"
  TMP="$(mktemp -d)"
  mkdir -p "$HOME_DIR"
  LOG="$HOME_DIR/install.log"   # everything the steps print, kept for support; the last run only
  : > "$LOG"

  say() { printf '%s\n' "$*"; }
  step() { printf '\n== %s\n' "$*"; }
  have() { command -v "$1" >/dev/null 2>&1; }
  cleanup() { rm -rf "$TMP"; }
  trap cleanup EXIT
  die() { printf '\nBIMControl cannot be installed: %s\n\n' "$*" >&2; exit 1; }
  # run "what is happening" command args...   Output goes to the log; on failure its tail is shown.
  run() {
    msg="$1"; shift
    say "   ... $msg"
    printf '\n>>> %s\n' "$msg" >>"$LOG"
    if "$@" </dev/null >>"$LOG" 2>&1; then return 0; fi
    printf '\n--- last lines of %s ---\n' "$LOG" >&2
    tail -n 15 "$LOG" >&2
    return 1
  }

  say ""
  say "BIMControl  (BI Migrations)"
  say "Migrates dashboards, data and logic to Power BI / Fabric, and checks the numbers match."
  have curl || die "curl is needed and was not found."

  # --- where the app comes from ----------------------------------------------------
  # A checkout: `sh packaging/install.sh` finds the repository around itself ($0 is `sh` under
  # `curl | sh`, so that never matches); BIMCONTROL_SOURCE names one explicitly.
  SRC="${BIMCONTROL_SOURCE:-}"
  FOLDER=""
  case "$0" in
    *install.sh)
      d="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
      if [ -z "$SRC" ] && [ -n "$d" ] && [ -f "$d/start.py" ] && [ -f "$d/../pyproject.toml" ] && [ -d "$d/../src/bimcontrol" ]; then SRC="$d/.."; fi
      # A folder: the zip a customer is sent unpacks to install.sh beside latest.txt and its wheel.
      if [ -z "$SRC" ] && [ -n "$d" ] && [ -f "$d/latest.txt" ]; then
        w="$(sed -n 's/^wheel=//p' "$d/latest.txt" | head -n 1)"
        if [ -n "$w" ] && [ -f "$d/$w" ]; then FOLDER="$d"; fi
      fi ;;
  esac
  if [ -n "$SRC" ]; then
    { [ -f "$SRC/pyproject.toml" ] && [ -d "$SRC/src/bimcontrol" ]; } || die "BIMCONTROL_SOURCE is not a checkout of BIMControl: $SRC"
    SRC="$(cd "$SRC" && pwd)"
  fi

  field() { sed -n "s/^$1=//p" "$TMP/latest.txt" | tr -d '\r' | head -n 1; }
  WHEEL=""; SHA=""
  if [ -n "$SRC" ]; then
    VERSION="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$SRC/pyproject.toml" | head -n 1)"
    say "Installing from the checkout $SRC"
  elif [ -n "$FOLDER" ]; then
    cp "$FOLDER/latest.txt" "$TMP/latest.txt"
    VERSION="$(field version)"; WHEEL="$(field wheel)"; SHA="$(field sha256)"
    [ -n "$VERSION" ] && [ -n "$SHA" ] || die "The version information in $FOLDER/latest.txt is incomplete."
    say "Installing from the folder $FOLDER (version ${VERSION%%+*})"
  else
    curl -fsSL "$BASE/latest.txt" -o "$TMP/latest.txt" || die "Could not reach $BASE/latest.txt. Check your internet connection."
    VERSION="$(field version)"; WHEEL="$(field wheel)"; SHA="$(field sha256)"
    [ -n "$VERSION" ] && [ -n "$WHEEL" ] && [ -n "$SHA" ] || die "The version information at $BASE/latest.txt is incomplete."
    say "Latest version: ${VERSION%%+*}"
  fi

  # --- Python 3.11 or newer --------------------------------------------------------
  step "Python"
  usable() {  # $1 = interpreter: new enough, and can make a venv with pip
    "$1" -c 'import sys, venv, ensurepip; sys.exit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1
  }
  pyver() { "$1" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])'; }
  PY=""
  if [ "${BIMCONTROL_FORCE_UV:-}" != "1" ]; then
    for name in python3.13 python3.12 python3.11 python3; do
      p="$(command -v "$name" 2>/dev/null || true)"
      [ -n "$p" ] || continue
      # macOS's /usr/bin/python3 is a stub that pops up the developer tools installer.
      [ "$OS" = "Darwin" ] && [ "$p" = "/usr/bin/python3" ] && continue
      if usable "$p"; then PY="$p"; break; fi
    done
  fi
  if [ -n "$PY" ]; then
    say "   Python $(pyver "$PY") found at $PY"
  else
    say "   There is no Python 3.11 or newer here, so one is being set up inside $HOME_DIR."
    say "   Nothing else on this computer is changed."
    get_python() {
      curl -fsSL "$UV_INSTALLER" -o "$TMP/uv-install.sh" || return 1
      UV_UNMANAGED_INSTALL="$HOME_DIR/uv" sh "$TMP/uv-install.sh" || return 1
      export UV_PYTHON_INSTALL_DIR="$HOME_DIR/python"
      "$HOME_DIR/uv/uv" python install 3.12 || return 1
      "$HOME_DIR/uv/uv" python find 3.12 >"$TMP/py"
    }
    run "Installing Python 3.12 (a few minutes, no administrator rights needed)" get_python || die "Could not install Python 3.12. The details are in $LOG."
    PY="$(cat "$TMP/py")"
    usable "$PY" || die "The Python that was installed ($PY) does not work."
    say "   Python $(pyver "$PY") installed in $HOME_DIR/python"
  fi

  # --- BIMControl itself -----------------------------------------------------------
  step "BIMControl"
  if [ -x "$VENV/bin/python" ] && ! usable "$VENV/bin/python"; then rm -rf "$VENV"; fi
  if [ ! -x "$VENV/bin/python" ]; then
    run "Creating a private environment in $VENV" "$PY" -m venv "$VENV" || die "Could not create a Python environment in $VENV. The details are in $LOG."
  fi
  # start.py writes .installed-wheel (the wheel's file name); this installer writes .installed-version.
  # Running one after the other is harmless: the other's stamp simply does not match and pip reinstalls.
  STAMP="$VERSION|$EXTRAS"
  if [ -n "$SRC" ]; then
    # A checkout changes without its version changing, so it is always reinstalled.
    run "Installing BIMControl from the checkout (a few minutes the first time)" \
      "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check --upgrade "$SRC[$EXTRAS]" \
      || die "Installing from the checkout failed. The details are in $LOG."
    printf '%s\n' "checkout|$EXTRAS" >"$VENV/.installed-version"
  elif [ "$(cat "$VENV/.installed-version" 2>/dev/null || true)" != "$STAMP" ]; then
    if [ -n "$FOLDER" ]; then
      cp "$FOLDER/$WHEEL" "$TMP/$WHEEL" || die "Could not read $FOLDER/$WHEEL."
    else
      run "Downloading BIMControl ${VERSION%%+*}" curl -fsSL "$BASE/$WHEEL" -o "$TMP/$WHEEL" || die "Could not download $BASE/$WHEEL."
    fi
    if have sha256sum; then GOT="$(sha256sum "$TMP/$WHEEL" | cut -d' ' -f1)"; else GOT="$(shasum -a 256 "$TMP/$WHEEL" | cut -d' ' -f1)"; fi
    [ "$GOT" = "$SHA" ] || die "The file is corrupt (checksum mismatch). Download it again."
    say "   Checksum verified"
    run "Installing BIMControl ${VERSION%%+*} and its libraries (a few minutes the first time)" \
      "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check --upgrade "$TMP/$WHEEL[$EXTRAS]" \
      || die "Installing the app's libraries failed. The details are in $LOG."
    printf '%s\n' "$STAMP" >"$VENV/.installed-version"
  else
    say "   BIMControl ${VERSION%%+*} is already installed"
  fi

  # A command for next time.
  mkdir -p "$HOME_DIR/bin"
  cat >"$HOME_DIR/bin/bimcontrol" <<LAUNCHER
#!/bin/sh
# Starts BIMControl. Re-run the installer to update it.
if [ \$# -eq 0 ]; then set -- ui; fi
exec "$VENV/bin/python" -m bimcontrol "\$@"
LAUNCHER
  chmod +x "$HOME_DIR/bin/bimcontrol"

  printf '\nAll set. Next time, run  %s/bin/bimcontrol\n' "$HOME_DIR"
  say "Your migrations are kept in $HOME_DIR, on this computer."
  say "Installing downloaded Python packages from PyPI (and Python from astral.sh if you had none)."
  say "Running BIMControl contacts only your BI platforms, your warehouse and the converter service."
  say "BIMControl reads the scan EstateScanner made (~/.estate-scanner/estate.db)."

  [ "${BIMCONTROL_NO_LAUNCH:-}" = "1" ] && exit 0
  if [ "${BIMCONTROL_CHECK:-}" = "1" ]; then
    printf '\nRunning the self-test ...\n\n'
    cleanup; trap - EXIT
    exec "$VENV/bin/python" -m bimcontrol ui --check
  fi
  printf '\nStarting BIMControl ...\n\n'
  cleanup; trap - EXIT
  exec "$VENV/bin/python" -m bimcontrol ui
}

main "$@"
