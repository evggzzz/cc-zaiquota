---
description: Refresh the z.ai Coding Plan quota cache (one fetch, no AI agent)
allowed-tools: Bash(bash:*)
---

Refresh the cached z.ai GLM Coding Plan quota so the statusline widget shows current values. Run the fetcher exactly once:

`bash ~/.claude/zaiquota/quota-fetch.sh`

- On success: tell the user the cache is updated and the statusline will reflect it on the next render (or after restarting Claude Code).
- On failure: show the error. The most common cause is `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` not being set in the environment.
