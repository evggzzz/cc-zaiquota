// cc-zaiquota statusline mod.
//
// Renders the quota line itself and pins it under the prompt ($.ui.status).
// The provider this session talks to picks the data source:
//
//   z.ai sessions      (ANTHROPIC_BASE_URL contains z.ai)
//                      -> ~/.claude/zaiquota/quota.cache (refreshed by the
//                         launchd/cron daemon; rendering stays network-free)
//   Anthropic sessions (plain CLI, GUI, anything else)
//                      -> ~/.claude/zaiquota/rate_limits.json, the mirror the
//                         statusline command (scripts/mirror.sh) writes from
//                         the stdin JSON Claude Code feeds it — the official
//                         rate_limits channel for Pro/Max/Ultra
//
// A 30s tick keeps the reset countdowns moving while the session is open.
// Pin it with ZAI_PROVIDER in config.env, same as the bash composer.
import type { Register } from 'claude-code'

const SEGMENTS = 10
const TICK_MS = 30000

function bar(pct: number): string {
  const filled = Math.max(0, Math.min(SEGMENTS, Math.floor((pct * SEGMENTS) / 100)))
  return '█'.repeat(filled) + '░'.repeat(SEGMENTS - filled)
}

function remain(targetSec: number, nowSec: number): string {
  const r = Math.max(0, Math.floor(targetSec) - nowSec)
  const d = Math.floor(r / 86400)
  const h = Math.floor((r % 86400) / 3600)
  const m = Math.floor((r % 3600) / 60)
  if (d > 0) return `${d}d${h}h`
  if (h > 0) return `${h}h${m}m`
  return `${m}m`
}

function seg(label: string, pct: number, resetTxt: string): string {
  return `${label} [${bar(pct)}] ${Math.floor(pct)}% ${resetTxt}`
}

async function readJson($: any, path: string): Promise<any> {
  try {
    const raw = await $.fs.read(path)
    if (typeof raw !== 'string') return undefined
    return JSON.parse(raw)
  } catch {
    return undefined
  }
}

// config.env is the installer's shell file (KEY=value); pick one key out of it.
async function readEnvKey($: any, path: string, key: string): Promise<string> {
  try {
    const raw = await $.fs.read(path)
    if (typeof raw !== 'string') return ''
    const line = raw.split('\n').find((l) => l.startsWith(`${key}=`))
    return line ? line.slice(key.length + 1).trim() : ''
  } catch {
    return ''
  }
}

async function render($: any): Promise<void> {
  let home = await $.env.get('HOME')
  home = typeof home === 'string' && home ? home : ''
  const base = await $.env.get('ANTHROPIC_BASE_URL')
  const pinned = await readEnvKey($, `${home}/.claude/zaiquota/config.env`, 'ZAI_PROVIDER')
  const provider =
    pinned || (/z\.ai/.test(typeof base === 'string' ? base : '') ? 'zai' : 'anthropic')

  if (provider === 'zai') {
    const cache = await readJson($, `${home}/.claude/zaiquota/quota.cache`)
    const limits: any[] = cache?.data?.limits ?? []
    const tokens = limits
      .filter((l: any) => l?.type === 'TOKENS_LIMIT')
      .sort((a: any, b: any) => (a?.nextResetTime ?? 0) - (b?.nextResetTime ?? 0))
    const mcp = limits.find((l: any) => l?.type === 'TIME_LIMIT')
    if (!tokens.length && !mcp) {
      $.ui.status('⏳ z.ai quota: run /cc-zaiquota:refresh')
      return
    }
    const nowSec = Math.floor((await $.clock.now()) / 1000)
    const parts: string[] = []
    if (tokens[0]) {
      parts.push(seg('5h', tokens[0].percentage ?? 0, remain((tokens[0].nextResetTime ?? 0) / 1000, nowSec)))
    }
    if (tokens[1]) {
      parts.push(seg('wk', tokens[1].percentage ?? 0, remain((tokens[1].nextResetTime ?? 0) / 1000, nowSec)))
    }
    if (mcp) parts.push(`MCP ${Math.floor(mcp.percentage ?? 0)}%`)
    $.ui.status(`⏳ ${parts.join(' · ')}`)
    return
  }

  // Anthropic session: the mirror carries rate_limits (epoch-second resets_at).
  const mirror = await readJson($, `${home}/.claude/zaiquota/rate_limits.json`)
  const rl = mirror?.rate_limits ?? {}
  const five = rl.five_hour
  const week = rl.seven_day
  const nowSec = Math.floor((await $.clock.now()) / 1000)
  const parts: string[] = []
  if (typeof five?.used_percentage === 'number') {
    parts.push(seg('5h', five.used_percentage, remain(five.resets_at ?? 0, nowSec)))
  }
  if (typeof week?.used_percentage === 'number') {
    parts.push(seg('wk', week.used_percentage, remain(week.resets_at ?? 0, nowSec)))
  }
  $.ui.status(parts.length ? `⏳ ${parts.join(' · ')}` : '⏳ 5h/wk quota appears after the first API response')
}

export const register: Register = (on) => {
  on('session.start', async ($, e, next) => {
    const tick = async () => {
      try {
        await render($)
      } catch {
        // keep the previous line on a transient read error
      }
    }
    $.clock.every(TICK_MS, () => {
      void tick()
    })
    await tick()
    return next(e)
  }).catch(async (_$, e, next) => {
    if (!next.called) await next(e)
  })
}
