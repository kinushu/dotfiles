
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias mem='top -o rsize'
alias cpu='top -o cpu'

alias rm='rm -i'
alias mv='mv -i'

alias ssh='ssh -C'

if [[ $(command -v exa) ]]; then
  alias e='exa --icons'
  alias ea='exa -a --icons'
  alias ee='exa -aal --icons'
fi

# eval "$(jump shell)"


source ~/.docker/init-bash.sh || true # Added by Docker Desktop
