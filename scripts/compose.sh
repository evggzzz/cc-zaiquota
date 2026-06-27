#!/usr/bin/env bash
# cc-zaiquota statusline composer.
# Runs cc-contextbar (line 1) then cc-zaiquota quota (line 2), passing the
# same stdin to both. Set this as the statusLine command in settings.json.
# Each widget stays independent; missing ones are skipped.
input=$(cat)

if [ -x "$HOME/.claude/ctxbar/statusline.sh" ]; then
  printf '%s' "$input" | "$HOME/.claude/ctxbar/statusline.sh"
fi

if [ -x "$HOME/.claude/zaiquota/quota.sh" ]; then
  printf '\n'
  printf '%s' "$input" | "$HOME/.claude/zaiquota/quota.sh"
fi
