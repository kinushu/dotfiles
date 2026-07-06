# frozen_string_literal: true

# nodeが利用可能な場合はnodeを使用、それ以外はデフォルトを使用
dotfiles_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
home_dir = ENV['HOME']
p "Dotfiles path: #{dotfiles_path}, Home directory: #{home_dir}"

config_path = File.join(dotfiles_path, 'config')

shell_escape = lambda do |path|
  "'#{path.gsub("'", %q('"'"'))}'"
end

# フォルダ単位でリンクする対象（node.jsonから取得、未定義なら空配列）
directory_links = node[:directory_links] || []
p "Directory links: #{directory_links}"

# テンプレートからローカル実ファイルを生成する対象
template_copy_targets = node[:template_copy_targets] || []
p "Template copy targets: #{template_copy_targets}"

# フォルダ単位でリンクを作成
directory_links.each do |dir_path|
  src_path = File.join(config_path, dir_path)
  dst_path = File.join(home_dir, dir_path)

  # ソースディレクトリが存在する場合のみ処理
  next unless File.directory?(src_path)

  # 親ディレクトリを作成
  parent_dir = File.dirname(dst_path)
  directory parent_dir do
    action :create
  end

  # フォルダ単位でシンボリックリンクを作成
  link dst_path do
    to src_path
    force true
  end
end

# テンプレートからローカル実ファイルを生成
template_copy_targets.each do |target|
  source_rel = target[:source]
  destination_rel = target[:destination]
  next if source_rel.nil? || destination_rel.nil?

  src_path = File.join(config_path, source_rel)
  dst_path = File.join(home_dir, destination_rel)
  next unless File.file?(src_path)

  parent_dir = File.dirname(dst_path)
  directory parent_dir do
    action :create
  end

  # 旧運用で作成した managed symlink は、通常ファイルへ移行するため除去する。
  execute "remove managed symlink for #{destination_rel}" do
    command "rm #{shell_escape.call(dst_path)}"
    only_if do
      next false unless File.symlink?(dst_path)

      link_target = File.readlink(dst_path)
      resolved_target = File.expand_path(link_target, File.dirname(dst_path))
      managed_targets = [
        File.join(config_path, destination_rel),
        src_path
      ]

      managed_targets.include?(resolved_target)
    end
  end

  execute "copy template for #{destination_rel}" do
    command "cp #{shell_escape.call(src_path)} #{shell_escape.call(dst_path)}"
    not_if { File.exist?(dst_path) || File.symlink?(dst_path) }
  end
end

# config/以下のファイルを動的にスキャンしてリストを生成
# File::FNM_DOTMATCH でドットファイルも含める
# .DS_Storeなどは除外
# directory_links で指定されたフォルダ配下は除外
template_sources = template_copy_targets.map { |target| target[:source] }.compact
config_files = Dir.glob(File.join(config_path, '**', '*'), File::FNM_DOTMATCH)
                  .select { |f| File.file?(f) }
                  .reject { |f| f.include?('.DS_Store') }
                  .map { |f| f.sub("#{config_path}/", '') }
                  .reject { |f| template_sources.include?(f) }
                  .reject { |f| directory_links.any? { |dir| f.start_with?("#{dir}/") } }

p "Found #{config_files.length} config files to deploy (excluding directory links)"

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

# エイリアスリンク: ホームディレクトリ内の別パスへのシンボリックリンク
# node.json の alias_links で定義（例: ".claude/skills" → ".agents/skills"）
alias_links = node[:alias_links] || {}
alias_links.each do |link_path, target_rel|
  dst_path = File.join(home_dir, link_path)
  target_path = File.join(home_dir, target_rel)

  # 親ディレクトリを作成
  parent_dir = File.dirname(dst_path)
  directory parent_dir do
    action :create
  end

  link dst_path do
    to target_path
    only_if { File.directory?(target_path) || File.symlink?(target_path) }
  end
end

# # Git設定コマンド
# execute "git config --global core.excludesfile ~/.gitignore_global" do
#   only_if { File.exist?(File.join(home_dir, '.gitignore_global')) }
#   not_if "git config --global --get core.excludesfile | grep -q .gitignore_global"
# end
