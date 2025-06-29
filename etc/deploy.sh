#!/bin/zsh

set -eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $script_dir

## プロジェクトのルートディレクトリに移動
cd ../

bash ./etc/install_mitamae.sh

bin/mitamae local ./cookbooks/dotfiles/default.rb
