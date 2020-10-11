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

omz update

brew upgrade
