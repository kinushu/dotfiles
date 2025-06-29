#!/bin/zsh

set -eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $script_dir

## プロジェクトのルートディレクトリに移動
cd ../

# check architecture
case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  arm64) arch=aarch64 ;;
  *) echo "unknown arch" >&2; exit 1
esac

# pull mitamae
curl -fsSLo ./bin/mitamae https://github.com/itamae-kitchen/mitamae/releases/latest/download/mitamae-${arch}-darwin
chmod +x ./bin/mitamae
