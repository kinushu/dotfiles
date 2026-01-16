#!/bin/bash

set -eu

# dotfilesリポジトリのパス
DOTPATH="${DOTPATH:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG_PATH="${DOTPATH}/config"
HOME_DIR="${HOME}"

echo "==> Removing symlinks for config files..."
echo ""

removed_count=0

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
    # シンボリックリンクが存在し、リンク先がconfig/のファイルの場合のみ削除
    link_target=$(readlink "$home_path")
    if [ "$link_target" = "$file" ]; then
      rm "$home_path"
      echo "[REMOVED] ${relative_path}"
      ((removed_count++)) || true
    else
      echo "[SKIP] ${relative_path} (links to different target: ${link_target})"
    fi
  elif [ -e "$home_path" ]; then
    echo "[SKIP] ${relative_path} (not a symlink)"
  else
    echo "[SKIP] ${relative_path} (does not exist)"
  fi
done < <(find "$CONFIG_PATH" -type f -print0)

echo ""
echo "==> Done. Removed ${removed_count} symlinks."
