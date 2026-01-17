#!/bin/zsh

set -eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $script_dir

## プロジェクトのルートディレクトリに移動
cd ../

bash ./etc/install_mitamae.sh

if [ "${DRY_RUN:-}" = "1" ]; then
  echo "[DRY-RUN MODE] 以下の変更が適用されます:"
  echo ""
  bin/mitamae local --dry-run ./roles/darwin.rb --node-json node.json
else
  bin/mitamae local ./roles/darwin.rb --node-json node.json
fi
