
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias mem='top -o rsize'
alias cpu='top -o cpu'

alias rm='rm -i'
alias mv='mv -i'

if [[ $(command -v exa) ]]; then
  alias e='exa --icons'
  alias ea='exa -a --icons'
  alias ee='exa -aal --icons'
fi

# eval "$(jump shell)"

