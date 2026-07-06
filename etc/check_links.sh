#!/bin/bash
# check_links.sh - シンボリックリンクの状態検証スクリプト
#
# 概要:
#   config/ 以下のファイルおよびディレクトリが、ホームディレクトリに正しく
#   シンボリックリンクされているかを検証する。
#
# 前提:
#   このスクリプトは cookbooks/dotfiles/default.rb と同じリンクロジックを
#   前提としている。default.rb を変更した場合は本スクリプトも更新すること。
#
# リンクモード:
#   1. ディレクトリ単位リンク: node.json の directory_links で指定
#   2. ファイル単位リンク: config/ 以下の全ファイル（directory_links 配下を除く）
#   3. テンプレートコピー: node.json の template_copy_targets で指定
#
# 依存:
#   - jq (node.json のパース用)
#
# 使用方法:
#   bash etc/check_links.sh          通常モード（全リンク状態を表示）
#   bash etc/check_links.sh --diff   差分モード（変更が必要なリンクのみ表示）

set -eu

# 引数解析
DIFF_MODE=0
for arg in "$@"; do
  case "$arg" in
    --diff) DIFF_MODE=1 ;;
  esac
done

# diffモード用の差分情報を蓄積する配列
diff_entries=()

# dotfilesリポジトリのパス
DOTPATH="${DOTPATH:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG_PATH="${DOTPATH}/config"
HOME_DIR="${HOME}"
NODE_JSON="${DOTPATH}/node.json"

# node.jsonからdirectory_linksを読み取り（存在しない場合は空配列にフォールバック）
dir_links=()
template_sources=()
template_destinations=()
if [ -f "$NODE_JSON" ]; then
  while IFS= read -r entry; do
    [ -n "$entry" ] && dir_links+=("$entry")
  done < <(jq -r '.directory_links // [] | .[]' "$NODE_JSON")

  while IFS= read -r entry; do
    [ -n "$entry" ] && template_sources+=("$entry")
  done < <(jq -r '.template_copy_targets // [] | .[] | .source' "$NODE_JSON")

  while IFS= read -r entry; do
    [ -n "$entry" ] && template_destinations+=("$entry")
  done < <(jq -r '.template_copy_targets // [] | .[] | .destination' "$NODE_JSON")
fi

# ディレクトリリンクの検証
if [ "$DIFF_MODE" -eq 0 ]; then
  echo "==> Directory links:"
  echo ""
fi

dir_issues=()

for rel_dir in "${dir_links[@]+"${dir_links[@]}"}"; do
  # 空要素をスキップ（dir_linksが空の場合の安全策）
  [ -z "$rel_dir" ] && continue

  home_path="${HOME_DIR}/${rel_dir}"
  expected_target="${CONFIG_PATH}/${rel_dir}"

  if [ -h "$home_path" ]; then
    # シンボリックリンクが存在する場合、リンク先を確認
    link_target=$(readlink "$home_path")
    # 相対パスと絶対パスの両方を考慮して比較
    resolved_target=$(cd "$(dirname "$home_path")" && realpath "$link_target" 2>/dev/null || echo "$link_target")
    resolved_expected=$(realpath "$expected_target" 2>/dev/null || echo "$expected_target")
    if [ "$resolved_target" = "$resolved_expected" ] || [ "$link_target" = "$expected_target" ]; then
      if [ "$DIFF_MODE" -eq 0 ]; then
        echo "[OK] ${rel_dir} -> ${link_target}"
      fi
    else
      if [ "$DIFF_MODE" -eq 0 ]; then
        echo "[WRONG] ${rel_dir} -> ${link_target} (期待値: ${expected_target})"
      else
        diff_entries+=("~ ${rel_dir}: ${link_target} -> ${expected_target}  (directory link, fix target)")
      fi
      dir_issues+=("$rel_dir")
    fi
  elif [ -d "$home_path" ]; then
    # 通常ディレクトリが存在する場合
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[DIR] ${rel_dir} (シンボリックリンクではなく通常ディレクトリが存在します)"
    else
      diff_entries+=("~ ${rel_dir} -> ${expected_target}  (directory link, replace directory)")
    fi
    dir_issues+=("$rel_dir")
  else
    # 何も存在しない場合
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[MISSING] ${rel_dir}"
    else
      diff_entries+=("+ ${rel_dir} -> ${expected_target}  (directory link, new)")
    fi
    dir_issues+=("$rel_dir")
  fi
done

if [ "$DIFF_MODE" -eq 0 ]; then
  echo ""
fi

# エイリアスリンクの検証（ホームディレクトリ内のクロスリファレンス）
alias_issues=()

