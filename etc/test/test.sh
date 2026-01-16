#!/bin/zsh

set -eu

echo "test start."

source $HOME/.bash_profile

set -eu

echo $PATH

brew -v
git --version
which git
ruby -v
which ruby

python -V
which python
# echo $PYENV_ROOT

go version
which go


