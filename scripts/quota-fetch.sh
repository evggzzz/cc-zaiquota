#!/usr/bin/env bash
# cc-zaiquota fetcher — updates ~/.claude/zaiquota/quota.cache
#
# Ban-safe: this performs the EXACT same request as z.ai's official
# glm-plan-usage plugin (same endpoint, same Authorization header, same
# Content-Type / Accept-Language). It is a single GET; no retries, no loop.
set -euo pipefail

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

CACHE_DIR="$HOME/.claude/zaiquota"
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
jq -c --argjson ts "$fetched" '{fetched_at:$ts, data:.data}' "$tmp" > "$CACHE_DIR/quota.cache"
rm -f "$tmp"
echo "✓ quota cache updated -> $CACHE_DIR/quota.cache"
