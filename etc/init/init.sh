#!/bin/bash

set +eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $script_dir

# シンボリックリンクがすでに配置されていることを前提に設定ファイルを読み込む
source $HOME/.bash_profile

set -eu

echo 'touch ~/.bashrc.local'
touch ~/.bashrc.local

# OS を判定して対応する role を mitamae で実行する
## プロジェクトのルートディレクトリに移動
cd ../../
# shellcheck source=etc/lib/detect_os.sh
source ./etc/lib/detect_os.sh
if ! platform=$(detect_platform); then
    echo "OS の判定に失敗したため処理を中断します" >&2
    exit 1
fi
case "$platform" in
  darwin)
    bin/mitamae local ./roles/darwin.rb --node-json node.json
    ;;
  ubuntu)
    # system 変更（apt/locale/chsh）は sudo で、ユーザー設定（dotfiles/mise/zsh）は通常ユーザーで実行する
    sudo bin/mitamae local ./roles/ubuntu_system.rb --node-json node.json
    bin/mitamae local ./roles/ubuntu_user.rb --node-json node.json
    ;;
  *)
    echo "未対応の platform です: ${platform}" >&2
    exit 1
    ;;
esac
cd -
## 上記の mitamae の変更を反映
source $HOME/.bash_profile

# Ruby
# if [[ -d ~/.rbenv ]]; then
#   echo 'Ruby already installed.'
# else
#   brew install ruby
#   git clone https://github.com/rbenv/rbenv.git ~/.rbenv
#   git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

#   rbenv rehash
#   which ruby
#   ruby -v

#   curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
# fi

# # asdf
# ## asdf 16.0 以上対応
# brew install asdf
# source ~/.bash_profile
# # BREW_PREFIX=`brew --prefix`
# # . ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh
# which asdf
# asdf version

# ## Go, etc..
# asdf plugin add python
# asdf install python latest
# asdf set -u python latest

# asdf plugin add golang
# asdf install golang latest
# asdf set -u golang latest

# asdf plugin add nodejs
# asdf install nodejs latest
# asdf set -u nodejs latest

## check
ruby -v
which ruby
python -V
which python
go version
which go

# git
git config --global pull.rebase false
git config --global core.excludesfile ~/.gitignore_global
# git-secrets
if [[ -f ~/.git-templates/git-secrets/hooks/commit-msg ]]; then
  echo 'git-secrets already installed.'
elif command -v git-secrets >/dev/null 2>&1; then
  git secrets --install ~/.git-templates/git-secrets
  git config --global init.templatedir '~/.git-templates/git-secrets'
  git secrets --register-aws --global
  git secrets --add 'private_key' --global
  git secrets --add 'private_key_id' --global
  # git secrets --install # for repository folder
  # less ~/.gitconfig # 設定確認
else
  echo 'git-secrets が見つからないためスキップします。'
fi

# oh-my-zsh
if [[ -d ~/.oh-my-zsh ]]; then
  echo 'oh-my-zsh already installed.'
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

echo 'library install.'

set +eu

# brew install google-cloud-sdk

# go get github.com/sonots/lltsv

## Go lib
ghq get https://github.com/rupa/z

mkdir -p ~/duck/Volumes

echo 'fin.'

# git config --global user.name "Name"
# git config --global user.email "EMail"
# git config -l
