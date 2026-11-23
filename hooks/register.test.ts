import { expect, test } from 'claude-code/testing'

const ZAI_CACHE = JSON.stringify({
  fetched_at: 1795270509,
  data: {
    limits: [
      { type: 'TOKENS_LIMIT', percentage: 20.4, nextResetTime: 1795299000000 },
      { type: 'TOKENS_LIMIT', percentage: 35, nextResetTime: 1795900000000 },
      { type: 'TIME_LIMIT', percentage: 24 },
    ],
  },
})

const MIRROR = JSON.stringify({
  fetched_at: 1795270509,
  rate_limits: {
    five_hour: { used_percentage: 23, resets_at: 1795299000 },
    seven_day: { used_percentage: 41, resets_at: 1795900000 },
  },
})

function seed($: any, on: any, opts: { base: string; files: Record<string, string> }) {
  const seen: (string | undefined)[] = []
  on('ui.status', (_$, e: any) => {
    seen.push(e?.text)
    return { value: null }
  })
  on('env.get', (_$, e: any) => ({ value: e?.name === 'HOME' ? '/home/tester' : opts.base }))
  on('fs.read', (_$, e: any) => {
    const p: string = e?.path ?? ''
    const hit = Object.entries(opts.files).find(([suffix]) => p.endsWith(suffix))
    if (!hit) throw new Error(`unexpected read: ${p}`)
    return { value: hit[1] }
  })
  on('clock.now', () => ({ value: 1795270509000 }))
  on('clock.every', () => ({ value: {} }))
  on('session.start', (_$, e: any) => ({
    cwd: e?.cwd,
    surface: e?.surface,
    isInteractive: e?.isInteractive,
  }))
  return seen
}

test('z.ai session renders the cached quota line', async ($, on) => {
  const seen = seed($, on, {
    base: 'https://api.z.ai/api/anthropic',
    files: {
      'config.env': 'ANTHROPIC_AUTH_TOKEN=x\n',
      'quota.cache': ZAI_CACHE,
    },
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const line = seen.at(-1)
  expect(line).toContain('5h')
  expect(line).toContain('20%')
  expect(line).toContain('wk')
  expect(line).toContain('35%')
  expect(line).toContain('MCP 24%')
  expect(line).not.toContain('░░░░░░░░░░') // a bar, not an empty one
})

test('anthropic session renders the mirrored rate_limits', async ($, on) => {
  const seen = seed($, on, {
    base: '',
    files: { 'rate_limits.json': MIRROR },
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const line = seen.at(-1)
  expect(line).toContain('5h')
  expect(line).toContain('23%')
  expect(line).toContain('wk')
  expect(line).toContain('41%')
  expect(line).not.toContain('MCP')
})

test('anthropic session with no data yet shows the placeholder', async ($, on) => {
  const seen = seed($, on, {
    base: '',
    files: { 'rate_limits.json': JSON.stringify({ fetched_at: 1, rate_limits: {} }) },
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  expect(seen.at(-1)).toContain('first API response')
})

test('a ZAI_PROVIDER pin in config.env beats the base URL', async ($, on) => {
  const seen = seed($, on, {
    base: 'https://api.z.ai/api/anthropic',
    files: {
      'config.env': 'ZAI_PROVIDER=anthropic\nANTHROPIC_AUTH_TOKEN=x\n',
      'rate_limits.json': MIRROR,
    },
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  expect(seen.at(-1)).toContain('23%')
  expect(seen.at(-1)).not.toContain('MCP')
})

test('a z.ai cache older than two refresh intervals is flagged stale', async ($, on) => {
  // clock.now is pinned to 1795270509000; fetched_at is one hour older
  const seen = seed($, on, {
    base: 'https://api.z.ai/api/anthropic',
    files: {
      'config.env': '',
      'quota.cache': JSON.stringify({
        fetched_at: 1795266900,
        data: {
          limits: [
            { type: 'TOKENS_LIMIT', percentage: 20, nextResetTime: 1795299000000 },
            { type: 'TOKENS_LIMIT', percentage: 35, nextResetTime: 1795900000000 },
            { type: 'TIME_LIMIT', percentage: 24 },
          ],
        },
      }),
    },
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  expect(seen.at(-1)).toContain('stale')
  expect(seen.at(-1)).toContain('1h')
})

test('a fresh cache shows no stale marker', async ($, on) => {
  const seen = seed($, on, {
    base: 'https://api.z.ai/api/anthropic',
    files: { 'config.env': '', 'quota.cache': ZAI_CACHE }, // fetched_at 1795270509 == pinned now
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  expect(seen.at(-1)).not.toContain('stale')
})
