# frozen_string_literal: true

# nodeが利用可能な場合はnodeを使用、それ以外はデフォルトを使用
dotfiles_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
home_dir = ENV['HOME']
p "Dotfiles path: #{dotfiles_path}, Home directory: #{home_dir}"

config_path = File.join(dotfiles_path, 'config')

# config/以下のファイルを動的にスキャンしてリストを生成
# File::FNM_DOTMATCH でドットファイルも含める
# .DS_Storeなどは除外
config_files = Dir.glob(File.join(config_path, '**', '*'), File::FNM_DOTMATCH)
                  .select { |f| File.file?(f) }
                  .reject { |f| f.include?('.DS_Store') }
                  .map { |f| f.sub("#{config_path}/", '') }

p "Found #{config_files.length} config files to deploy"

# configディレクトリからすべてのファイルを自動的にデプロイ
config_files.each do |path|
  if path.include?('/')
    # ファイルがサブディレクトリにある場合
    dir = File.dirname(path)
    home_subdir = File.join(home_dir, dir)
    # ディレクトリが存在しない場合は作成
    directory home_subdir do
      action :create
    end
  end

  # ターゲットパスを決定
  dst_path = File.join(home_dir, path)
  src_path = File.join(config_path, path)

  # シンボリックリンクを作成
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
