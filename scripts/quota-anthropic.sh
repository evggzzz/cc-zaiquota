#!/usr/bin/env bash
# cc-zaiquota statusline part (line 2, Anthropic sessions).
#
# When the session talks to Anthropic directly (no z.ai in ANTHROPIC_BASE_URL
# — the plain `cl` CLI, the GUI, or any other non-z.ai setup), Claude Code
# feeds this script the subscriber rate limits on stdin, the same data
# /status and /usage show:
#
#   .rate_limits.five_hour  { used_percentage, resets_at }   rolling 5h window
#   .rate_limits.seven_day  { used_percentage, resets_at }   weekly window
#
# claude.ai Pro/Max/Ultra only; each window may be independently absent
# (e.g. before the first API response of the session), so render whatever
# arrived. No network here — the data rides in with the render.
set -o pipefail

# shellcheck source=/dev/null
[ -f "$HOME/.claude/zaiquota/config.env" ] && . "$HOME/.claude/zaiquota/config.env"
SEGMENTS=${ZAI_SEGMENTS:-10}
FILL=${ZAI_FILL:-█}
EMPTY=${ZAI_EMPTY:-░}

# color escape by threshold: <50 green / <80 yellow / >=80 red+bold
color_for() {
  if   [ "$1" -lt 50 ]; then printf '\033[32m'
  elif [ "$1" -lt 80 ]; then printf '\033[33m'
  else                     printf '\033[1;31m'; fi
}

# labels: plain by default, emoji when ZAI_ICONS=1 (kept in sync with quota.sh)
if [ "${ZAI_ICONS:-0}" = "1" ]; then
  L5="⚡5h"; LWK="📅wk"; PFX=""
else
  L5="5h"; LWK="wk"; PFX="⏳ "
fi

# segment: $1=label $2=pct $3=reset_txt  ->  "5h [██████░░░░] 51% 2h26m"
# bar + % colored; reset dimmed
seg() {
  local pct=$2 filled empty i fp ep c
  c=$(color_for "$pct")
  filled=$(( pct * SEGMENTS / 100 )); [ "$filled" -gt "$SEGMENTS" ] && filled=$SEGMENTS
  empty=$(( SEGMENTS - filled ))
  fp=""; i=0; while [ "$i" -lt "$filled" ]; do fp="${fp}${FILL}"; i=$((i+1)); done
  ep=""; i=0; while [ "$i" -lt "$empty"  ]; do ep="${ep}${EMPTY}"; i=$((i+1)); done
  printf '%s %b[%s\033[90m%s\033[0m] \033[1m%b%s%%\033[0m \033[2m%s\033[0m' \
    "$1" "$c" "$fp" "$ep" "$c" "$pct" "$3"
}

input=$(cat)
now=$(date +%s)

# time-to-reset (target epoch sec -> "2h26m" / "6d7h" / "12m")
remain() {
  local r=$(( ${1:-0} - now )); [ "$r" -lt 0 ] && r=0
  local d=$(( r / 86400 )) h=$(( (r % 86400) / 3600 )) m=$(( (r % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# absent window -> -1, so it can be told apart from a real 0%
IFS=$'\t' read -r h5p h5r wp wr < <(
  printf '%s' "$input" | jq -r '
    (.rate_limits // {}) as $r
    | [ (($r.five_hour.used_percentage // -1) | floor),
        ($r.five_hour.resets_at // 0),
        (($r.seven_day.used_percentage // -1) | floor),
        ($r.seven_day.resets_at // 0) ]
    | @tsv
  ' 2>/dev/null
)
h5p=${h5p:--1}; h5r=${h5r:-0}; wp=${wp:--1}; wr=${wr:-0}

if [ "$h5p" -lt 0 ] && [ "$wp" -lt 0 ]; then
  printf '⏳ \033[2m5h/wk quota appears after the first API response\033[0m'
  exit 0
fi

out=""
[ "$h5p" -ge 0 ] && out="$(seg "$L5" "$h5p" "$(remain "$h5r")")"
if [ "$wp" -ge 0 ]; then
  [ -n "$out" ] && out="$out · "
  out="$out$(seg "$LWK" "$wp" "$(remain "$wr")")"
fi

printf '%s%s' "$PFX" "$out"
