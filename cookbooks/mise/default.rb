# frozen_string_literal: true

# mise (rust-based successor to asdf)
# Install mise for version management via Homebrew

# Get dotfiles path dynamically
# dotfiles_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
home_dir = ENV['HOME']

# # Create symlink for .mise.toml from dotfiles
# source_mise_toml = File.join(dotfiles_path, '.mise.toml')
# target_mise_toml = File.join(home_dir, '.mise.toml')

# link target_mise_toml do
#   to source_mise_toml
#   only_if "test -f #{source_mise_toml}"
# end

# mise 本体を導入する。
# macOS は Homebrew（cookbooks/homebrew）で導入済みのため not_if でスキップされる。
# Ubuntu は apt に mise が無いため、公式インストーラ（内部で checksum 検証を行う）で
# ~/.local/bin へ導入する（sudo 不要のユーザーレベル処理）。
execute 'install mise binary' do
  command 'curl -fsSL https://mise.run | sh'
  not_if 'command -v mise >/dev/null 2>&1 || test -x "$HOME/.local/bin/mise"'
end

# Install common tools via mise if config.toml exists
# mise が PATH に無い場合に備え ~/.local/bin を PATH 前置してから実行する。
execute 'Install mise tools' do
  cwd home_dir
  command 'export PATH="$HOME/.local/bin:$PATH" && mise install'
  only_if 'test -f ~/.config/mise/config.toml'
end
