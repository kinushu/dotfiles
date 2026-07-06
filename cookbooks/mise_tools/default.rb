# frozen_string_literal: true

# apt に無い CLI ツールを mise で導入する Ubuntu 固有分。
# macOS は brew 管理のため対象外（本 cookbook は ubuntu_user role からのみ include される）。
#
# 重要: `mise use -g` は ~/.config/mise/config.toml（dotfiles 管理の symlink）へ追記してしまい、
# リポジトリ管理ファイルを汚染し macOS にも波及するため使用しない。
# 代わりに mise が自動マージする conf.d/ へ Ubuntu 専用の toml を配置する
# （config.toml symlink は変更されない）。呼び出し元は通常ユーザー権限のため sudo は使わない。

home_dir = ENV['HOME']

# conf.d ディレクトリを用意する（config.toml は個別 symlink だが、conf.d は実ディレクトリとして作成可能）
directory "#{home_dir}/.config/mise/conf.d" do
  action :create
end

# Ubuntu 固有 CLI ツールを宣言する toml を配置する。
# jump は registry 短縮名が曖昧なため明示 backend（aqua:gsamokovarov/jump）を指定する。
file "#{home_dir}/.config/mise/conf.d/ubuntu-cli-tools.toml" do
  content <<~TOML
    # Ubuntu 固有 CLI ツール（apt に無いものを mise で導入する分）
    # 本ファイルは cookbooks/mise_tools が生成する。config.toml（dotfiles 管理）とは分離している。
    [tools]
    eza = "latest"
    starship = "latest"
    ghq = "latest"
    yq = "latest"
    peco = "latest"
    "aqua:gsamokovarov/jump" = "latest"
  TOML
end

# conf.d 配置後に mise install で導入する。
# mise が PATH に無い場合に備え ~/.local/bin を PATH 前置する。
# 全ツールが導入済みならスキップして冪等性を担保する。
execute 'install ubuntu cli tools via mise' do
  command 'export PATH="$HOME/.local/bin:$PATH" && mise install'
  not_if 'export PATH="$HOME/.local/bin:$PATH" && ' \
         'mise which eza >/dev/null 2>&1 && ' \
         'mise which starship >/dev/null 2>&1 && ' \
         'mise which ghq >/dev/null 2>&1 && ' \
         'mise which yq >/dev/null 2>&1 && ' \
         'mise which peco >/dev/null 2>&1 && ' \
         'mise which jump >/dev/null 2>&1'
end
