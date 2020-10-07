#!/bin/zsh

echo "test start."

set +eu

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
echo $PYENV_ROOT

go version
which go


