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

## asdf
asdf install python latest
asdf global python latest

asdf install golang latest
asdf global golang latest

asdf install nodejs latest
asdf global nodejs latest

brew doctor

echo "please turn on 'brew bundle'"
