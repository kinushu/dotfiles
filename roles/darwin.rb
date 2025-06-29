# frozen_string_literal: true

# Base role for macOS
include_recipe './base.rb'

# macOS specific setup
case node[:platform]
when 'darwin'
  # deply dotfiles
  include_recipe '../cookbooks/dotfiles/default.rb'

  # Install Xcode Command Line Tools
  execute 'Install Xcode Command Line Tools' do
    command 'xcode-select --install'
    not_if 'xcode-select -p'
  end

  # Install mise for version management
  include_recipe '../cookbooks/mise/default.rb'
end
