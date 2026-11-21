#!/usr/bin/env bash
# cc-zaiquota statusline composer.
#
# Provider-aware. Line 2 is picked by the provider this Claude Code session
# talks to (override in ~/.claude/zaiquota/config.env with ZAI_PROVIDER=zai
# or ZAI_PROVIDER=anthropic to pin it):
#
#   z.ai sessions      (ANTHROPIC_BASE_URL contains z.ai — the wrapper setup)
#                      -> z.ai GLM Coding Plan quota from the local cache
#   Anthropic sessions (plain CLI, GUI, anything else)
#                      -> claude.ai plan rate limits from the statusline stdin
#
# cc-contextbar (line 1) is provider-agnostic and runs either way.
# Each widget stays independent; missing ones are skipped.
# Set this as the statusLine command in settings.json.
input=$(cat)

if [ -x "$HOME/.claude/ctxbar/statusline.sh" ]; then
  printf '%s' "$input" | "$HOME/.claude/ctxbar/statusline.sh"
fi

# Pick up an explicit ZAI_PROVIDER=zai|anthropic pin from config.env without
# sourcing it wholesale — it also carries ANTHROPIC_BASE_URL/AUTH_TOKEN for
# the refresh daemon, and importing those here would make every session look
# z.ai. A pin in config.env wins over the env var; absence falls through.
if [ -f "$HOME/.claude/zaiquota/config.env" ]; then
  _pin=$(grep -E '^ZAI_PROVIDER=' "$HOME/.claude/zaiquota/config.env" 2>/dev/null | cut -d= -f2-)
  [ -n "$_pin" ] && ZAI_PROVIDER="$_pin"
fi
ZAI_PROVIDER=${ZAI_PROVIDER:-auto}

case "$ZAI_PROVIDER" in
  zai)       WIDGET="$HOME/.claude/zaiquota/quota.sh" ;;
  anthropic) WIDGET="$HOME/.claude/zaiquota/quota-anthropic.sh" ;;
  *)
    case "${ANTHROPIC_BASE_URL:-}" in
      *z.ai*) WIDGET="$HOME/.claude/zaiquota/quota.sh" ;;
      *)      WIDGET="$HOME/.claude/zaiquota/quota-anthropic.sh" ;;
    esac ;;
esac

if [ -x "$WIDGET" ]; then
  printf '\n'
  printf '%s' "$input" | "$WIDGET"
fi
