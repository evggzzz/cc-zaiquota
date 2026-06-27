#!/usr/bin/env bash
# cc-zaiquota installer.
#   install         place scripts under ~/.claude/zaiquota/ (+ composer at
#                   ~/.claude/statusline-compose.sh) and wire settings.json.
#   --uninstall     revert statusLine to cc-contextbar (if present) and remove
#                   the cc-zaiquota files.
set -euo pipefail

ZAI_DIR="$HOME/.claude/zaiquota"
SETTINGS="$HOME/.claude/settings.json"
COMPOSE="$HOME/.claude/statusline-compose.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

fetch() { # $1=name $2=dest
  if [ -f "$SCRIPT_DIR/$1" ]; then cp "$SCRIPT_DIR/$1" "$2"
  else echo "ERROR: bundled file missing: $1" >&2; exit 1; fi
}

if [ "${1:-install}" = "--uninstall" ] || [ "${1:-}" = "uninstall" ]; then
  echo ">> Removing cc-zaiquota..."
  if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    cp "$SETTINGS" "$SETTINGS.bak"
    tmp=$(mktemp)
    # revert to cc-contextbar if present, else drop statusLine
    if [ -x "$HOME/.claude/ctxbar/statusline.sh" ]; then
      jq --arg cmd "$HOME/.claude/ctxbar/statusline.sh" '.statusLine={"type":"command","command":$cmd,"padding":0}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    else
      jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    fi
    echo "   statusLine reverted (backup: $SETTINGS.bak)"
  fi
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

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"
tmp=$(mktemp)
jq --arg cmd "$COMPOSE" '.statusLine={"type":"command","command":$cmd,"padding":0}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
echo "   statusLine -> $COMPOSE  (backup: $SETTINGS.bak)"

cat <<EOF

>> Installed. Restart Claude Code.
>> Refresh quota:   /cc-zaiquota:refresh
                    (or: bash $ZAI_DIR/quota-fetch.sh)
>> Uninstall:       bash install.sh --uninstall

EOF
