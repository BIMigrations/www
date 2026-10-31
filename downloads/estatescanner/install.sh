#!/bin/sh
# Estate Scanner installer for macOS and Linux.
#
#   curl -fsSL https://bimigrations.com/downloads/estatescanner/install.sh | sh
#
# Walks you through it in four steps: which BI platform you will scan, Python
# (found, or installed for you with no administrator rights), Estate Scanner
# itself, and the Mac app. Then it starts the app. Run it again any time: it
# updates to the latest version, and offers the platforms you chose last time.
#
# Run as a file it can also install without the website:
#   sh install.sh         from the folder a zip unpacks to (beside latest.txt and its wheel):
#                         installs that wheel, and fetches nothing from bimigrations.com
#   sh packaging/install.sh   from a checkout of the repository: installs that checkout, so a
#                         branch can be tried with nothing to build or serve
# Under `curl | sh` there is no file beside it, so customers never take either path.
#
# Settings (all optional, mostly for testing and support):
#   ESTATE_SCANNER_SOURCE     install from this checkout (found on its own when run from one)
#   ESTATE_SCANNER_PLATFORMS  platforms to install without asking: all, or keys like domo,powerbi
#   ESTATE_SCANNER_BASE       where latest.txt (version, platforms) and the wheel are downloaded from
#   ESTATE_SCANNER_HOME       install folder (default ~/.estate-scanner)
#   ESTATE_SCANNER_CHECK=1    install, run the self-test, do not open the app
#   ESTATE_SCANNER_FORCE_UV=1 ignore any Python already on the machine
#   ESTATE_SCANNER_UV_INSTALLER  where the Python installer (uv) is fetched from if one is needed
#   ESTATE_SCANNER_NO_LAUNCH=1 install only
#   ESTATE_SCANNER_APPS_DIR   macOS: where "Estate Scanner.app" is created (default ~/Applications)
#   ESTATE_SCANNER_NO_APP=1   macOS: skip creating the app
#   ESTATE_SCANNER_PLAIN=1    no colour, spinner or prompts (also when NO_COLOR is set or output is not a terminal)

