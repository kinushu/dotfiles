#!/bin/zsh

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

## mise で latest をinstallする。
mise install

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
