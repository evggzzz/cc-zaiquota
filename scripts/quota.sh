#!/usr/bin/env bash
# cc-zaiquota statusline part (line 2).
# Reads ~/.claude/zaiquota/quota.cache ONLY — no network. Ban-safe by construction.
# Labels are English/international on purpose (no locale-specific wording).
set -o pipefail

CACHE="$HOME/.claude/zaiquota/quota.cache"
SEGMENTS=${ZAI_SEGMENTS:-10}
FILL=${ZAI_FILL:-█}
EMPTY=${ZAI_EMPTY:-░}

# color escape by threshold: <50 green / <80 yellow / >=80 red
color_for() {
  if   [ "$1" -lt 50 ]; then printf '\033[32m'
  elif [ "$1" -lt 80 ]; then printf '\033[33m'
  else                     printf '\033[1;31m'; fi   # red + bold when critical
}

# segment: $1=icon $2=label $3=pct $4=reset_txt
#   ->  "⚡ 5h [██████░░░░] 51% ⏲2h29m"  (bar + % colored, reset dimmed)
seg() {
  local pct=$3 filled empty i fp ep c
  c=$(color_for "$pct")
  filled=$(( pct * SEGMENTS / 100 )); [ "$filled" -gt "$SEGMENTS" ] && filled=$SEGMENTS
  empty=$(( SEGMENTS - filled ))
  fp=""; i=0; while [ "$i" -lt "$filled" ]; do fp="${fp}${FILL}"; i=$((i+1)); done
  ep=""; i=0; while [ "$i" -lt "$empty"  ]; do ep="${ep}${EMPTY}"; i=$((i+1)); done
  printf '%s %s %b[%s\033[90m%s\033[0m] %b%s%%\033[0m \033[2m⏲%s\033[0m' \
    "$1" "$2" "$c" "$fp" "$ep" "$c" "$pct" "$4"
}

if [ ! -f "$CACHE" ]; then
  printf '⏳ z.ai quota: \033[33mrun /cc-zaiquota:refresh\033[0m'
  exit 0
fi

now=$(date +%s)

# data.limits[]:
#   TIME_LIMIT  -> MCP monthly (percentage)
#   TOKENS_LIMIT x2 -> 5h (sooner nextResetTime) + weekly (later nextResetTime)
IFS=$'\t' read -r h5p h5r wp wr mcp fetched < <(
  jq -r '
    (.data.limits // []) as $l
    | ([$l[] | select(.type == "TOKENS_LIMIT")] | sort_by(.nextResetTime)) as $t
    | [ (($t[0].percentage // 0) | floor),
        ((($t[0].nextResetTime // 0) / 1000) | floor),
        (($t[1].percentage // 0) | floor),
        ((($t[1].nextResetTime // 0) / 1000) | floor),
        (([$l[] | select(.type == "TIME_LIMIT")][0].percentage // 0) | floor),
        (.fetched_at // 0) ]
    | @tsv
  ' "$CACHE" 2>/dev/null
)
h5p=${h5p:-0}; h5r=${h5r:-0}; wp=${wp:-0}; wr=${wr:-0}; mcp=${mcp:-0}; fetched=${fetched:-0}

# time-to-reset (target epoch sec -> "2h29m" / "6d7h" / "12m")
remain() {
  local r=$(( ${1:-0} - now )); [ "$r" -lt 0 ] && r=0
  local d=$(( r / 86400 )) h=$(( (r % 86400) / 3600 )) m=$(( (r % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}
h5txt=$(remain "$h5r"); wtxt=$(remain "$wr")

ago=$(( now - fetched )); ago_m=$(( ago / 60 ))

printf '%s · %s · 🔌 \033[1;32mMCP %s%%\033[0m · \033[2m⟳ %sm ago\033[0m' \
  "$(seg ⚡ 5h "$h5p" "$h5txt")" "$(seg 📅 wk "$wp" "$wtxt")" "$mcp" "$ago_m"
