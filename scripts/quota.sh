#!/usr/bin/env bash
# cc-zaiquota statusline part (line 2).
# Reads ~/.claude/zaiquota/quota.cache ONLY — no network. Ban-safe by construction.
set -o pipefail

CACHE="$HOME/.claude/zaiquota/quota.cache"

if [ ! -f "$CACHE" ]; then
  printf '⏳ z.ai quota: run /cc-zaiquota:refresh'
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

# color the 5h window: <50 green / <80 yellow / >=80 red
if   [ "$h5p" -lt 50 ]; then c=$'\033[32m'
elif [ "$h5p" -lt 80 ]; then c=$'\033[33m'
else                          c=$'\033[31m'; fi

# time-to-reset formatter (target epoch sec -> "2h13m" / "6d3h" / "12m")
remain() {
  local r=$(( ${1:-0} - now ))
  [ "$r" -lt 0 ] && r=0
  local d=$(( r / 86400 )) h=$(( (r % 86400) / 3600 )) m=$(( (r % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}
h5txt=$(remain "$h5r")
wtxt=$(remain "$wr")

ago=$(( now - fetched ))
ago_m=$(( ago / 60 ))

printf '⏳ %b5h %s%% (%s)\033[0m · 週 %s%% (%s) · MCP %s%% · %sm前' \
  "$c" "$h5p" "$h5txt" "$wp" "$wtxt" "$mcp" "$ago_m"
