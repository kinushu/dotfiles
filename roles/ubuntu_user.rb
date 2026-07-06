# frozen_string_literal: true

# Ubuntu 用 user role（通常ユーザー実行前提。sudo は使わない）
#
# system role（apt / locale / chsh）が完了した後に実行される想定。

# ENV['HOME'] 配下の基本ディレクトリを作成する（OS 共通の純粋な共通処理）
include_recipe './base.rb'

# dotfiles の symlink 展開（OS 共通）
include_recipe '../cookbooks/dotfiles/default.rb'

# zsh の oh-my-zsh 導入（OS 共通・user 処理。chsh は system role 側で実施済み）
include_recipe '../cookbooks/zsh/default.rb'

# mise 本体によるツールバージョン管理（OS 共通）
include_recipe '../cookbooks/mise/default.rb'

# apt に無い Ubuntu 固有 CLI ツールを mise で導入する
include_recipe '../cookbooks/mise_tools/default.rb'
