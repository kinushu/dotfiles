
export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin

export PATH="/usr/local/opt/openssl/bin:$PATH"

export PATH=$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"

export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

export PATH=$HOME/bin:$PATH

export MANPATH=/opt/local/man:$MANPATH

if which lesspipe.sh > /dev/null; then
  export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
fi

if [[ -f ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