if [ -f "$NODE_JSON" ] && jq -e '.alias_links // empty' "$NODE_JSON" &>/dev/null; then
  if [ "$DIFF_MODE" -eq 0 ]; then
    echo "==> Alias links:"
    echo ""
  fi

  while IFS=$'\t' read -r link_rel target_rel; do
    [ -z "$link_rel" ] && continue

    home_path="${HOME_DIR}/${link_rel}"
    expected_target="${HOME_DIR}/${target_rel}"

    if [ -h "$home_path" ]; then
      link_target=$(readlink "$home_path")
      resolved_target=$(cd "$(dirname "$home_path")" && realpath "$link_target" 2>/dev/null || echo "$link_target")
      resolved_expected=$(realpath "$expected_target" 2>/dev/null || echo "$expected_target")
      if [ "$resolved_target" = "$resolved_expected" ] || [ "$link_target" = "$expected_target" ]; then
        if [ "$DIFF_MODE" -eq 0 ]; then
          echo "[OK] ${link_rel} -> ${link_target}"
        fi
      else
        if [ "$DIFF_MODE" -eq 0 ]; then
          echo "[WRONG] ${link_rel} -> ${link_target} (期待値: ${expected_target})"
        else
          diff_entries+=("~ ${link_rel}: ${link_target} -> ${expected_target}  (alias link, fix target)")
        fi
        alias_issues+=("$link_rel")
      fi
    elif [ -e "$home_path" ]; then
      if [ "$DIFF_MODE" -eq 0 ]; then
        echo "[FILE/DIR] ${link_rel} (シンボリックリンクではなくファイル/ディレクトリが存在します)"
      else
        diff_entries+=("~ ${link_rel} -> ${expected_target}  (alias link, replace)")
      fi
      alias_issues+=("$link_rel")
    else
      if [ "$DIFF_MODE" -eq 0 ]; then
        echo "[MISSING] ${link_rel}"
      else
        diff_entries+=("+ ${link_rel} -> ${expected_target}  (alias link, new)")
      fi
      alias_issues+=("$link_rel")
    fi
  done < <(jq -r '.alias_links | to_entries[] | [.key, .value] | @tsv' "$NODE_JSON")

  if [ "$DIFF_MODE" -eq 0 ]; then
    echo ""
  fi
fi

# ファイルリンクの検証
if [ "$DIFF_MODE" -eq 0 ]; then
  echo "==> File links:"
  echo ""
fi

unlinked_files=()
broken_links=()
dangling_links=()

# directory_linksのパスに前方一致するファイルを除外する関数
is_under_dir_link() {
  local rel_path="$1"
  for dir_link in "${dir_links[@]+"${dir_links[@]}"}"; do
    [ -z "$dir_link" ] && continue
    # 前方一致: rel_pathがdir_link/で始まるか、完全一致するか
    if [[ "$rel_path" == "${dir_link}/"* ]] || [[ "$rel_path" == "$dir_link" ]]; then
      return 0
    fi
  done
  return 1
}

is_template_source() {
  local rel_path="$1"
  for template_source in "${template_sources[@]+"${template_sources[@]}"}"; do
    [ -z "$template_source" ] && continue
    if [ "$rel_path" = "$template_source" ]; then
      return 0
    fi
  done
  return 1
}

# config/以下の全ファイルをチェック
while IFS= read -r -d '' file; do
  # config/からの相対パス
  relative_path="${file#$CONFIG_PATH/}"

  # .DS_Storeは除外
  if [[ "$relative_path" == *".DS_Store"* ]]; then
    continue
  fi

  # directory_links配下のファイルは除外
  if is_under_dir_link "$relative_path"; then
    continue
  fi

  # template_copy_targets の source はシンボリックリンク検証から除外
  if is_template_source "$relative_path"; then
    continue
  fi

  # ホームディレクトリの対応するパス
  home_path="${HOME_DIR}/${relative_path}"

  if [ -h "$home_path" ]; then
    # シンボリックリンクが存在する場合（壊れたリンクも検出）
    if [ -e "$home_path" ]; then
      # リンク先が存在する場合、リンク先を確認
      link_target=$(readlink "$home_path")
      if [ "$link_target" = "$file" ]; then
        if [ "$DIFF_MODE" -eq 0 ]; then
          echo "[OK] ${relative_path}"
        fi
      else
        if [ "$DIFF_MODE" -eq 0 ]; then
          echo "[WRONG] ${relative_path} -> ${link_target} (期待値: ${file})"
        else
          diff_entries+=("~ ${relative_path}: ${link_target} -> ${file}  (fix target)")
        fi
        broken_links+=("$relative_path")
      fi
    else
      # リンク先が存在しない（dangling symlink）
      link_target=$(readlink "$home_path")
      if [ "$DIFF_MODE" -eq 0 ]; then
        echo "[DANGLING] ${relative_path} -> ${link_target} (リンク先が存在しません)"
      else
        diff_entries+=("! ${relative_path} -> ${link_target}  (dangling symlink)")
      fi
      dangling_links+=("$relative_path")
    fi
  elif [ -e "$home_path" ]; then
    # 通常のファイルが存在する場合
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[FILE] ${relative_path} (シンボリックリンクではなくファイルが存在します)"
    else
      diff_entries+=("~ ${relative_path} -> ${file}  (replace file)")
    fi
    unlinked_files+=("$relative_path")
  else
    # ファイルもリンクも存在しない場合
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[MISSING] ${relative_path}"
    else
      diff_entries+=("+ ${relative_path} -> ${file}  (new link)")
    fi
    unlinked_files+=("$relative_path")
  fi
