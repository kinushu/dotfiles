# frozen_string_literal: true

# Ubuntu 用 system role（sudo 実行前提）
#
# base.rb は ENV['HOME'] 配下にディレクトリを作るユーザーレベル処理であり、
# 本 role を sudo で実行すると /root 配下に作成されてしまうため、
# base.rb は include しない（base.rb は roles/ubuntu_user.rb 側で include する）。

include_recipe '../cookbooks/apt/default.rb'
include_recipe '../cookbooks/locale/default.rb'

# ログインシェルを zsh へ変更する（chsh）
# /etc/passwd の変更には root 権限が必要なため、apt/locale と同様に system role（sudo 実行）側に置く。
execute 'chsh -s "$(command -v zsh)" "$SUDO_USER"' do
  command 'chsh -s "$(command -v zsh)" "$SUDO_USER"'
  # sudo 経由でない場合（$SUDO_USER が空）は対象ユーザーを特定できないためスキップする
  only_if 'test -n "$SUDO_USER"'
  # 対象ユーザーのログインシェルが既に zsh の場合はスキップし、冪等性を担保する
  not_if 'getent passwd "$SUDO_USER" | cut -d: -f7 | grep -q zsh'
end

# desktop プロファイル拡張点（今回はスタブ。GUI 向け cookbook は将来追加）
if node[:profile] == 'desktop'
  # include_recipe '../cookbooks/ubuntu_desktop/default.rb'  # fonts/IME/gsettings 等
end
