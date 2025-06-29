# frozen_string_literal: true

# Base role that can be used across different platforms

# Create necessary directories
home_dir = ENV['HOME']
%w[
  .config
  .local/share
  .cache
  tmp
].each do |dir|
  directory "#{home_dir}/#{dir}" do
    action :create
  end
end
