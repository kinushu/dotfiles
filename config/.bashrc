
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias mem='top -o rsize'
alias cpu='top -o cpu'

alias rm='rm -i'
alias mv='mv -i'

alias ssh='ssh -C'

# Claude CLI実行中のスリープ防止
# alias claude='caffeinate -i claude'

# aider-chat（ローカルLLMコードエージェント、fence サンドボックス経由）
# 根拠 ADR: docs/adr/2026-05-28_1000_introduce_ollama_as_local_cli_chat.md
if [[ $(command -v aider-safe) ]]; then
  alias aid='aider-safe --model ollama/qwen3:8b'
  alias aidc='aider-safe --model ollama/qwen2.5-coder:14b'
fi

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

