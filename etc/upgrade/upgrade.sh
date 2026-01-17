#!/bin/zsh

# .zshrc読み込み時は未定義変数エラーを無視（oh-my-zsh等が未定義変数を使用するため）
set +eu
source $HOME/.zshrc
set -eu

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

brew upgrade

## mise で latest を更新する。
mise upgrade

## asdf
# asdf install python latest
# asdf set -u python latest

# asdf install golang latest
# asdf set -u golang latest

# asdf install nodejs latest
# asdf set -u nodejs latest

set +eu
brew doctor

echo "please turn on 'brew bundle'"
