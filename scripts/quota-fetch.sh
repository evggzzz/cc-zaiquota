#!/usr/bin/env bash
# cc-zaiquota fetcher — updates ~/.claude/zaiquota/quota.cache
#
# Ban-safe: performs the EXACT same request as z.ai's official glm-plan-usage
# plugin (same endpoint, same Authorization header). Single GET, no retries.
#
# Throttle: skips the network call if the cache is younger than
# ZAI_REFRESH_MIN (default 600s). Use --force to bypass (the manual
# /cc-zaiquota:refresh command uses --force). This lets a frequent hook
# (Stop / SessionStart) trigger it safely — at most one real call per window.
set -euo pipefail

CACHE_DIR="$HOME/.claude/zaiquota"
# shellcheck source=/dev/null
[ -f "$CACHE_DIR/config.env" ] && . "$CACHE_DIR/config.env"   # ZAI_* + ANTHROPIC_* (for launchd/cron, which don't inherit shell env)
CACHE="$CACHE_DIR/quota.cache"
MIN_INTERVAL=${ZAI_REFRESH_MIN:-600}

FORCE=0
case "${1:-}" in
  -f|--force) FORCE=1 ;;
esac

# throttle (unless --force)
if [ "$FORCE" -eq 0 ] && [ -f "$CACHE" ]; then
  last=$(jq -r '.fetched_at // 0' "$CACHE" 2>/dev/null || echo 0)
  now=$(date +%s)
  if [ -n "${last:-0}" ] && [ "${last:-0}" -gt 0 ] && [ $(( now - last )) -lt "$MIN_INTERVAL" ]; then
    exit 0   # fresh enough — skip silently
  fi
fi

BASE_URL="${ANTHROPIC_BASE_URL:-}"
TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"

if [ -z "$TOKEN" ]; then
  echo "ERROR: ANTHROPIC_AUTH_TOKEN is not set" >&2
  exit 1
fi
if [ -z "$BASE_URL" ]; then
  echo "ERROR: ANTHROPIC_BASE_URL is not set" >&2
  exit 1
fi

# base domain, e.g. https://api.z.ai  (drop the /api/anthropic path)
domain=$(printf '%s' "$BASE_URL" | sed -E 's|(https?://[^/]+).*|\1|')
url="${domain}/api/monitor/usage/quota/limit"

mkdir -p "$CACHE_DIR"

tmp=$(mktemp)
http=$(curl -sS -o "$tmp" -w '%{http_code}' \
  -H "Authorization: ${TOKEN}" \
  -H "Accept-Language: en-US,en" \
  -H "Content-Type: application/json" \
  "$url") || { echo "ERROR: curl request failed" >&2; rm -f "$tmp"; exit 1; }

if [ "$http" != "200" ]; then
  echo "ERROR: HTTP $http" >&2
  cat "$tmp" >&2
  rm -f "$tmp"
  exit 1
fi

fetched=$(date +%s)
# store fetch timestamp + the .data object (keeps nextResetTime etc.)
jq -c --argjson ts "$fetched" '{fetched_at:$ts, data:.data}' "$tmp" > "$CACHE"
rm -f "$tmp"
[ "$FORCE" -eq 1 ] && echo "✓ quota cache updated -> $CACHE"
exit 0
