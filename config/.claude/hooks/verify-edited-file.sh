#!/bin/bash
# ADR-2038 に基づく編集後ファイル検証フック
# PostToolUse フックとして stdin から JSON を受け取り、
# 編集・書き込みされたファイルの構文・lint を非破壊・非ブロックで確認する。
#
# 対応拡張子:
#   .rb   → rubocop（存在すれば）または ruby -c
#   .sh   → bash -n
#   .yml / .yaml → yq（存在すれば）または python3 で yaml.safe_load
#   .json → jq empty
#   その他 → no-op
#
# 設計原則:
#   - 自動修正は行わない（rubocop に -a/-A を付けない）
#   - チェッカが不在なら静かに skip
#   - 問題は stderr に「警告:」付きで出力
#   - 常に exit 0（非ブロック）でワークフローを止めない

set -uo pipefail

# jq の存在確認
if ! command -v jq >/dev/null 2>&1; then
  echo "[verify-edited-file] 警告: jq が見つかりません。ファイル検証をスキップします。" >&2
  exit 0
fi

# stdin から JSON を読み込み、対象ファイルパスを取り出す
input=$(cat)

# PostToolUse の JSON 構造: tool_input.file_path に編集対象ファイルパスが入る
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# ファイルパスが空の場合はスキップ
if [[ -z "$file_path" ]]; then
  exit 0
fi

# ファイルが存在しない場合はスキップ
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# 拡張子を取得（小文字正規化）
ext="${file_path##*.}"
ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

# 拡張子別に構文チェックを実行
case "$ext" in
  rb)
    # Ruby: rubocop があれば実行（自動修正なし）、なければ ruby -c でフォールバック。
    # ファイル名がハイフン始まりでもオプションと誤解釈されないよう -- 区切りを入れる。
    if command -v rubocop >/dev/null 2>&1; then
      # 二重実行を避けるため、出力を一時ファイルに取って判定と先頭30行出力を1回で賄う。
      rubocop_out=$(mktemp)
      if ! rubocop --no-color -- "$file_path" >"$rubocop_out" 2>&1; then
        echo "[verify-edited-file] 警告: rubocop が問題を検出しました: $file_path" >&2
        head -30 "$rubocop_out" >&2
      fi
      # 一時ファイルは trash で片付ける（rm は使わない）。trash 不在時はそのまま放置。
      if command -v trash >/dev/null 2>&1; then
        trash "$rubocop_out" >/dev/null 2>&1 || true
      fi
    elif command -v ruby >/dev/null 2>&1; then
      if ! ruby -c -- "$file_path" >/dev/null 2>&1; then
        echo "[verify-edited-file] 警告: ruby -c が構文エラーを検出しました: $file_path" >&2
        ruby -c -- "$file_path" >&2 2>&1
      fi
    fi
    ;;
  sh)
    # Shell: bash -n で構文チェック
    if command -v bash >/dev/null 2>&1; then
      if ! bash -n -- "$file_path" 2>/dev/null; then
        echo "[verify-edited-file] 警告: bash -n が構文エラーを検出しました: $file_path" >&2
        bash -n -- "$file_path" >&2 2>&1
      fi
    fi
    ;;
  yml|yaml)
    # YAML: yq があれば実行、なければ python3 で yaml.safe_load
    # yq（mikefarah 版 v4 系）は -- 区切りに対応するため付与する。
    if command -v yq >/dev/null 2>&1; then
      if ! yq '.' -- "$file_path" >/dev/null 2>&1; then
        echo "[verify-edited-file] 警告: yq が YAML 構文エラーを検出しました: $file_path" >&2
        yq '.' -- "$file_path" >&2 2>&1
      fi
    # python3 フォールバックは PyYAML が import できる場合のみ実行する。
    # PyYAML 不在環境で ModuleNotFoundError を構文エラーと誤警告しないよう、
    # チェッカ不在 = skip の設計に合わせて静かに skip する。
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
      # ファイルパスは引数で渡す（sys.argv[1]）ためオプション誤解釈の懸念はない。
      if ! python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" "$file_path" 2>/dev/null; then
        echo "[verify-edited-file] 警告: python3(yaml) が YAML 構文エラーを検出しました: $file_path" >&2
        python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" "$file_path" >&2 2>&1
      fi
    fi
    ;;
  json)
    # JSON: jq empty で構文チェック（jq は冒頭で確認済み）
    if ! jq empty -- "$file_path" 2>/dev/null; then
      echo "[verify-edited-file] 警告: jq が JSON 構文エラーを検出しました: $file_path" >&2
      jq empty -- "$file_path" >&2 2>&1
    fi
    ;;
  *)
    # その他の拡張子は no-op
    ;;
esac

# 常に exit 0（非ブロック）
exit 0
