#!/bin/zsh

set +eu

source $HOME/.zshrc

set -eu

# OS 判定ライブラリを読み込む（DOTPATH があれば優先し、なければスクリプトからの相対パスで解決する）
if [ -n "${DOTPATH:-}" ] && [ -f "$DOTPATH/etc/lib/detect_os.sh" ]; then
    source "$DOTPATH/etc/lib/detect_os.sh"
else
    source "$(dirname "$0")/../lib/detect_os.sh"
fi

if ! platform=$(detect_platform); then
    echo "OS の判定に失敗したため処理を中断します" >&2
    exit 1
fi

# ## ruby, rbenv
# cd ~/.rbenv
# git pull

# cd ~/.rbenv/plugins/ruby-build
# git pull

#cd ~/.pyenv
#git pull

cd ~/
set +eu
omz update

set -eu

## mise で latest を更新する。
mise upgrade

## asdf
# asdf install python latest
# asdf set -u python latest

# asdf install golang latest
# asdf set -u golang latest

# asdf install nodejs latest
# asdf set -u nodejs latest

# OS ごとのパッケージ管理コマンドで更新する
case "$platform" in
    darwin)
        brew update
        brew upgrade -y

        set +eu
        brew doctor
        set -eu

        echo "please turn on 'brew bundle'"
        ;;
    ubuntu)
        sudo DEBIAN_FRONTEND=noninteractive apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        ;;
esac
