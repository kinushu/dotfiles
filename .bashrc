
# z command
source ~/.ghq/github.com/rupa/z/z.sh

# ctrl+f で 良く行くフォルダに移動
function peco-z-search
{
  which peco z > /dev/null
  if [ $? -ne 0 ]; then
    echo "Please install peco and z"
    return 1
  fi
  local res=$(z | sort -rn | cut -c 12- | fzf)
  if [ -n "$res" ]; then
    BUFFER+="cd $res"
    zle accept-line
  else
    return 1
  fi
}
zle -N peco-z-search
bindkey '^f' peco-z-search

# fd - cd to selected directory
find_cd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf) &&
  cd "$dir"
}
alias fd='find_cd'

# ghqのlist一覧から選択して移動します。
alias gh='cd $(ghq list -p | peco)'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias mem='top -o rsize'
alias cpu='top -o cpu'
