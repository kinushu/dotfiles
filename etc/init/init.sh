#!/bin/sh

set -eu

source $HOME/.bash_profile

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# brew
if [[ -f /usr/local/bin/brew ]]; then
    echo 'brew already installed.'
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# brew using
brew install git tig gibo
brew install zsh curl peco fzf

# Ruby
if [[ -d ~/.rbenv ]]; then
  echo 'Ruby already installed.'
else
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
  gem update --system
fi
gem install bundler
gem install bundler -v '~> 1.17.3'

## Go
brew install go
go get github.com/motemen/ghq
go get github.com/sonots/lltsv

ghq get https://github.com/rupa/z

## Python

pip install yq

# git-secrets
brew install git-secrets
git secrets --install ~/.git-templates/git-secrets
git config --global init.templatedir '~/.git-templates/git-secrets'
git secrets --register-aws --global
git secrets --add 'private_key' --global
git secrets --add 'private_key_id' --global
# git secrets --install # for repository folder
# less ~/.gitconfig # 設定確認




# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

brew install vim less lesspipe
brew install trash tree
brew install mas
brew install zlib pyenv

brew cask install google-cloud-sdk
