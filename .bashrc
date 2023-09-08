
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias mem='top -o rsize'
alias cpu='top -o cpu'

alias rm='rm -i'
alias mv='mv -i'

alias ssh='ssh -C'

if [[ $(command -v eza) ]]; then
  alias e='eza --icons'
  alias ea='eza -a --icons'
  alias ee='eza -aal --icons'
fi

# eval "$(jump shell)"

