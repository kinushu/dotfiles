#!/bin/zsh

set +eu

source $HOME/.zshrc

set -eu

cd ~/.rbenv
git pull

cd ~/.rbenv/plugins/ruby-build
git pull

cd ~/.pyenv
git pull

cd ~/
set +eu
omz update
set -eu

brew upgrade
# go get -u all

echo "please turn on 'brew bundle'"
