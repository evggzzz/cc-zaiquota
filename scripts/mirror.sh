#!/usr/bin/env bash
# cc-zaiquota stdin mirror (mod mode).
#
# Claude Code pipes the statusline stdin JSON here. The hooks module
# (hooks/register.ts) reads the rate_limits object back from
# ~/.claude/zaiquota/rate_limits.json and does all the rendering. This
# script prints nothing — on-screen output belongs to the mod.
set -euo pipefail

DIR="${ZAI_DIR:-$HOME/.claude/zaiquota}"
mkdir -p "$DIR"

tmp=$(mktemp)
jq -c '{fetched_at: (now|floor), rate_limits: (.rate_limits // {})}' > "$tmp"
mv "$tmp" "$DIR/rate_limits.json"
