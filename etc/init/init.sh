#!/bin/sh

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# brew using
brew install git tig gibo
brew install zsh curl
brew install vim less lesspipe
brew install trash tree
brew install mas

# ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
rbenv install 2.3.8
rbenv global 2.3.8
gem update --system
gem i bundler

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

brew install go
go get github.com/motemen/ghq
go get github.com/sonots/lltsv