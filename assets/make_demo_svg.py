#!/usr/bin/env python3
"""Generate assets/demo.svg — a 2-line Claude Code statusline mock
(line 1: cc-contextbar, line 2: cc-zaiquota)."""
from html import escape

W, H = 840, 170
BG, BORDER = "#0d1117", "#30363d"
WHITE, GRAY, DIM = "#c9d1d9", "#8b949e", "#6e7681"
DARKSEG = "#21262d"
GREEN, YELLOW = "#3fb950", "#d29922"
DOTS = ["#ff5f56", "#ffbd2e", "#27c93f"]


def bar(x, y, filled, total, color, seg=13, gap=2, h=14):
    """Return SVG rects for a battery-style bar."""
    out = []
    for i in range(total):
        sx = x + i * (seg + gap)
        c = color if i < filled else DARKSEG
        out.append(f'      <rect x="{sx}" y="{y}" width="{seg}" height="{h}" rx="3" fill="{c}"/>')
    return "\n".join(out)


def robot(x, y):
    return f"""      <g transform="translate({x},{y})">
        <rect x="0" y="6" width="22" height="18" rx="5" fill="#6e7681"/>
        <circle cx="6.5" cy="15" r="2.4" fill="{GREEN}"/>
        <circle cx="15.5" cy="15" r="2.4" fill="{GREEN}"/>
        <circle cx="11" cy="2" r="2.2" fill="{GREEN}"/>
      </g>"""


def clock(x, y, c):
    return f"""      <g transform="translate({x},{y})">
        <circle cx="9" cy="11" r="8" fill="none" stroke="{c}" stroke-width="1.8"/>
        <line x1="9" y1="11" x2="9" y2="6" stroke="{c}" stroke-width="1.8" stroke-linecap="round"/>
        <line x1="9" y1="11" x2="13" y2="13" stroke="{c}" stroke-width="1.8" stroke-linecap="round"/>
      </g>"""


parts = [f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" fill="none" role="img" aria-label="cc-zaiquota demo">
  <rect width="{W}" height="{H}" rx="14" fill="{BG}" stroke="{BORDER}" stroke-width="1.5"/>''']

# chrome
for i, c in enumerate(DOTS):
    parts.append(f'  <circle cx="{24 + i*22}" cy="22" r="6" fill="{c}"/>')
parts.append(f'  <text x="{W//2}" y="27" text-anchor="middle" font-family="sans-serif" font-size="13" fill="#484f58">Claude Code</text>')
parts.append(f'  <line x1="14" y1="42" x2="{W-14}" y2="42" stroke="{DARKSEG}" stroke-width="1"/>')

parts.append('  <g font-family="ui-monospace,SFMono-Regular,Menlo,monospace" text-rendering="geometricPrecision">')

# line 1 — cc-contextbar
parts.append(robot(28, 68))
parts.append(f'  <text x="60" y="86" font-size="17" fill="{WHITE}">glm-5.2</text>')
parts.append(f'  <text x="150" y="86" font-size="17" fill="{DIM}">·</text>')
parts.append(bar(170, 74, filled=4, total=10, color=GREEN))
parts.append(f'  <text x="306" y="86" font-size="17" fill="{WHITE}">42%</text>')
parts.append(f'  <text x="346" y="86" font-size="17" fill="{DIM}">·</text>')
parts.append(f'  <text x="364" y="86" font-size="17" fill="{GREEN}">$1.23</text>')

# line 2 — cc-zaiquota
parts.append(clock(28, 104, YELLOW))
parts.append(f'  <text x="60" y="124" font-size="16" fill="{GRAY}">5h</text>')
parts.append(bar(86, 113, filled=5, total=10, color=YELLOW, seg=12, gap=2, h=12))
parts.append(f'  <text x="214" y="124" font-size="16" fill="{WHITE}">56%</text>')
parts.append(f'  <text x="252" y="124" font-size="13" fill="{DIM}">2h22m</text>')
parts.append(f'  <text x="306" y="124" font-size="16" fill="{DIM}">·</text>')
parts.append(f'  <text x="320" y="124" font-size="16" fill="{GRAY}">wk</text>')
parts.append(bar(346, 113, filled=1, total=10, color=GREEN, seg=12, gap=2, h=12))
parts.append(f'  <text x="474" y="124" font-size="16" fill="{WHITE}">15%</text>')
parts.append(f'  <text x="512" y="124" font-size="13" fill="{DIM}">6d7h</text>')
parts.append(f'  <text x="560" y="124" font-size="16" fill="{DIM}">·</text>')
parts.append(f'  <text x="574" y="124" font-size="16" fill="{GREEN}">MCP 1%</text>')
parts.append(f'  <text x="640" y="124" font-size="13" fill="{DIM}">· 0m</text>')

parts.append('  </g>')
parts.append('</svg>')

svg = "\n".join(parts)
with open("demo.svg", "w") as f:
    f.write(svg)
print(f"wrote demo.svg ({len(svg)} bytes)")
