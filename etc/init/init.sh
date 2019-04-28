#!/bin/sh

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# brew
if [[ -f /usr/local/bin/brew ]]; then
    echo 'brew already installed.'
else
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# brew using
brew install git tig gibo
brew install zsh curl
brew install vim less lesspipe
brew install trash tree
brew install mas
brew install zlib pyenv

# ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
gem update --system
gem i bundler

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

brew install go
go get github.com/motemen/ghq
go get github.com/sonots/lltsv
