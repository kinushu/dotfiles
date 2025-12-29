# frozen_string_literal: true

# nodeが利用可能な場合はnodeを使用、それ以外はデフォルトを使用
dotfiles_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
home_dir = ENV['HOME']
p "Dotfiles path: #{dotfiles_path}, Home directory: #{home_dir}"

config_path = File.join(dotfiles_path, 'config')

# デプロイする設定ファイルのリスト(追加や削除があった場合はここを更新)
config_files = [
  '.bash_profile',
  '.bashrc',
  '.codex/AGENTS.md',
  '.claude/CLAUDE.md',
  '.claude/settings.json',
  '.claude/commands/gemini-search.md',
  '.config/ghostty/config',
  '.config/mise/config.toml',
  '.config/starship.toml',
  '.gemrc',
  '.gitignore_global',
  '.vimrc',
  '.zshrc'
]

# 特殊なケース用のディレクトリマッピングを定義
# special_dirs = {
#   # 'claude' => '.claude'
# }

# 特殊なケース用に必要なディレクトリを作成
# special_dirs.each do |dir_name, target_dir|
#   directory File.join(home_dir, target_dir) do
#     action :create
#   end
# end

# configディレクトリからすべてのファイルを自動的にデプロイ
config_files.each do |path|
  next if File.directory?(path)

  # configディレクトリからの相対パスを取得
  relative_path = path.sub(config_path, '')

  if relative_path.include?('/')
    # ファイルがサブディレクトリにある場合
    dir = File.dirname(relative_path) # ディレクトリ部分を取得
    # ホームディレクトリのサブディレクトリを取得
    home_subdir = File.join(home_dir, dir)
    # p "Creating directory: #{home_subdir}"
    # ディレクトリが存在しない場合は作成
    directory home_subdir do
      action :create
    end
  end
  # ターゲットパスを決定
  dst_path = File.join(home_dir, path)
  src_path = File.join(config_path, path)

  # シンボリックリンクを作成
  # p "Linking #{src_path} to #{dst_path}"
  link dst_path do
    to src_path
    force true
  end
end

# # Git設定コマンド
# execute "git config --global core.excludesfile ~/.gitignore_global" do
#   only_if { File.exist?(File.join(home_dir, '.gitignore_global')) }
#   not_if "git config --global --get core.excludesfile | grep -q .gitignore_global"
# end

# # ユーザースクリプトディレクトリ
# link File.join(home_dir, 'bin') do
#   to File.join(dotfiles_path, 'bin')
#   force true
# end
