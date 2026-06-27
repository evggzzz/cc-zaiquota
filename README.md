# cc-zaiquota

Show your **z.ai GLM Coding Plan quota** (5-hour + weekly + MCP) as a second line in the [Claude Code](https://code.claude.com) statusline.

```
🤖 glm-5.2 · [████░░░░░░] 42% · $1.23        ← cc-contextbar (line 1)
⏳ 5h 48% (2h13m) · 週 13% (6d3h) · MCP 1% · 3m前   ← cc-zaiquota (line 2)
```

Designed to compose on top of [cc-contextbar](https://github.com/evggzzz/cc-contextbar) — install both and you get a two-line statusline. Each works standalone too.

## Why

z.ai's Coding Plan has a **5-hour rolling** and a **weekly** quota. Hitting them mid-session throttles you. This widget shows how much you have left and when each resets — right next to your chat input.

## Ban-safe by design

- The statusline widget **never calls the network** — it reads a local cache (`~/.claude/zaiquota/quota.cache`).
- The cache is refreshed **on demand** via `/cc-zaiquota:refresh`, which performs the **exact same request** as z.ai's official `glm-plan-usage` plugin (same endpoint, same `Authorization` header). No raw SDK, no polling loop.
- (Claude Code's built-in `rate_limits` statusline field is Claude.ai-only and is **absent** for z.ai — so a dedicated fetch is required.)

## Requirements

- [Claude Code](https://code.claude.com) backed by z.ai (`ANTHROPIC_BASE_URL=https://api.z.ai/...`)
- `ANTHROPIC_AUTH_TOKEN` set in your environment (the official plugin uses the same)
- [`jq`](https://stedolan.github.io/jq/) — `brew install jq`

## Install

```bash
claude plugin marketplace add evggzzz/cc-zaiquota
claude plugin install cc-zaiquota@cc-zaiquota
```

Then inside Claude Code:

```
/cc-zaiquota:refresh
```

Or one-liner (no plugin):

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash
```

Restart Claude Code. Run `/cc-zaiquota:refresh` whenever you want fresh numbers (the statusline otherwise shows the last-cached value with an "Nm ago" stamp).

## How it works

- `quota-fetch.sh` → `GET {baseDomain}/api/monitor/usage/quota/limit` with `Authorization: $ANTHROPIC_AUTH_TOKEN`, saves `.data` + a timestamp to the cache.
- `quota.sh` → parses the cache: `TOKENS_LIMIT` entries (5h = sooner reset, weekly = later reset) and `TIME_LIMIT` (MCP monthly); computes time-to-reset from each `nextResetTime`.
- `compose.sh` → runs cc-contextbar (line 1) then this widget (line 2); set as the `statusLine` command.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash -s -- --uninstall
```

Reverts the statusline to cc-contextbar (if present) and removes `~/.claude/zaiquota/`.

## License

MIT © [evggzzz](https://github.com/evggzzz)
