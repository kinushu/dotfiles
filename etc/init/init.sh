#!/bin/bash

set +eu

source $HOME/.bash_profile

set -eu

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# brew
if [[ -f /usr/local/bin/brew ]]; then
    echo 'brew already installed.'
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# brew using
brew install git tig gibo zlib

# Ruby
if [[ -d ~/.rbenv ]]; then
  echo 'Ruby already installed.'
else
  brew install ruby
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

  rbenv rehash
  which ruby
  ruby -v

  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
fi

## Go
brew install go

## Python
brew install python
if [[ -d ~/.pyenv ]]; then
  echo 'Python already installed.'
else
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  pyenv rehash
fi

# git-secrets
if [[ -f ~/.git-templates/git-secrets/hooks/commit-msg ]]; then
  echo 'git-secrets already installed.'
else
  brew install git-secrets
  git secrets --install ~/.git-templates/git-secrets
  git config --global init.templatedir '~/.git-templates/git-secrets'
  git secrets --register-aws --global
  git secrets --add 'private_key' --global
  git secrets --add 'private_key_id' --global
  # git secrets --install # for repository folder
  # less ~/.gitconfig # 設定確認
fi

brew install zsh
# oh-my-zsh
if [[ -d ~/.oh-my-zsh ]]; then
  echo 'oh-my-zsh already installed.'
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

echo 'library install.'

set +eu

brew install vim less lesspipe
brew install trash tree
brew install mas

brew cask install google-cloud-sdk

## ghq
go get github.com/motemen/ghq
# go get github.com/sonots/lltsv

## Go lib
ghq get https://github.com/rupa/z

pip install yq

brew install curl peco fzf

echo 'fin.'
