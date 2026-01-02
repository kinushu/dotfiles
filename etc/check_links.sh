#!/bin/bash

set -eu

# dotfilesリポジトリのパス
DOTPATH="${DOTPATH:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG_PATH="${DOTPATH}/config"
HOME_DIR="${HOME}"

echo "==> Checking symlinks for config files..."
echo ""

unlinked_files=()
broken_links=()

# config/以下の全ファイルをチェック
while IFS= read -r -d '' file; do
  # config/からの相対パス
  relative_path="${file#$CONFIG_PATH/}"

  # .DS_Storeは除外
  if [[ "$relative_path" == *".DS_Store"* ]]; then
    continue
  fi

  # ホームディレクトリの対応するパス
  home_path="${HOME_DIR}/${relative_path}"

  if [ -L "$home_path" ]; then
    # シンボリックリンクが存在する場合、リンク先を確認
    link_target=$(readlink "$home_path")
    if [ "$link_target" = "$file" ]; then
      echo "[OK] ${relative_path}"
    else
      echo "[WRONG] ${relative_path} -> ${link_target} (expected: ${file})"
      broken_links+=("$relative_path")
    fi
  elif [ -e "$home_path" ]; then
    # 通常のファイルが存在する場合
    echo "[FILE] ${relative_path} (not a symlink, file exists)"
    unlinked_files+=("$relative_path")
  else
    # ファイルもリンクも存在しない場合
    echo "[MISSING] ${relative_path}"
    unlinked_files+=("$relative_path")
  fi
done < <(find "$CONFIG_PATH" -type f -print0)

echo ""
echo "==> Summary"

if [ ${#unlinked_files[@]} -eq 0 ] && [ ${#broken_links[@]} -eq 0 ]; then
  echo "All config files are properly linked!"
  exit 0
else
  if [ ${#unlinked_files[@]} -gt 0 ]; then
    echo ""
    echo "Unlinked files (${#unlinked_files[@]}):"
    for f in "${unlinked_files[@]}"; do
      echo "  - $f"
    done
  fi

  if [ ${#broken_links[@]} -gt 0 ]; then
    echo ""
    echo "Broken/wrong links (${#broken_links[@]}):"
    for f in "${broken_links[@]}"; do
      echo "  - $f"
    done
  fi

  echo ""
  echo "Run 'make deploy' to fix these issues."
  exit 1
fi
