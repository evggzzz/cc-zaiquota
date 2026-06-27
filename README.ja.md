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
  <a href="https://code.claude.com">Claude Code</a> のステータスラインに、<strong>z.ai GLM Coding Plan のクォータ</strong>（5時間・週次・MCP）を2行目として表示します。
</p>

<p align="center">
  <sub><a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a></sub>
</p>

<p align="center">
  <img src="assets/demo.svg" alt="cc-zaiquota デモ" width="640">
</p>

---

## ✨ 機能

| | |
|---|---|
| ⏳ **3つのウィンドウを一目で** | 5時間ローリング・週次（7日）・MCP月次を、それぞれカラーバー＋％＋リセットまでの時間で表示します。 |
| 🎨 **リッチかつコンパクト** | カラーのバッテリーバー＋太字の％＋薄い色のカウントダウン。デフォルトは2幅emojiなし（ワイド端末なら `ZAI_ICONS=1` で表示）。 |
| 🧩 **cc-contextbar と合成** | [cc-contextbar](https://github.com/evggzzz/cc-contextbar) の下に重ねて2行ステータスラインに。単体でも使えます。 |
| 🛡️ **BAN回避設計** | ステータスラインはキャッシュ読込のみで**描画ごとの通信ゼロ**。更新はオンデマンドで、z.ai公式と**同一のリクエスト**を使います。 |
| ⚡ **AIエージェント不要** | 公式 `glm-plan-usage` プラグインと違い、更新はシェル1呼び出し（ミリ秒、約20秒ではありません）。 |

## 🤔 なぜこれが必要か

> [!IMPORTANT]
> z.ai の Coding Plan は **5時間**か**週次**ウィンドウを使い切ると制限がかかります。Claude Code 標準の `rate_limits` フィールドは **Claude.ai 専用**で z.ai では入らないため、別途取得が必要です。本ウィジェットはそれを安全に行います。

## 🛡️ BANを回避する仕組み

- ステータスラインは**ネットワーク通信を一切しない**。`~/.claude/zaiquota/quota.cache` を読むだけです。
- `/cc-zaiquota:refresh` は z.ai 公式 `glm-plan-usage` と**同一のリクエスト**（`GET {baseDomain}/api/monitor/usage/quota/limit`、`Authorization: $ANTHROPIC_AUTH_TOKEN`）。エンドポイントもヘッダも同じなので、公式ツールと区別がつきません。
- デフォルトはオンデマンドのみ（ポーリングループなし）。

## ♻️ 自動更新

`Stop` と `SessionStart` フック経由でキャッシュを自動更新します。毎ターン終了時とセッション開始時に走り、**`ZAI_REFRESH_MIN`（デフォルト600秒）に1回までスロットル**されます。使っている間は最新を保ち、アイドル中はポーリングしません。

- 間隔を調整: `~/.claude/zaiquota/config.env` に `ZAI_REFRESH_MIN=300`
- 即時更新: `/cc-zaiquota:refresh`（`--force` でスロットルを無視）

ステータスライン本体は**通信ゼロ**のまま。スロットル付きのフェッチャだけがAPIを叩きます。

## 🚀 インストール

> 環境変数 `ANTHROPIC_BASE_URL`＋`ANTHROPIC_AUTH_TOKEN`（公式プラグインと同じ）と [`jq`](https://stedolan.github.io/jq/) が必要です。

**A — プラグインで**

```bash
claude plugin marketplace add evggzzz/cc-zaiquota
claude plugin install cc-zaiquota@cc-zaiquota
```

そのあと Claude Code 上で：

```
/cc-zaiquota:refresh
```

**B — 1行で**

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash
```

どちらもスクリプトを `~/.claude/zaiquota/` に置き、`~/.claude/statusline-compose.sh` を生成して `statusLine` をそこに向けます（事前に `.bak` でバックアップ）。**Claude Code を再起動**し、`/cc-zaiquota:refresh` でキャッシュを取得してください。

## 🔬 仕組み

- `quota-fetch.sh` → `GET /api/monitor/usage/quota/limit` を叩き、`.data`＋タイムスタンプをキャッシュに保存。
- `quota.sh` → `data.limits[]` を解析。2つの `TOKENS_LIMIT` は 5h（`nextResetTime` が早い方）と週次（遅い方）、`TIME_LIMIT` は MCP月次。リセットまでの時間は絶対時刻 `nextResetTime` から毎回リアルタイムで計算します。
- `compose.sh` → cc-contextbar（1行目）と本ウィジェット（2行目）を順に実行。これを `statusLine` に設定します。

## ⚙️ カスタマイズ

`~/.claude/zaiquota/config.env` を作ってデフォルトを上書きできます：

| 変数 | デフォルト | 効果 |
|---|---|---|
| `ZAI_SEGMENTS` | `10` | バーのセル数 |
| `ZAI_FILL` / `ZAI_EMPTY` | `█` / `░` | バーの文字 |
| `ZAI_ICONS` | `0` | `1` でemojiアイコンを表示（ワイド端末向け） |
| `ZAI_REFRESH_MIN` | `600` | 自動更新の最小間隔（秒） |

```bash
# ~/.claude/zaiquota/config.env
ZAI_SEGMENTS=8
ZAI_ICONS=1
ZAI_REFRESH_MIN=300
```

## 🗑️ アンインストール

```bash
curl -fsSL https://raw.githubusercontent.com/evggzzz/cc-zaiquota/main/scripts/install.sh | bash -s -- --uninstall
```

`statusLine` を cc-contextbar に戻し（存在すれば）、`~/.claude/zaiquota/` を削除します。

## ⭐ Star History

<a href="https://star-history.com/#evggzzz/cc-zaiquota&Date">
  <img src="https://api.star-history.com/svg?repos=evggzzz/cc-zaiquota&type=Date" alt="Star History" width="600">
</a>

## 📄 ライセンス

MIT © [evggzzz](https://github.com/evggzzz)
