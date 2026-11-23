#!/usr/bin/env bash
# cc-zaiquota stdin mirror (mod mode).
#
# Claude Code pipes the statusline stdin JSON here. The hooks module
# (hooks/register.ts) reads the rate_limits object back from
# ~/.claude/zaiquota/rate_limits.json and does all the rendering. This
# script prints nothing — on-screen output belongs to the mod.
#
# Writes only when the stdin actually carries rate_limits. z.ai sessions
# get none in their stdin, and both config dirs run this same script, so
# writing unconditionally would let a z.ai session clobber the last data
# an Anthropic session mirrored (last-writer-wins over one shared file).
set -euo pipefail

DIR="${ZAI_DIR:-$HOME/.claude/zaiquota}"
mkdir -p "$DIR"

input=$(cat)
if ! printf '%s' "$input" | jq -e '.rate_limits != null and ((.rate_limits | length) > 0)' >/dev/null 2>&1; then
  exit 0   # no windows in this render — keep the previous content
fi

payload=$(printf '%s' "$input" | jq -c '{fetched_at: (now|floor), rate_limits: .rate_limits}')
[ -n "$payload" ] || exit 0

tmp="$DIR/.rate_limits.$$.tmp"
printf '%s' "$payload" > "$tmp"
mv "$tmp" "$DIR/rate_limits.json"
