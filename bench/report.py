#!/usr/bin/env python3
"""Turn hyperfine's JSON into bench/results.md and light/dark SVG bar charts."""
import json, platform, subprocess, sys, datetime, html

src, out = sys.argv[1], sys.argv[2]
data = json.load(open(src))["results"]

def stats(r):
    # hyperfine >= 2.0 nests wall-clock stats under summary.time_wall_clock; 1.x is flat
    w = r.get("summary", {}).get("time_wall_clock")
    if w is None:
        w = {"mean": r["mean"], "stddev": r["stddev"], "min": r["min"]}
    return r.get("name") or r["command"], w["mean"] * 1000, (w.get("stddev") or 0) * 1000, w["min"] * 1000

rows = sorted((stats(r) for r in data), key=lambda r: r[1])

def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True).strip()
    except Exception: return "?"

cpu = sh("sysctl -n machdep.cpu.brand_string 2>/dev/null || lscpu | sed -n 's/Model name: *//p'")
osv = sh("sw_vers -productVersion 2>/dev/null || uname -sr")
zsh = sh("zsh --version")
when = datetime.date.today().isoformat()

# ── markdown ─────────────────────────────────────────────────────────────────
md = ["| setup | mean | min |", "|---|---:|---:|"]
for name, mean, sd, mn in rows:
    md.append(f"| {name} | {mean:.1f} ms ± {sd:.1f} | {mn:.1f} ms |")
md.append("")
md.append(f"{cpu}, macOS {osv}, {zsh}, {when}. hyperfine, {len(data)} setups, `zsh -i -c exit`.")
open(f"{out}/results.md", "w").write("\n".join(md) + "\n")

# ── svg ──────────────────────────────────────────────────────────────────────
def svg(path, bg, fg, muted, bar, bar_hi, grid):
    W, lab_w, right, row_h, top = 760, 250, 70, 30, 20
    H = top + row_h * len(rows) + 30
    maxv = max(r[1] for r in rows)
    scale = (W - lab_w - right) / (maxv * 1.05)
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="-apple-system, Segoe UI, Helvetica, Arial, sans-serif" font-size="13">',
         f'<rect width="{W}" height="{H}" fill="{bg}"/>']
    # grid
    step = 10 if maxv < 120 else 25
    v = 0
    while v <= maxv * 1.05:
        x = lab_w + v * scale
        o.append(f'<line x1="{x:.1f}" y1="{top - 6}" x2="{x:.1f}" y2="{H - 26}" stroke="{grid}" stroke-width="1"/>')
        o.append(f'<text x="{x:.1f}" y="{H - 10}" fill="{muted}" text-anchor="middle" font-size="11">{v}</text>')
        v += step
    for i, (name, mean, sd, mn) in enumerate(rows):
        y = top + i * row_h
        hi = name.startswith("zflash")
        o.append(f'<text x="{lab_w - 10}" y="{y + 19}" fill="{fg}" text-anchor="end"{" font-weight=\"600\"" if hi else ""}>{html.escape(name)}</text>')
        o.append(f'<rect x="{lab_w}" y="{y + 6}" width="{mean * scale:.1f}" height="{row_h - 12}" rx="3" fill="{bar_hi if hi else bar}"/>')
        o.append(f'<text x="{lab_w + mean * scale + 6:.1f}" y="{y + 19}" fill="{fg}" font-size="12">{mean:.0f} ms</text>')
    o.append(f'<text x="{W - 8}" y="{H - 10}" fill="{muted}" text-anchor="end" font-size="11">ms, mean of {len(data)} setups × hyperfine runs · {when}</text>')
    o.append("</svg>")
    open(path, "w").write("\n".join(o))

svg(f"{out}/chart.svg",      bg="#ffffff", fg="#1f2328", muted="#656d76", bar="#8c959f", bar_hi="#0969da", grid="#eaeef2")
svg(f"{out}/chart-dark.svg", bg="#0d1117", fg="#e6edf3", muted="#8d96a0", bar="#6e7681", bar_hi="#58a6ff", grid="#21262d")
