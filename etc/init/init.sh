#!/bin/bash

set +eu

source $HOME/.bash_profile

set -eu

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# 共有フォルダで .DS_Store ファイルを作成しない
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# brew
if [[ -f /opt/homebrew/bin/brew ]] || [[ -f /usr/local/bin/brew ]]; then
    echo 'brew already installed.'
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# /usr/local/ 以下は ユーザー権限書込みとしておく
# これがないと Rubymine などのコマンドラインツールが入れられない
sudo mkdir -p /usr/local/bin/
sudo chown $(whoami):admin /usr/local/bin/
sudo mkdir -p /usr/local/lib/
sudo chown $(whoami):admin /usr/local/lib/

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

# git
git config --global pull.rebase false
git config --global core.excludesfile ~/.gitignore_global
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

brew install google-cloud-sdk

# go get github.com/sonots/lltsv

## Go lib
ghq get https://github.com/rupa/z

brew install curl
brew install peco fzf jump
brew install yq jq ghq

brew install mountain-duck
mkdir -p ~/duck/Volumes

echo 'fin.'

# git config --global user.name "Name"
# git config --global user.email "EMail"
# git config -l
