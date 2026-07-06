#!/bin/bash
# ADR-1404 に基づく危険コマンドガード
# PreToolUse フックとして stdin から JSON を受け取り、
# tool_input.command を検査して危険なコマンドをブロック（exit 2）または警告（exit 0）する。
#
# ブロック対象（exit 2）:
#   - rm（bash -c 越しのラップを含む）
#   - sudo
#   - git push --force / -f
#   - codex exec の危険オプション
#   - ディスク破壊系（dd / mkfs / diskutil eraseDisk / fdisk / parted）
#
# 警告のみ（exit 0）:
#   - 上記未該当の一般的な -f / --force
#
# 既知の限界: base64 等の難読化・多段ネストは検出できない。
# 脅威モデルは「うっかり実行・deny の素朴な迂回」まで。

set -euo pipefail

# jq の存在確認
if ! command -v jq >/dev/null 2>&1; then
  echo "[guard-dangerous-command] 警告: jq が見つかりません。コマンド検査をスキップします。" >&2
  exit 0
fi

# stdin から JSON を読み込み、コマンド文字列を取り出す
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

# コマンドが空の場合はスキップ
if [[ -z "$cmd" ]]; then
  exit 0
fi

# ブロックパターンの検査
# パターン1: rm コマンド（語境界で検出、bash -c ラップ越しも含む）
# \b は macOS の grep -E でも有効。grep -f ファイルオプションの -f は誤検知しない。
if echo "$cmd" | grep -qE '\brm\b'; then
  echo "[guard-dangerous-command] ブロック: rm コマンドが検出されました。" >&2
  echo "  代替: rm の代わりに trash コマンドを使用してください（例: trash ファイル名）" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# パターン2: sudo コマンド（語境界で検出）
if echo "$cmd" | grep -qE '\bsudo\b'; then
  echo "[guard-dangerous-command] ブロック: sudo コマンドが検出されました。" >&2
  echo "  sudo は使用禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# パターン3: git push に --force または -f（git push 限定）
if echo "$cmd" | grep -qE 'git[[:space:]]+push' && echo "$cmd" | grep -qE '(--force\b|-f\b)'; then
  echo "[guard-dangerous-command] ブロック: git push --force / -f が検出されました。" >&2
  echo "  強制プッシュは禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# パターン4: codex exec の危険オプション
if echo "$cmd" | grep -qE 'codex[[:space:]]+exec'; then
  if echo "$cmd" | grep -qE '(--dangerously-bypass-approvals-and-sandbox|-s[[:space:]]+danger-full-access|--ignore-rules|--dangerously-bypass-hook-trust)'; then
    echo "[guard-dangerous-command] ブロック: codex exec の危険オプションが検出されました。" >&2
    echo "  --dangerously-bypass-approvals-and-sandbox / -s danger-full-access / --ignore-rules / --dangerously-bypass-hook-trust は使用禁止です。" >&2
    echo "  検出されたコマンド: $cmd" >&2
    exit 2
  fi
fi

# パターン5: ディスク破壊系コマンド
# dd（語境界で検出）
if echo "$cmd" | grep -qE '\bdd\b'; then
  echo "[guard-dangerous-command] ブロック: dd コマンドが検出されました。" >&2
  echo "  ディスク操作系コマンドは禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# mkfs（前方一致）
if echo "$cmd" | grep -qE '\bmkfs\b'; then
  echo "[guard-dangerous-command] ブロック: mkfs コマンドが検出されました。" >&2
  echo "  ディスク操作系コマンドは禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# diskutil eraseDisk
if echo "$cmd" | grep -qE 'diskutil[[:space:]]+eraseDisk'; then
  echo "[guard-dangerous-command] ブロック: diskutil eraseDisk コマンドが検出されました。" >&2
  echo "  ディスク消去操作は禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# fdisk（語境界で検出）
if echo "$cmd" | grep -qE '\bfdisk\b'; then
  echo "[guard-dangerous-command] ブロック: fdisk コマンドが検出されました。" >&2
  echo "  ディスク操作系コマンドは禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# parted（語境界で検出）
if echo "$cmd" | grep -qE '\bparted\b'; then
  echo "[guard-dangerous-command] ブロック: parted コマンドが検出されました。" >&2
  echo "  ディスク操作系コマンドは禁止です。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  exit 2
fi

# 警告パターンの検査（BLOCK 未該当の一般的な -f / --force）
# git push の -f は上記でブロック済みのためここに到達した場合は git push ではない
if echo "$cmd" | grep -qE '(^|[[:space:]])-f([[:space:]]|$)' || echo "$cmd" | grep -qE '[[:space:]]--force\b'; then
  echo "[guard-dangerous-command] 警告: force フラグ（-f または --force）が検出されました。意図を確認してください。" >&2
  echo "  検出されたコマンド: $cmd" >&2
  # exit 0 で実行は許可（警告のみ）
fi

exit 0
