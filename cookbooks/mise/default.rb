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

# Install common tools via mise if .mise.toml exists
execute 'Install mise tools' do
  cwd home_dir
  command 'mise install'
  only_if 'test -f ~/.config/mise/config.toml'
end
