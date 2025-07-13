
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

if [[ $(command -v op) ]]; then
  # 1Password cli 使用できる場合は以下をprefixとして実行する。
  alias op_env='op run --env-file=".env_op" --no-masking --'
  alias bundle_op='op_env bundle'
fi

# eval "$(jump shell)"

