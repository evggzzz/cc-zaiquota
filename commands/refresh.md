---
description: Refresh the z.ai Coding Plan quota cache (one fetch, no AI agent)
allowed-tools: Bash(bash:*)
---

Refresh the cached z.ai GLM Coding Plan quota so the statusline widget shows current values. Run the fetcher once, bypassing the throttle:

`bash ~/.claude/zaiquota/quota-fetch.sh --force`

- On success: tell the user the cache is updated and the statusline will reflect it on the next render (or after restarting Claude Code).
- On failure: show the error. The most common cause is `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` not being set in the environment.

Note: a background daemon (launchd on macOS, cron on Linux) also refreshes automatically every `ZAI_REFRESH_MIN` seconds, so manual refresh is only needed to force an immediate update.
