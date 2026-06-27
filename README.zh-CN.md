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
  把你的 <strong>z.ai GLM Coding Plan 用量</strong>（5 小时 + 每周 + MCP）显示为<br>
  <a href="https://code.claude.com">Claude Code</a> 状态栏的第二行。
</p>

<p align="center">
  <sub><a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a></sub>
</p>

<p align="center">
  <img src="assets/demo.svg" alt="cc-zaiquota 演示" width="640">
</p>

---

## ✨ 特性

| | |
|---|---|
| ⏳ **一眼看清三个额度** | 5 小时滚动、每周（7 天）、MCP 月度，各自带颜色条、百分比和重置倒计时。 |
| 🎨 **精致又紧凑** | 彩色电池条 + 加粗百分比 + 变淡的倒计时。默认不带双宽 emoji（宽屏终端可设 `ZAI_ICONS=1`）。 |
| 🧩 **与 cc-contextbar 组合** | 叠在 [cc-contextbar](https://github.com/evggzzz/cc-contextbar) 下方组成两行状态栏，也可单独使用。 |
| 🛡️ **防封号设计** | 状态栏只读缓存，**每次渲染零网络请求**。刷新按需触发，且复用 z.ai 官方的*同一请求*。 |
| ⚡ **不走 AI agent** | 不像官方 `glm-plan-usage` 插件那样经 LLM，刷新只是一次 shell 调用（毫秒级，而非约 20 秒）。 |

## 🤔 为什么需要

> [!IMPORTANT]
> z.ai Coding Plan 在 **5 小时**或**每周**额度用满时会限流。Claude Code 自带的 `rate_limits` 字段**仅限 Claude.ai**，在 z.ai 下并不存在 —— 所以需要单独获取。本插件安全地完成这件事。

## 🛡️ 如何避免封号

- 状态栏组件**完全不联网**，只读 `~/.claude/zaiquota/quota.cache`。
- `/cc-zaiquota:refresh` 发出与官方 `glm-plan-usage` **完全相同的请求**：`GET {baseDomain}/api/monitor/usage/quota/limit`，带 `Authorization: $ANTHROPIC_AUTH_TOKEN`。端点和请求头都一样，与官方工具无法区分。
- 默认仅按需触发（无轮询循环）。

## ♻️ 自动刷新

通过 `Stop` 和 `SessionStart` 钩子自动刷新缓存 —— 每轮对话结束和会话开始时触发，**节流为每个 `ZAI_REFRESH_MIN`（默认 600 秒）最多一次**。活跃使用时保持最新，空闲时不轮询。

- 调整间隔：在 `~/.claude/zaiquota/config.env` 设 `ZAI_REFRESH_MIN=300`
- 立即更新：`/cc-zaiquota:refresh`（用 `--force`，绕过节流）

状态栏本身仍然**零网络请求**；只有带节流的 fetcher 会访问 API。

## 🚀 安装

> 需要环境变量 `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`（与官方插件相同），以及 [`jq`](https://stedolan.github.io/jq/)。

**方式 A —— 作为插件**

```bash
claude plugin marketplace add evggzzz/cc-zaiquota
claude plugin install cc-zaiquota@cc-zaiquota
```

然后在 Claude Code 中：

```
/cc-zaiquota:refresh
```

**方式 B —— 一行命令**

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash
```

两种方式都会把脚本放到 `~/.claude/zaiquota/`，在 `~/.claude/statusline-compose.sh` 放一个合成器，并把 `statusLine` 指向它（会先备份为 `.bak`）。**重启 Claude Code**，再执行 `/cc-zaiquota:refresh` 生成缓存。

## 🔬 工作原理

- `quota-fetch.sh` → `GET /api/monitor/usage/quota/limit`，把 `.data` 和时间戳存入缓存。
- `quota.sh` → 解析 `data.limits[]`：两个 `TOKENS_LIMIT` 分别是 5 小时（`nextResetTime` 更早）和每周（更晚）；`TIME_LIMIT` 是 MCP 月度。重置倒计时根据绝对时间 `nextResetTime` 实时计算。
- `compose.sh` → 先跑 cc-contextbar（第 1 行），再跑本组件（第 2 行）；把它设为 `statusLine`。

## ⚙️ 自定义

创建 `~/.claude/zaiquota/config.env` 覆盖默认值：

| 变量 | 默认 | 作用 |
|---|---|---|
| `ZAI_SEGMENTS` | `10` | 进度条格子数 |
| `ZAI_FILL` / `ZAI_EMPTY` | `█` / `░` | 进度条字符 |
| `ZAI_ICONS` | `0` | `1` 显示 emoji 图标（宽屏终端） |
| `ZAI_REFRESH_MIN` | `600` | 自动刷新最小间隔（秒） |

```bash
# ~/.claude/zaiquota/config.env
ZAI_SEGMENTS=8
ZAI_ICONS=1
ZAI_REFRESH_MIN=300
```

## 🗑️ 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash -s -- --uninstall
```

把 `statusLine` 恢复为 cc-contextbar（如已安装），并删除 `~/.claude/zaiquota/`。

## ⭐ Star 历史

<a href="https://star-history.com/#evggzzz/cc-zaiquota&Date">
  <img src="https://api.star-history.com/svg?repos=evggzzz/cc-zaiquota&type=Date" alt="Star History" width="600">
</a>

## 📄 许可证

MIT © [evggzzz](https://github.com/evggzzz)
