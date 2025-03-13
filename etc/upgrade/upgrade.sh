#!/bin/zsh

set +eu

source $HOME/.zshrc

set -eu

## ruby, rbenv
cd ~/.rbenv
git pull

cd ~/.rbenv/plugins/ruby-build
git pull

#cd ~/.pyenv
#git pull

cd ~/
set +eu
omz update

set -eu

brew upgrade

set +eu

## asdf
asdf install python latest
### set global で 終了コード1になる？ため、一旦回避
asdf set global python latest

asdf install golang latest
asdf set global golang latest

asdf install nodejs latest
asdf set global nodejs latest

set -eu

brew doctor

echo "please turn on 'brew bundle'"