# Everything lives in main() so a truncated download runs nothing at all.
main() {
  set -eu
  BASE="${ESTATE_SCANNER_BASE:-https://bimigrations.com/downloads/estatescanner}"
  HOME_DIR="${ESTATE_SCANNER_HOME:-$HOME/.estate-scanner}"
  VENV="$HOME_DIR/venv"
  APPS_DIR="${ESTATE_SCANNER_APPS_DIR:-$HOME/Applications}"
  UV_INSTALLER="${ESTATE_SCANNER_UV_INSTALLER:-https://astral.sh/uv/install.sh}"
  OS="$(uname -s)"
  TMP="$(mktemp -d)"
  mkdir -p "$HOME_DIR"
  LOG="$HOME_DIR/install.log"   # everything the steps print, kept for support; the last run only
  : > "$LOG"
  STTY_SAVED=""

  # --- the terminal ------------------------------------------------------------
  # FANCY: colour, spinner and glyphs. ASK: we can also read keys. Under `curl | sh`
  # stdin is the script itself, so keys come from /dev/tty, never from stdin.
  FANCY=0; ASK=0
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -z "${ESTATE_SCANNER_PLAIN:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then FANCY=1; fi
  if [ "$FANCY" = 1 ] && ( : </dev/tty >/dev/tty ) 2>/dev/null && stty -g </dev/tty >/dev/null 2>&1; then ASK=1; fi
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) UTF=1 ;; *) UTF=0 ;; esac

  ESC=""; RESET=""; BOLD=""; DIM=""; TEAL=""; AMBER=""; RED=""; CLR=""; HIDE=""; SHOW=""
  if [ "$FANCY" = 1 ]; then
    ESC="$(printf '\033')"
    RESET="${ESC}[0m"; BOLD="${ESC}[1m"; DIM="${ESC}[2m"
    TEAL="${ESC}[38;5;29m"; AMBER="${ESC}[38;5;166m"; RED="${ESC}[38;5;160m"
    CLR="${ESC}[2K"; HIDE="${ESC}[?25l"; SHOW="${ESC}[?25h"
  fi
  if [ "$FANCY" = 1 ] && [ "$UTF" = 1 ]; then
    G_OK="✔"; G_BAD="✘"; G_WARN="!"; G_ON="◉"; G_OFF="◯"; G_SOON="◌"; G_CUR="❯"; G_RULE="─"; G_MARK="◆"; G_DOT="·"
    SPIN="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"; SPINN=10
  else
    G_OK="+"; G_BAD="x"; G_WARN="!"; G_ON="[x]"; G_OFF="[ ]"; G_SOON="[-]"; G_CUR=">"; G_RULE="-"; G_MARK="*"; G_DOT="-"
    SPIN='| / - \'; SPINN=4
  fi
  RULE=""; n=0
  while [ "$n" -lt 52 ]; do RULE="$RULE$G_RULE"; n=$((n + 1)); done

  say() { printf '%s\n' "$*"; }
  ok() { printf '   %s%s%s %s\n' "$TEAL" "$G_OK" "$RESET" "$*"; }
  warn() { printf '   %s%s%s %s\n' "$AMBER" "$G_WARN" "$RESET" "$*"; }
  note() { printf '     %s%s%s\n' "$DIM" "$*" "$RESET"; }
  step() { printf '\n   %s%s%s  %s%s%s\n\n' "$DIM" "$1" "$RESET" "$BOLD" "$2" "$RESET"; }
  have() { command -v "$1" >/dev/null 2>&1; }
  tilde() { case "$1" in "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }

  # Put the terminal back as we found it and delete our scratch folder. Safe to call twice.
  finish_terminal() {
    if [ -n "$STTY_SAVED" ]; then stty "$STTY_SAVED" </dev/tty 2>/dev/null || true; STTY_SAVED=""; fi
    [ "$FANCY" = 1 ] && printf '%s' "$SHOW" || true
  }
  cleanup() { finish_terminal; rm -rf "$TMP"; }
  trap cleanup EXIT
  trap 'printf "\n\n   Cancelled.\n\n"; exit 130' INT TERM HUP

  fail_tail() {  # what the failed step last printed, so the reason is on screen and not only in a file
    if [ -s "$LOG" ]; then
      tail -n 8 "$LOG" | grep -v -e '^>>> ' -e '^$' | cut -c1-72 | while IFS= read -r l; do note "$l"; done
    fi
  }
  # die "what went wrong"      a problem the message explains in full
  # die_run "what went wrong"  a step that ran a command: its last output is shown, and where the rest is
  die() {
    printf '\n   %s%s%s %s\n\n' "$RED" "$G_BAD" "$RESET" "$*" >&2
    exit 1
  }
  die_run() {
    printf '\n   %s%s%s %s\n\n' "$RED" "$G_BAD" "$RESET" "$*" >&2
    fail_tail >&2
    printf '\n     %sThe full details are in %s%s\n\n' "$DIM" "$(tilde "$LOG")" "$RESET" >&2
    exit 1
  }

  # run "what is happening" command args...
  # Quiet: the command's output goes to the log, and on a terminal a spinner shows it is working.
  run() {
    msg="$1"; shift
    printf '\n>>> %s\n' "$msg" >>"$LOG"
    if [ "$FANCY" = 1 ]; then
      "$@" >>"$LOG" 2>&1 &
      rpid=$!
      n=0
      printf '%s' "$HIDE"
      while kill -0 "$rpid" 2>/dev/null; do
        frame="$(printf '%s' "$SPIN" | cut -d' ' -f$((n % SPINN + 1)))"
        printf '\r%s   %s%s%s %s' "$CLR" "$TEAL" "$frame" "$RESET" "$msg"
        n=$((n + 1))
        sleep 0.1
      done
      if wait "$rpid"; then rc=0; else rc=$?; fi
      printf '\r%s%s' "$CLR" "$SHOW"
    else
      printf '   ... %s\n' "$msg"
      if "$@" </dev/null >>"$LOG" 2>&1; then rc=0; else rc=$?; fi
    fi
    return "$rc"
  }

  # --- hello ---------------------------------------------------------------------
  printf '\n   %s%s%s  %sEstate Scanner%s   %sBI / MIGRATIONS%s\n' "$AMBER" "$G_MARK" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET"
  printf '      %sInventory your BI estate. Everything stays on this computer.%s\n' "$DIM" "$RESET"
  printf '   %s%s%s\n' "$DIM" "$RULE" "$RESET"

  have curl || die "curl is needed and was not found."

  # A checkout: `sh packaging/install.sh` finds the repository around itself ($0 is `sh` under
  # `curl | sh`, so that never matches); ESTATE_SCANNER_SOURCE names one explicitly.
  SRC="${ESTATE_SCANNER_SOURCE:-}"
  case "$0" in
    *install.sh)
      d="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
      if [ -z "$SRC" ] && [ -n "$d" ] && [ -f "$d/platforms.txt" ] && [ -f "$d/../pyproject.toml" ] && [ -d "$d/../src/estate_scanner" ]; then SRC="$d/.."; fi ;;
  esac
  if [ -n "$SRC" ]; then
    { [ -f "$SRC/pyproject.toml" ] && [ -f "$SRC/packaging/platforms.txt" ]; } || die "ESTATE_SCANNER_SOURCE is not a checkout of Estate Scanner: $SRC"
    SRC="$(cd "$SRC" && pwd)"
  fi

  # A folder: the zip a customer is sent unpacks to install.sh beside latest.txt and the wheel it
  # names. Then nothing is fetched from bimigrations.com (Python and the app's libraries still
  # come from their own sources). Under `curl | sh` $0 is `sh`, so a customer cannot land here.
  FOLDER=""
  if [ -z "$SRC" ]; then
    case "$0" in
      *install.sh)
        d="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
        if [ -n "$d" ] && [ -f "$d/latest.txt" ]; then
          w="$(sed -n 's/^wheel=//p' "$d/latest.txt" | head -n 1)"
          if [ -n "$w" ] && [ -f "$d/$w" ]; then FOLDER="$d"; fi
        fi ;;
    esac
  fi

  # The platform list is `platform=` lines in latest.txt itself, not a file of its own: the
  # website caches every file for ten minutes, so a separate list could belong to another
  # release than the wheel latest.txt names.
  platforms_from_latest() {
    sed -n 's/^platform=//p' "$TMP/latest.txt" | tr -d '\r' >"$TMP/platforms.txt"
    # A latest.txt from before the list existed: Domo and Power BI are what it could install.
    [ -s "$TMP/platforms.txt" ] \
      || printf '%s\n' 'domo|Domo|domo|available|chrome' 'powerbi|Power BI|powerbi|available|system' >"$TMP/platforms.txt"
  }
  fetch_manifest() {
    curl -fsSL "$BASE/latest.txt" -o "$TMP/latest.txt" || return 1
    platforms_from_latest
  }
  field() { sed -n "s/^$1=//p" "$TMP/latest.txt" | head -n 1; }
  printf '\n'
  if [ -n "$SRC" ]; then
    cp "$SRC/packaging/platforms.txt" "$TMP/platforms.txt"
    VERSION="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$SRC/pyproject.toml" | head -n 1)"
    rev=""
    if have git && git -C "$SRC" rev-parse --git-dir >/dev/null 2>&1; then
      rev="$(git -C "$SRC" rev-parse --abbrev-ref HEAD 2>/dev/null) $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)"
      [ -z "$(git -C "$SRC" status --porcelain 2>/dev/null)" ] || rev="$rev, modified"
      rev=" ${DIM}($rev)${RESET}"
    fi
    ok "Installing from this checkout$rev"
    note "$(tilde "$SRC")"
  elif [ -n "$FOLDER" ]; then
    cp "$FOLDER/latest.txt" "$TMP/latest.txt"
    platforms_from_latest
    VERSION="$(field version)"; WHEEL="$(field wheel)"; SHA="$(field sha256)"
    [ -n "$VERSION" ] && [ -n "$SHA" ] || die "The version information in $(tilde "$FOLDER")/latest.txt is incomplete."
    ok "Installing from this folder ${DIM}(version ${VERSION%%+*})${RESET}"
    note "$(tilde "$FOLDER")"
  else
    run "Checking for the latest version" fetch_manifest || die_run "Could not reach $BASE/latest.txt. Check your internet connection."
    VERSION="$(field version)"; WHEEL="$(field wheel)"; SHA="$(field sha256)"
    [ -n "$VERSION" ] && [ -n "$WHEEL" ] && [ -n "$SHA" ] || die "The version information at $BASE/latest.txt is incomplete."
    ok "Latest version is ${VERSION%%+*}"
  fi

  # =============================================================================
  # Step 1: platforms
  # =============================================================================
  # packaging/platforms.txt is the whole menu (build.py puts it in latest.txt), so a new
  # platform needs a line there and nothing here.
  tr -d '\r' <"$TMP/platforms.txt" | grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' >"$TMP/rows" || true
  NROWS="$(wc -l <"$TMP/rows" | tr -d ' ')"
  fld() { sed -n "$1p" "$TMP/rows" | cut -d'|' -f"$2"; }
  AVAIL=""; i=1
  while [ "$i" -le "$NROWS" ]; do
    [ "$(fld "$i" 4)" = "available" ] && AVAIL="$AVAIL $i"
    i=$((i + 1))
  done
  [ -n "$AVAIL" ] || die "$BASE/latest.txt offers no platform that can be installed yet."
  index_of() {  # key -> row number, or nothing
    i=1
    while [ "$i" -le "$NROWS" ]; do
      if [ "$(fld "$i" 1)" = "$1" ]; then printf '%s' "$i"; return 0; fi
      i=$((i + 1))
    done
  }
  is_sel() { case " $SEL " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
  toggle() { if is_sel "$1"; then SEL="$(printf ' %s ' "$SEL" | sed "s/ $1 / /")"; else SEL="$SEL $1"; fi; }
  neighbour() {  # direction (1 or -1) from row $2 to the next one that can be picked, wrapping round
    set -- "$1" "$2" $AVAIL
    dir="$1"; cur="$2"; shift 2
    cnt=$#; pos=1
    for a in "$@"; do [ "$a" = "$cur" ] && break; pos=$((pos + 1)); done
    pos=$(((pos - 1 + dir + cnt) % cnt + 1))
    eval "printf '%s' \"\${$pos}\""
  }

  SEL=""
  if [ -s "$HOME_DIR/platforms" ]; then   # last time's choice, so an update is one keypress
    for k in $(tr ',' ' ' <"$HOME_DIR/platforms"); do
      j="$(index_of "$k")"
      if [ -n "$j" ] && [ "$(fld "$j" 4)" = "available" ]; then SEL="$SEL $j"; fi
    done
  fi

  hint_for() { case "$1" in chrome) printf 'signs in with Chrome or Edge' ;; system) printf 'signs in with your browser' ;; esac; }
  draw_row() {
    name="$(fld "$1" 2)"
    if [ "$(fld "$1" 4)" != "available" ]; then
      printf '%s     %s%s %-16s coming soon%s\n' "$CLR" "$DIM" "$G_SOON" "$name" "$RESET"
      return
    fi
    if is_sel "$1"; then mark="${TEAL}${G_ON}${RESET}"; else mark="${DIM}${G_OFF}${RESET}"; fi
    if [ "$1" = "$CUR" ]; then pointer="${AMBER}${G_CUR}${RESET}"; style="$BOLD"; else pointer=" "; style=""; fi
    printf '%s   %s %s %s%-16s%s %s%s%s\n' "$CLR" "$pointer" "$mark" "$style" "$name" "$RESET" "$DIM" "$(hint_for "$(fld "$1" 5)")" "$RESET"
  }
  draw_rows() {
    i=1
    while [ "$i" -le "$NROWS" ]; do draw_row "$i"; i=$((i + 1)); done
    printf '%s   %s%s%s\n' "$CLR" "$AMBER" "$MSG" "$RESET"
  }
  readkey() {
    b="$(dd bs=1 count=1 2>/dev/null </dev/tty | od -An -tx1 | tr -d ' \n')"
    case "$b" in
      1b)  # an arrow key is ESC [ A or ESC O A; a lone Esc has nothing after it and times out
        stty min 0 time 1 </dev/tty
        rest="$(dd bs=1 count=2 2>/dev/null </dev/tty | od -An -tx1 | tr -d ' \n')"
        stty min 1 time 0 </dev/tty
        case "$rest" in 5b41 | 4f41) echo up ;; 5b42 | 4f42) echo down ;; *) echo other ;; esac ;;
      6b) echo up ;;
      6a) echo down ;;
      20) echo space ;;
      0a | 0d) echo enter ;;
      61) echo all ;;
      71 | 04 | "") echo quit ;;
      *) echo other ;;
    esac
  }

  step "Step 1 of 4" "Choose your platform"
  if [ -n "${ESTATE_SCANNER_PLATFORMS:-}" ]; then
    SEL=""
    if [ "$ESTATE_SCANNER_PLATFORMS" = "all" ]; then SEL="$AVAIL"; else
      for k in $(printf '%s' "$ESTATE_SCANNER_PLATFORMS" | tr ',' ' '); do
        j="$(index_of "$k")"
        [ -n "$j" ] || die "ESTATE_SCANNER_PLATFORMS names '$k', which is not a platform. Choose from: $(cut -d'|' -f1 "$TMP/rows" | tr '\n' ' ')"
        [ "$(fld "$j" 4)" = "available" ] || die "$(fld "$j" 2) is not available yet."
        is_sel "$j" || SEL="$SEL $j"
      done
    fi
  elif [ "$ASK" = 1 ]; then
    set -- $AVAIL; CUR="$1"; MSG=""
    if [ "$UTF" = 1 ]; then keys="↑ ↓ move"; else keys="up/down move"; fi
    printf '   Which BI platforms will you scan?\n'
    printf '   %s%s   space select   a all   enter continue%s\n\n' "$DIM" "$keys" "$RESET"
    STTY_SAVED="$(stty -g </dev/tty)"
    stty -icanon -echo min 1 time 0 </dev/tty
    printf '%s' "$HIDE"
    draw_rows
    while :; do
      key="$(readkey)"
      case "$key" in
        up) CUR="$(neighbour -1 "$CUR")" ;;
        down) CUR="$(neighbour 1 "$CUR")" ;;
        space) toggle "$CUR" ;;
        all) if [ "$(printf '%s' "$SEL" | wc -w | tr -d ' ')" -ge "$(printf '%s' "$AVAIL" | wc -w | tr -d ' ')" ]; then SEL=""; else SEL="$AVAIL"; fi ;;
        enter) if [ -z "$(printf '%s' "$SEL" | tr -d ' ')" ]; then SEL=" $CUR"; fi; break ;;
        quit) printf '\n\n   Cancelled.\n\n'; exit 130 ;;
      esac
      printf '\033[%sA' "$((NROWS + 1))"
      draw_rows
    done
    finish_terminal
    # Fold the menu (question, hint, blank, the rows, the message line) into the one-line
    # summary below, so the screen reads as a list of what was done.
    printf '\033[%sA\033[J' "$((NROWS + 4))"
  elif [ -z "$(printf '%s' "$SEL" | tr -d ' ')" ]; then
    SEL="$AVAIL"   # nobody to ask and nothing chosen before: everything that is available
  fi

  CHOSEN_KEYS=""; CHOSEN_NAMES=""; EXTRAS="ui"; NEED_CHROME=0
  i=1
  while [ "$i" -le "$NROWS" ]; do
    if is_sel "$i"; then
      CHOSEN_KEYS="${CHOSEN_KEYS:+$CHOSEN_KEYS,}$(fld "$i" 1)"
      CHOSEN_NAMES="${CHOSEN_NAMES:+$CHOSEN_NAMES, }$(fld "$i" 2)"
      extra="$(fld "$i" 3)"
      case ",$EXTRAS," in *",$extra,"*) ;; *) [ -z "$extra" ] || EXTRAS="$EXTRAS,$extra" ;; esac
      [ "$(fld "$i" 5)" = "chrome" ] && NEED_CHROME=1
    fi
    i=$((i + 1))
  done
  [ -n "$CHOSEN_KEYS" ] || die "No platform was chosen."
  printf '%s\n' "$CHOSEN_KEYS" >"$HOME_DIR/platforms"
  ok "Platforms: $CHOSEN_NAMES"

  # =============================================================================
  # Step 2: Python 3.11 or newer
  # =============================================================================
  step "Step 2 of 4" "Python"
  usable() {  # $1 = interpreter: new enough, and can make a venv with pip
    "$1" -c 'import sys, venv, ensurepip; sys.exit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1
  }
  pyver() { "$1" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])'; }
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
  if [ -n "$PY" ]; then
    ok "Python $(pyver "$PY") found ${DIM}at $(tilde "$PY")${RESET}"
  else
    if [ "$OS" = "Darwin" ]; then here="this Mac"; else here="this computer"; fi
    note "There is no Python 3.11 or newer on $here, so one is being set up for you."
    note "It is kept inside $(tilde "$HOME_DIR"); nothing else on $here is changed."
    get_python() {
      curl -fsSL "$UV_INSTALLER" -o "$TMP/uv-install.sh" || return 1
      UV_UNMANAGED_INSTALL="$HOME_DIR/uv" sh "$TMP/uv-install.sh" || return 1
      export UV_PYTHON_INSTALL_DIR="$HOME_DIR/python"
      "$HOME_DIR/uv/uv" python install 3.12 || return 1
      "$HOME_DIR/uv/uv" python find 3.12 >"$TMP/py"
    }
    run "Installing Python 3.12 (a few minutes, no administrator rights needed)" get_python || die_run "Could not install Python 3.12."
    PY="$(cat "$TMP/py")"
    usable "$PY" || die "The Python that was installed ($(tilde "$PY")) does not work."
    ok "Python $(pyver "$PY") installed ${DIM}in $(tilde "$HOME_DIR/python")${RESET}"
  fi

  # =============================================================================
  # Step 3: Estate Scanner
  # =============================================================================
  step "Step 3 of 4" "Install Estate Scanner"
  if [ -x "$VENV/bin/python" ] && ! usable "$VENV/bin/python"; then rm -rf "$VENV"; fi
  if [ ! -x "$VENV/bin/python" ]; then
    run "Creating a private environment" "$PY" -m venv "$VENV" || die_run "Could not create a Python environment in $(tilde "$VENV")."
  fi
  # The extras are part of the stamp: choosing another platform later must install its libraries.
  STAMP="$VERSION|$EXTRAS"
  if [ -n "$SRC" ]; then
    # A checkout changes without its version changing, so it is always reinstalled, and its
    # stamp can never match a published version's.
    run "Installing Estate Scanner for $CHOSEN_NAMES (about a minute the first time)" \
      "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check --upgrade "$SRC[$EXTRAS]" \
      || die_run "Installing from the checkout failed."
    printf '%s\n' "checkout|$EXTRAS" >"$VENV/.installed-version"
    ok "Installed Estate Scanner ${VERSION%%+*} ${DIM}${G_DOT} from this checkout${RESET}"
  elif [ "$(cat "$VENV/.installed-version" 2>/dev/null || true)" != "$STAMP" ]; then
    if [ -n "$FOLDER" ]; then
      cp "$FOLDER/$WHEEL" "$TMP/$WHEEL" || die "Could not read $(tilde "$FOLDER")/$WHEEL."
      got_word="Checked"
    else
      run "Downloading Estate Scanner ${VERSION%%+*}" curl -fsSL "$BASE/$WHEEL" -o "$TMP/$WHEEL" || die_run "Could not download $BASE/$WHEEL."
      got_word="Downloaded"
    fi
    if have sha256sum; then GOT="$(sha256sum "$TMP/$WHEEL" | cut -d' ' -f1)"; else GOT="$(shasum -a 256 "$TMP/$WHEEL" | cut -d' ' -f1)"; fi
    [ "$GOT" = "$SHA" ] || die "The file is corrupt (checksum mismatch). Download it again."
    ok "$got_word ${VERSION%%+*} ${DIM}${G_DOT} checksum verified${RESET}"
    run "Installing Estate Scanner for $CHOSEN_NAMES (about a minute the first time)" \
      "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check --upgrade "$TMP/$WHEEL[$EXTRAS]" \
      || die_run "Installing the app's libraries failed."
    printf '%s\n' "$STAMP" >"$VENV/.installed-version"
    ok "Installed Estate Scanner ${VERSION%%+*}"
  else
    ok "Estate Scanner ${VERSION%%+*} is already installed"
  fi

  # A command for next time.
  mkdir -p "$HOME_DIR/bin"
  cat >"$HOME_DIR/bin/estate-scanner" <<LAUNCHER