done < <(find "$CONFIG_PATH" -type f -print0)

# テンプレートコピー対象の検証
template_issues=()

if [ "$DIFF_MODE" -eq 0 ] && [ ${#template_destinations[@]} -gt 0 ]; then
  echo ""
  echo "==> Template-generated files:"
  echo ""
fi

for destination_rel in "${template_destinations[@]+"${template_destinations[@]}"}"; do
  [ -z "$destination_rel" ] && continue

  home_path="${HOME_DIR}/${destination_rel}"

  if [ -h "$home_path" ]; then
    link_target=$(readlink "$home_path")
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[SYMLINK] ${destination_rel} -> ${link_target} (通常ファイルとして存在してほしいです)"
    else
      diff_entries+=("~ ${destination_rel}  (template-generated file, replace symlink with local file)")
    fi
    template_issues+=("$destination_rel")
  elif [ -f "$home_path" ]; then
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[OK] ${destination_rel}"
    fi
  elif [ -e "$home_path" ]; then
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[FILE/DIR] ${destination_rel} (通常ファイル以外が存在します)"
    else
      diff_entries+=("~ ${destination_rel}  (template-generated file, replace existing path)")
    fi
    template_issues+=("$destination_rel")
  else
    if [ "$DIFF_MODE" -eq 0 ]; then
      echo "[MISSING] ${destination_rel}"
    else
      diff_entries+=("+ ${destination_rel}  (template-generated file, create from template)")
    fi
    template_issues+=("$destination_rel")
  fi
done

if [ "$DIFF_MODE" -eq 0 ]; then
  echo ""
  echo "==> Summary"
fi

has_issues=0

if [ ${#dir_issues[@]} -gt 0 ]; then
  has_issues=1
fi
if [ ${#unlinked_files[@]} -gt 0 ]; then
  has_issues=1
fi
if [ ${#broken_links[@]} -gt 0 ]; then
  has_issues=1
fi
if [ ${#dangling_links[@]} -gt 0 ]; then
  has_issues=1
fi
if [ ${#alias_issues[@]} -gt 0 ]; then
  has_issues=1
fi
if [ ${#template_issues[@]} -gt 0 ]; then
  has_issues=1
fi

# diffモード: 差分のみを簡潔に表示
if [ "$DIFF_MODE" -eq 1 ]; then
  if [ "$has_issues" -eq 0 ]; then
    echo "全てのリンクが最新です。"
    exit 0
  else
    echo "==> Changes needed (run 'make deploy' to apply):"
    for entry in "${diff_entries[@]}"; do
      echo "$entry"
    done
    exit 1
  fi
fi

# 通常モード: 詳細なサマリーを表示
if [ ${#dir_issues[@]} -gt 0 ]; then
  echo ""
  echo "ディレクトリリンクの問題 (${#dir_issues[@]}):"
  for d in "${dir_issues[@]}"; do
    echo "  - $d"
  done
fi

if [ ${#unlinked_files[@]} -gt 0 ]; then
  echo ""
  echo "未リンクファイル (${#unlinked_files[@]}):"
  for f in "${unlinked_files[@]}"; do
    echo "  - $f"
  done
fi

if [ ${#broken_links[@]} -gt 0 ]; then
  echo ""
  echo "リンク先不一致 (${#broken_links[@]}):"
  for f in "${broken_links[@]}"; do
    echo "  - $f"
  done
fi

if [ ${#dangling_links[@]} -gt 0 ]; then
  echo ""
  echo "壊れたリンク (${#dangling_links[@]}):"
  for f in "${dangling_links[@]}"; do
    echo "  - $f"
  done
fi

if [ ${#alias_issues[@]} -gt 0 ]; then
  echo ""
  echo "エイリアスリンクの問題 (${#alias_issues[@]}):"
  for f in "${alias_issues[@]}"; do
    echo "  - $f"
  done
fi

if [ ${#template_issues[@]} -gt 0 ]; then
  echo ""
  echo "テンプレート生成ファイルの問題 (${#template_issues[@]}):"
  for f in "${template_issues[@]}"; do
    echo "  - $f"
  done
fi

if [ "$has_issues" -eq 0 ]; then
  echo "全ての設定ファイルが正しくリンクされています。"
  exit 0
else
  echo ""
  echo "'make deploy' を実行して問題を修正してください。"
  exit 1
fi
