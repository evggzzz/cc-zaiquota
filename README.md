<p align="center">
  <img src="assets/banner.svg" alt="cc-zaiquota" width="780">
</p>

<p align="center">
  <a href="https://github.com/evggzzz/cc-zaiquota/releases"><img src="https://img.shields.io/badge/version-1.0.0-3fb950?style=flat-square"></a>
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square">
  <img src="https://img.shields.io/badge/z.ai-Coding%20Plan-6f42c1?style=flat-square">
  <img src="https://img.shields.io/badge/built%20with-bash%20%2B%20jq-1f1f1f?style=flat-square">
  <img src="https://img.shields.io/github/stars/evggzzz/cc-zaiquota?style=flat-square&color=yellow">
</p>

<p align="center">
  Show your <strong>z.ai GLM Coding Plan quota</strong> (5-hour + weekly + MCP) as a second line<br>
  in the <a href="https://code.claude.com">Claude Code</a> statusline — right next to your chat input.
</p>

<p align="center">
  <img src="assets/demo.svg" alt="cc-zaiquota statusline demo" width="640">
</p>

---

## ✨ Features

| | |
|---|---|
| ⏳ **Three windows at a glance** | 5-hour rolling, weekly (7-day), and MCP monthly — each with a color-coded bar, %, and time-to-reset. |
| 🎨 **Rich, compact** | Colored battery bars + bold % + dimmed countdowns. No double-width emoji by default (set `ZAI_ICONS=1` on wide terminals). |
| 🧩 **Composes with cc-contextbar** | Stacks under [cc-contextbar](https://github.com/evggzzz/cc-contextbar) for a two-line statusline. Each works standalone too. |
| 🛡️ **Ban-safe by design** | The statusline reads a local cache only — **zero network per render**. Refresh is on demand and reuses z.ai's *exact* official quota request. |
| ⚡ **No AI agent** | Unlike the official `glm-plan-usage` plugin, the refresh is a single shell call (milliseconds, not ~20s). |

## 🤔 Why

> [!IMPORTANT]
> z.ai's Coding Plan throttles you when the **5-hour** or **weekly** window fills. Claude Code's built-in `rate_limits` statusline field is **Claude.ai-only** and is absent for z.ai — so you need a dedicated fetch. This widget does it safely.

## 🛡️ Ban-safe — how

- The statusline widget **never calls the network**; it reads `~/.claude/zaiquota/quota.cache`.
- `/cc-zaiquota:refresh` performs the **exact same request** as z.ai's official `glm-plan-usage` plugin: `GET {baseDomain}/api/monitor/usage/quota/limit` with `Authorization: $ANTHROPIC_AUTH_TOKEN`. Same endpoint, same headers → indistinguishable from the official tool.
- On-demand only by default (no polling loop).

## 🚀 Install

> Requires `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` in your environment (the official plugin uses the same), and [`jq`](https://stedolan.github.io/jq/).

**Option A — as a plugin**

```bash
claude plugin marketplace add evggzzz/cc-zaiquota
claude plugin install cc-zaiquota@cc-zaiquota
```

Then inside Claude Code:

```
/cc-zaiquota:refresh
```

**Option B — one-liner**

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash
```

Both copy the scripts under `~/.claude/zaiquota/`, drop a composer at `~/.claude/statusline-compose.sh`, and point `statusLine` at it (a `.bak` backup is written first). **Restart Claude Code**, then run `/cc-zaiquota:refresh` to populate the cache.

## 🔬 How it works

- `quota-fetch.sh` → `GET /api/monitor/usage/quota/limit`, stores `.data` + a timestamp in the cache.
- `quota.sh` → parses `data.limits[]`: the two `TOKENS_LIMIT` entries are 5h (sooner `nextResetTime`) and weekly (later); `TIME_LIMIT` is MCP monthly. Time-to-reset is computed live from each absolute `nextResetTime`.
- `compose.sh` → runs cc-contextbar (line 1) then this widget (line 2); set as the `statusLine` command.

## ⚙️ Customize

Create `~/.claude/zaiquota/config.env` to override defaults:

| Var | Default | Effect |
|---|---|---|
| `ZAI_SEGMENTS` | `10` | bar cell count |
| `ZAI_FILL` / `ZAI_EMPTY` | `█` / `░` | bar glyphs |
| `ZAI_ICONS` | `0` | `1` to prepend emoji icons (wide terminals) |

```bash
# ~/.claude/zaiquota/config.env
ZAI_SEGMENTS=8
ZAI_ICONS=1
```

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash -s -- --uninstall
```

Reverts `statusLine` to cc-contextbar (if present) and removes `~/.claude/zaiquota/`.

## ⭐ Star History

<a href="https://star-history.com/#evggzzz/cc-zaiquota&Date">
  <img src="https://api.star-history.com/svg?repos=evggzzz/cc-zaiquota&type=Date" alt="Star History" width="600">
</a>

## 📄 License

MIT © [evggzzz](https://github.com/evggzzz)