#!/bin/sh
# Starts Estate Scanner. Re-run the installer to update it.
exec "$VENV/bin/python" -m estate_scanner "\${@:-ui}"
LAUNCHER
  chmod +x "$HOME_DIR/bin/estate-scanner"

  # =============================================================================
  # Step 4: the app, and the sign-in browser
  # =============================================================================
  step "Step 4 of 4" "Finish setting up"
  APP=""
  if [ "$OS" = "Darwin" ] && [ "${ESTATE_SCANNER_NO_APP:-}" != "1" ]; then
    # Created here from the Python just installed, never downloaded: a file a browser
    # fetches carries macOS's quarantine flag and, being unsigned, is then refused,
    # whereas one assembled by this script is an ordinary local file. It is a thin view
    # over the environment above; see src/estate_scanner/macos_app.py.
    if run "Adding the Estate Scanner app to $(tilde "$APPS_DIR")" "$VENV/bin/python" -m estate_scanner mac-app --dest "$APPS_DIR"; then
      APP="$APPS_DIR/Estate Scanner.app"
      ok "Estate Scanner app added ${DIM}in $(tilde "$APPS_DIR")${RESET}"
    else
      warn "The Estate Scanner app could not be created. It still starts with $(tilde "$HOME_DIR/bin/estate-scanner")"
      fail_tail
    fi
  fi
  if [ "$NEED_CHROME" = 1 ]; then
    has_chrome=0
    if [ "$OS" = "Darwin" ]; then
      for b in "/Applications/Google Chrome.app" "/Applications/Microsoft Edge.app" "$HOME/Applications/Google Chrome.app" "$HOME/Applications/Microsoft Edge.app"; do
        [ -d "$b" ] && has_chrome=1
      done
    else
      for b in google-chrome google-chrome-stable microsoft-edge microsoft-edge-stable; do have "$b" && has_chrome=1; done
    fi
    if [ "$has_chrome" = 1 ]; then
      ok "Chrome or Edge found ${DIM}for signing in${RESET}"
    elif [ "$OS" = "Darwin" ]; then
      warn "Install Google Chrome or Microsoft Edge before you sign in to your BI platform."
    elif run "Downloading Chromium for the sign-in window (about 200 MB)" "$VENV/bin/python" -m playwright install chromium; then
      ok "Chromium ready ${DIM}for signing in${RESET}"
    else
      warn "Could not download Chromium. Install Google Chrome, then run this again."
    fi
  fi

  printf '\n   %s%s%s\n\n' "$DIM" "$RULE" "$RESET"
  printf '   %s%s%s  %sAll set.%s\n' "$TEAL" "$G_OK" "$RESET" "$BOLD" "$RESET"
  if [ -n "$APP" ]; then
    note "Next time, open Estate Scanner from Launchpad or Spotlight."
    note "The app is in $(tilde "$APPS_DIR")."
  else
    note "Next time, run  $(tilde "$HOME_DIR/bin/estate-scanner")"
  fi
  note "Run this installer again to update, or to add another platform."
  note "Your scans are kept in $(tilde "$HOME_DIR"), on this computer."
  note "Installing downloaded Python packages from PyPI (and Python from astral.sh if you had none)."
  note "Running Estate Scanner contacts only your BI platform."

  [ "${ESTATE_SCANNER_NO_LAUNCH:-}" = "1" ] && exit 0
  if [ "${ESTATE_SCANNER_CHECK:-}" = "1" ]; then
    printf '\n   Running the self-test ...\n\n'
    cleanup; trap - EXIT
    exec "$VENV/bin/python" -m estate_scanner ui --check
  fi
  printf '\n   Starting Estate Scanner ...\n\n'
  cleanup; trap - EXIT
  # Linux desktops rarely have a webview toolkit installed; use the browser there.
  if [ "$OS" = "Linux" ]; then exec "$VENV/bin/python" -m estate_scanner ui --browser; fi
  # Through the app rather than this Terminal, so the Dock shows the app and
  # closing the Terminal window does not close Estate Scanner.
  if [ -n "$APP" ]; then exec open "$APP"; fi
  exec "$VENV/bin/python" -m estate_scanner ui
}

main "$@"
