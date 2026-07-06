#!/bin/zsh

echo "test start."

set +eu

source $HOME/.bash_profile

set -eu

echo $PATH

# Homebrew は macOS のみ（Ubuntu では apt + mise 構成のため存在しない）。
# .bash_profile が brew を alias 定義しているため command -v では判定できず、
# OS 判定で分岐する。
if [ "$(uname -s)" = "Darwin" ]; then
  brew -v
fi
git --version
which git
ruby -v
which ruby

python -V
which python
# echo $PYENV_ROOT

go version
which go


