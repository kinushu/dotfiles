# frozen_string_literal: true

# zsh の oh-my-zsh 導入をまとめる cookbook（OS 共通・user 処理）
# 本レシピは通常ユーザー権限で実行される前提（sudo は使わない）。
# chsh（ログインシェル変更）は /etc/passwd の変更に sudo が必要なため、
# 本 cookbook には含めず system role（sudo 実行）側の担当とする。

home_dir = ENV['HOME']

# oh-my-zsh 導入
# 公式の curl インストーラは実行時に .zshrc を書き換える副作用があり、
# 本リポジトリでは .zshrc を dotfiles として symlink 管理しているため
# その副作用は都合が悪い。そのため git clone 方式（.zshrc には触れない）を採用する。
execute 'oh-my-zsh をインストール' do
  command "git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git #{home_dir}/.oh-my-zsh"
  not_if { File.directory?("#{home_dir}/.oh-my-zsh") }
end

# plugin 配置について
# 現状の .zshrc は `plugins=(git)` のみを指定しており、これは oh-my-zsh 本体に
# 標準同梱されている git plugin である。追加の外部 plugin（zsh-autosuggestions 等）は
# 利用していないため、追加 clone や配置処理は不要。将来 plugin を追加する場合は
# ここに `not_if` ガード付きの git clone を追記すること。
