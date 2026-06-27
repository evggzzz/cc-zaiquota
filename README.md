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

# Know exactly when z.ai will throttle you — before it happens.

A live, battery-style **quota meter for the z.ai GLM Coding Plan**, right in your
[Claude Code](https://code.claude.com) statusline. The 5-hour, weekly, and MCP
windows — each with a color-coded bar and a countdown to reset.

<p align="center">
  <sub><a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a></sub>
</p>

<p align="center">
  <img src="assets/demo.svg" alt="cc-zaiquota statusline demo" width="640">
</p>

---

## 😤 The problem

z.ai throttles you the moment a window fills — and you're flying blind, because:

- Claude Code's **native meter reports `0` forever** on z.ai (that field is Claude.ai-only).
- The **official** `glm-plan-usage` plugin works, but every check spins up an AI agent that takes **~20 seconds**.

**cc-zaiquota shows the same data — instantly, always-on, and ban-safe.**

## ✨ Features

| | |
|---|---|
| ⏳ **Three windows, one glance** | 5h rolling · weekly · MCP — each a colored bar, a %, and a reset countdown. |
| 🟢🟡🔴 **Color-coded** | Green → yellow → red as you burn a window. **Bold-red when you're about to get throttled.** |
| ⚡ **Instant, not 20 s** | One shell call — not an LLM. Milliseconds. |
| 🛡️ **Ban-safe** | Statusline = zero network. Refresh reuses z.ai's *exact* official request. |
| ♻️ **Auto-refresh (daemon)** | A launchd/cron daemon refreshes every ~10 min — even when Claude Code is closed. |
| 🧩 **Stacks with cc-contextbar** | Two-line statusline next to [cc-contextbar](https://github.com/evggzzz/cc-contextbar). Works standalone too. |

## 📊 How it compares

| | Native | Official plugin | **cc-zaiquota** |
|---|:--:|:--:|:--:|
| Shows z.ai quota | ❌ always `0` | ✅ | ✅ |
| Always-on statusline | ❌ | ❌ on-demand | ✅ |
| Query latency | — | ~20 s (AI agent) | **ms (shell)** |
| Auto-refresh | — | ❌ | ✅ |
| Ban-safe | — | ✅ official | ✅ same request |

## 🛡️ Ban-safe by design

- The statusline reads a local cache — **zero network per render**.
- A refresh sends the **exact** official request (`GET {baseDomain}/api/monitor/usage/quota/limit` with `Authorization: $ANTHROPIC_AUTH_TOKEN`). Same endpoint, same headers → indistinguishable from `glm-plan-usage`.

## 🚀 Install

> Requires `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` (same as the official plugin) and [`jq`](https://stedolan.github.io/jq/).

**Option A — as a plugin**

```bash
claude plugin marketplace add evggzzz/cc-zaiquota
claude plugin install cc-zaiquota@cc-zaiquota
```

Then in Claude Code:

```
/cc-zaiquota:refresh
```

**Option B — one-liner**

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash
```

Both drop the scripts under `~/.claude/zaiquota/`, add a composer at `~/.claude/statusline-compose.sh`, point `statusLine` at it, and install an **OS refresh daemon** (launchd on macOS, cron on Linux). Your z.ai credentials are stored in `~/.claude/zaiquota/config.env` (chmod 600) so the daemon can reach the API. A `.bak` backup is written first. **Restart Claude Code**.

## 🔬 How it works

- `quota-fetch.sh` → `GET /api/monitor/usage/quota/limit`, stores `.data` + a timestamp.
- `quota.sh` → parses `data.limits[]`: the two `TOKENS_LIMIT` entries are 5h (sooner `nextResetTime`) and weekly (later); `TIME_LIMIT` is MCP monthly. Countdowns are computed live from each absolute `nextResetTime`.
- `compose.sh` → runs cc-contextbar (line 1) then this widget (line 2); set as `statusLine`.

## ⚙️ Customize

`~/.claude/zaiquota/config.env`:

| Var | Default | Effect |
|---|---|---|
| `ZAI_SEGMENTS` | `10` | bar cells |
| `ZAI_FILL` / `ZAI_EMPTY` | `█` / `░` | bar glyphs |
| `ZAI_ICONS` | `0` | `1` = emoji icons (wide terminals) |
| `ZAI_REFRESH_MIN` | `600` | auto-refresh min interval (s) |

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash -s -- --uninstall
```

Reverts `statusLine` to cc-contextbar and stops/removes the daemon + `~/.claude/zaiquota/`.

---

> ⭐ **If z.ai has ever throttled you mid-flow — this is for you.**

## ⭐ Star History

<a href="https://star-history.com/#evggzzz/cc-zaiquota&Date">
  <img src="https://api.star-history.com/svg?repos=evggzzz/cc-zaiquota&type=Date" alt="Star History" width="600">
</a>

## 📄 License

MIT © [evggzzz](https://github.com/evggzzz)
