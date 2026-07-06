#!/bin/bash
# check_public.sh - ステージ済み変更が public リポジトリへ公開可能かを検証するスクリプト
#
# 概要:
#   `etc/public_allowlist.txt` の許可リストと突合し、リスト外のステージ済み
#   ファイルが無いことを確認する（既定非公開）。加えて git-secrets による
#   シークレットスキャンを実施し、多層防御とする。
#
# 前提:
#   git-secrets がインストール済みで、このリポジトリに設定済みであること。
#   未導入の場合はフォールバックせず警告して終了する。
#
# 使用方法:
#   bash etc/check_public.sh

set -eu

# dotfilesリポジトリのパス
DOTPATH="${DOTPATH:-$(cd "$(dirname "$0")/.." && pwd)}"
ALLOWLIST="${DOTPATH}/etc/public_allowlist.txt"

if [ ! -f "$ALLOWLIST" ]; then
  echo "エラー: 許可リストが見つかりません: ${ALLOWLIST}" >&2
  exit 1
fi

# 許可リストを読み込む（コメント行・空行を除外）
allow_patterns=()
while IFS= read -r line; do
  # 前後の空白を除去
  trimmed="${line#"${line%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  [ -z "$trimmed" ] && continue
  [[ "$trimmed" == \#* ]] && continue
  allow_patterns+=("$trimmed")
done < "$ALLOWLIST"

# 指定パスが許可リストのいずれかのパターンにマッチするか判定する
is_allowed() {
  local path="$1"
  local pattern
  for pattern in "${allow_patterns[@]}"; do
    # shellcheck disable=SC2053
    # パターン側をクオートしない: bash の [[ ]] はクオートするとリテラル比較に
    # なり、`*` がワイルドカードとして機能しなくなるため意図的に外している
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# ステージ済みファイル一覧を取得（削除は突合対象外）
staged_files=()
while IFS= read -r -d '' file; do
  [ -z "$file" ] && continue
  staged_files+=("$file")
done < <(git -C "$DOTPATH" diff --cached --name-only --diff-filter=d -z)

if [ ${#staged_files[@]} -eq 0 ]; then
  echo "ステージ済みの変更がありません。"
  exit 0
fi

echo "==> 許可リスト突合:"
echo ""

out_of_list=()
for file in "${staged_files[@]}"; do
  if is_allowed "$file"; then
    echo "[OK] ${file}"
  else
    echo "[NG] ${file} (許可リスト外)"
    out_of_list+=("$file")
  fi
done

echo ""

if [ ${#out_of_list[@]} -gt 0 ]; then
  echo "許可リスト外のステージ済みファイル (${#out_of_list[@]}):"
  for f in "${out_of_list[@]}"; do
    echo "  - $f"
  done
  echo ""
fi

# git-secrets によるシークレットスキャン
echo "==> git-secrets スキャン:"
echo ""

if ! command -v git-secrets > /dev/null 2>&1; then
  echo "エラー: git-secrets が未導入です。フォールバックせず中断します。" >&2
  echo "対処: 'brew install git-secrets' 等でインストールし、'git secrets --install' 'git secrets --register-aws' を実行してください。" >&2
  exit 1
fi

secrets_scan_ok=1
if ! git -C "$DOTPATH" secrets --scan --cached; then
  secrets_scan_ok=0
fi

echo ""
echo "==> Summary"

if [ ${#out_of_list[@]} -eq 0 ] && [ "$secrets_scan_ok" -eq 1 ]; then
  echo "公開可: 許可リスト外の項目なし、git-secrets スキャンも通過しました。"
  exit 0
else
  echo "公開不可: 上記の問題を解消してください。"
  exit 1
fi
