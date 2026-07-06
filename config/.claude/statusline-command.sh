#!/usr/bin/env python3
"""Claude Code ステータスライン - Braille Dots表示"""
import json, sys, os, subprocess

data = json.load(sys.stdin)

BRAILLE = ' \u28c0\u28c4\u28e4\u28e6\u28f6\u28f7\u28ff'
R = '\033[0m'
DIM = '\033[2m'

def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'
    else:
        g = int(200 - (pct - 50) * 4)
        return f'\033[38;2;255;{max(g, 0)};60m'

def braille_bar(pct, width=8):
    pct = min(max(pct, 0), 100)
    level = pct / 100
    bar = ''
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            bar += BRAILLE[7]
        elif level <= seg_start:
            bar += BRAILLE[0]
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            bar += BRAILLE[min(int(frac * 7), 7)]
    return bar

def fmt(label, pct):
    p = round(pct)
    return f'{DIM}{label}{R} {gradient(pct)}{braille_bar(pct)}{R} {p}%'

# --- モデル名 ---
model = data.get('model', {}).get('display_name', 'Claude')

parts = [model]

# --- コンテキストウィンドウ使用率 ---
ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    parts.append(fmt('ctx', ctx))

# --- レートリミット ---
five = data.get('rate_limits', {}).get('five_hour', {}).get('used_percentage')
if five is not None:
    parts.append(fmt('5h', five))

week = data.get('rate_limits', {}).get('seven_day', {}).get('used_percentage')
if week is not None:
    parts.append(fmt('7d', week))

# --- コスト ---
cost = data.get('cost', {}).get('total_cost_usd', 0)
parts.append(f'\033[33m${cost:.2f}{R}')

# --- ディレクトリ & Gitブランチ ---
current_dir = data.get('workspace', {}).get('current_dir', '')
if current_dir:
    dir_name = os.path.basename(current_dir)
    git_part = f'\033[36m{dir_name}{R}'
    try:
        branch = subprocess.run(
            ['git', 'branch', '--show-current'],
            capture_output=True, text=True, cwd=current_dir
        ).stdout.strip()
        if branch:
            git_part += f' \033[35m({branch}){R}'
    except Exception:
        pass
    parts.append(git_part)

print(f' {DIM}\u2502{R} '.join(parts), end='')
