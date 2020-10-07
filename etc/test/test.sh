#!/bin/zsh

set +eu

source $HOME/.zshrc

set -eu

echo $PATH

brew -v
git --version
which git
ruby -v
which ruby
python -V
which python
go version
which go


