
# echo ".bash_profile start"

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin

# for coreutils
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

export PATH="/usr/local/opt/openssl/bin:$PATH"

# brew
export PATH="/opt/homebrew/sbin:/opt/homebrew/bin/:$PATH"

# Ruby
export PATH=$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH

# # Python
# export PYENV_ROOT=${HOME}/.pyenv
# export PATH=${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:$PATH
# export PYTHONUSERBASE=${HOME}/.pip_local
# export PATH=${PYTHONUSERBASE}/bin:$PATH
#
# # Go
# export GOPATH=$HOME/go
# export PATH=$GOPATH/bin:$PATH

# home bin
export PATH=$HOME/bin:$PATH

export MANPATH=/opt/local/man:$MANPATH


if which lesspipe.sh > /dev/null; then
  export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
fi

export GHQ_ROOT=$HOME/ghq

alias brew="PATH=/opt/homebrew/bin/:/opt/homebrew/sbin/:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin brew"

if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

if [[ -f ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

# asdf
BREW_PREFIX=`brew --prefix`
. ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh

# echo ".bash_profile end"
