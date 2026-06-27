#!/usr/bin/env bash
# cc-zaiquota installer.
#   install         place scripts, wire statusLine -> composer, store credentials
#                   in config.env, and install an OS-level refresh daemon
#                   (launchd on macOS, cron on Linux).
#   --uninstall     stop+remove the daemon, revert statusLine, delete files.
set -euo pipefail

ZAI_DIR="$HOME/.claude/zaiquota"
SETTINGS="$HOME/.claude/settings.json"
COMPOSE="$HOME/.claude/statusline-compose.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
LABEL="com.evggzzz.cc-zaiquota"

fetch() { # $1=name $2=dest
  if [ -f "$SCRIPT_DIR/$1" ]; then cp "$SCRIPT_DIR/$1" "$2"
  else echo "ERROR: bundled file missing: $1" >&2; exit 1; fi
}

# --- credentials: launchd/cron don't inherit shell env, so persist them ---
ensure_credentials() {
  local cfg="$ZAI_DIR/config.env"
  mkdir -p "$ZAI_DIR"; touch "$cfg"; chmod 600 "$cfg"
  if [ -n "${ANTHROPIC_BASE_URL:-}" ] && [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
    grep -vE '^(ANTHROPIC_BASE_URL|ANTHROPIC_AUTH_TOKEN)=' "$cfg" > "$cfg.tmp" 2>/dev/null || true
    { printf 'ANTHROPIC_BASE_URL=%q\n'   "$ANTHROPIC_BASE_URL";
      printf 'ANTHROPIC_AUTH_TOKEN=%q\n' "$ANTHROPIC_AUTH_TOKEN"; } >> "$cfg.tmp"
    mv "$cfg.tmp" "$cfg"; chmod 600 "$cfg"
    echo "   credentials -> $cfg (chmod 600)"
  elif grep -qE '^ANTHROPIC_AUTH_TOKEN=' "$cfg"; then
    echo "   credentials: kept existing in $cfg"
  else
    echo "   WARN: ANTHROPIC_AUTH_TOKEN not in env; add it to $cfg so the daemon can fetch" >&2
  fi
}

refresh_interval() {  # seconds, from config.env or default 600
  local v; v=$(grep -E '^ZAI_REFRESH_MIN=' "$ZAI_DIR/config.env" 2>/dev/null | cut -d= -f2)
  echo "${v:-600}"
}

# --- macOS launchd ---
install_launchd() {
  local interval plist LA; interval=$(refresh_interval)
  LA="$HOME/Library/LaunchAgents"; mkdir -p "$LA"; plist="$LA/$LABEL.plist"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$ZAI_DIR/quota-fetch.sh</string>
  </array>
  <key>StartInterval</key><integer>$interval</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$ZAI_DIR/daemon.log</string>
  <key>StandardErrorPath</key><string>$ZAI_DIR/daemon.log</string>
</dict>
</plist>
EOF
  plutil -lint "$plist" >/dev/null || { echo "ERROR: generated invalid plist" >&2; exit 1; }
  local dom; dom="gui/$(id -u)"
  launchctl bootout "$dom/$LABEL" 2>/dev/null || true
  launchctl bootstrap "$dom" "$plist" 2>/dev/null || launchctl load -w "$plist" 2>/dev/null || true
  echo "   launchd agent -> every ${interval}s (runs on load + login)"
}
uninstall_launchd() {
  local dom; dom="gui/$(id -u)"
  launchctl bootout "$dom/$LABEL" 2>/dev/null || launchctl unload "$HOME/Library/LaunchAgents/$LABEL.plist" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
}

# --- Linux cron ---
install_cron() {
  local interval minutes; interval=$(refresh_interval); minutes=$(( interval / 60 )); [ "$minutes" -lt 1 ] && minutes=1
  ( crontab -l 2>/dev/null | grep -v "cc-zaiquota/quota-fetch.sh"; \
    echo "*/$minutes * * * * /bin/bash $ZAI_DIR/quota-fetch.sh >/dev/null 2>&1" ) | crontab -
  echo "   cron -> every ${minutes} min"
}
uninstall_cron() {
  crontab -l 2>/dev/null | grep -v "cc-zaiquota/quota-fetch.sh" | crontab - 2>/dev/null || true
}

install_daemon() {
  case "$(uname -s)" in
    Darwin) install_launchd ;;
    Linux)  install_cron ;;
    *) echo "   WARN: unrecognized OS ($(uname -s)); set up a scheduler to run $ZAI_DIR/quota-fetch.sh" >&2 ;;
  esac
}
uninstall_daemon() {
  case "$(uname -s)" in
    Darwin) uninstall_launchd ;;
    Linux)  uninstall_cron ;;
  esac
}

# remove hook-based auto-refresh left by older versions (now uses OS daemon)
cleanup_legacy_hooks() {
  [ -f "$SETTINGS" ] || return 0
  local before after tmp
  before=$(jq -c '.hooks // {}' "$SETTINGS" 2>/dev/null)
  tmp=$(mktemp)
  jq '(.hooks // {}) |= ( with_entries(.value |= map(select( ([.hooks[].command] | map(test("quota-fetch\\.sh")) | any) | not )))
      | with_entries(select(.value | length > 0)) )' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  after=$(jq -c '.hooks // {}' "$SETTINGS" 2>/dev/null)
  [ "$before" != "$after" ] && echo "   removed legacy Stop/SessionStart hooks (now using OS daemon)"
  return 0
}

# --- entry ---
if [ "${1:-install}" = "--uninstall" ] || [ "${1:-}" = "uninstall" ]; then
  echo ">> Removing cc-zaiquota..."
  if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak"
    tmp=$(mktemp)
    if [ -x "$HOME/.claude/ctxbar/statusline.sh" ]; then
      jq --arg cmd "$HOME/.claude/ctxbar/statusline.sh" '.statusLine={"type":"command","command":$cmd,"padding":0}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    else
      jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    fi
    echo "   statusLine reverted (backup: $SETTINGS.bak)"
  fi
  uninstall_daemon
  echo "   daemon stopped"
  rm -rf "$ZAI_DIR" "$COMPOSE"
  echo ">> Done. Restart Claude Code."
  exit 0
fi

echo ">> Installing cc-zaiquota..."
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required (brew install jq)" >&2; exit 1; }

mkdir -p "$ZAI_DIR"
fetch quota.sh        "$ZAI_DIR/quota.sh";        chmod +x "$ZAI_DIR/quota.sh"
fetch quota-fetch.sh  "$ZAI_DIR/quota-fetch.sh";  chmod +x "$ZAI_DIR/quota-fetch.sh"
fetch compose.sh      "$COMPOSE";                 chmod +x "$COMPOSE"

ensure_credentials

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"
tmp=$(mktemp)
jq --arg cmd "$COMPOSE" '.statusLine={"type":"command","command":$cmd,"padding":0}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
echo "   statusLine -> $COMPOSE  (backup: $SETTINGS.bak)"

cleanup_legacy_hooks
install_daemon

cat <<EOF

>> Installed. Restart Claude Code.
>> Background refresh: every \$(grep ^ZAI_REFRESH_MIN= $ZAI_DIR/config.env | cut -d= -f2 || echo 600)s
                       via launchd (macOS) / cron (Linux). Tune: ZAI_REFRESH_MIN in config.env, then re-run install.
>> Manual refresh:     /cc-zaiquota:refresh   (or: bash $ZAI_DIR/quota-fetch.sh --force)
>> Daemon log:         $ZAI_DIR/daemon.log
>> Uninstall:          bash install.sh --uninstall

EOF
