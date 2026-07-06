#!/usr/bin/env ruby
# frozen_string_literal: true

# scheduled_tasks.rb - 定期実行タスクオーケストレーター
# 複数のタスク（auto_commit, hatebu-to-md等）をまとめて実行する

require 'yaml'
require 'optparse'
require 'time'
require 'fileutils'
require 'logger'

class ScheduledTasks
  # 設定ファイルはプロジェクトルート（bin/ の親）に置く
  DEFAULT_CONFIG_PATH = File.join(__dir__, '..', 'config.local.yml')

  def initialize(options = {})
    @config_path = options[:config] || DEFAULT_CONFIG_PATH
    @dry_run = options[:dry_run] || false
    @verbose = options[:verbose] || false
    @config = nil
    @logger = nil
  end

  def run
    load_config
    log_start

    results = []

    # hatebu タスク
    if task_enabled?('hatebu')
      results << run_hatebu
    else
      log 'hatebu: スキップ（無効）'
    end

    # auto_commit タスク
    if task_enabled?('auto_commit')
      results << run_auto_commit
    else
      log 'auto_commit: スキップ（無効）'
    end

    log_end(results)
    results.all? { |r| r[:success] }
  end

  private

  def load_config
    unless File.exist?(@config_path)
      warn "ERROR: 設定ファイルが見つかりません: #{@config_path}"
      warn 'ERROR: config.local.yml.example をコピーして設定してください'
      exit 1
    end

    @config = YAML.load_file(@config_path)
    setup_logger
    log "設定ファイル読み込み: #{@config_path}" if @verbose
  end

  def setup_logger
    log_dir = determine_log_dir
    FileUtils.mkdir_p(log_dir)

    log_file = File.join(log_dir, 'scheduled_tasks.log')
    @logger = Logger.new(log_file, 'daily')
    @logger.formatter = proc do |severity, datetime, _progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [#{severity}] #{msg}\n"
    end
  end

  def determine_log_dir
    config_log_dir = @config.dig('scheduler', 'log_dir')
    if config_log_dir
      if config_log_dir.start_with?('./', '../')
        File.expand_path(File.join(__dir__, config_log_dir))
      else
        File.expand_path(config_log_dir)
      end
    else
      File.expand_path(File.join(__dir__, '..', 'log'))
    end
  end

  def task_enabled?(task_name)
    @config.dig(task_name, 'enabled') == true
  end

  def run_auto_commit
    log '=== auto_commit 開始 ==='

    auto_commit_config = @config['auto_commit'] || {}
    target_dir = expand_path(auto_commit_config['target_dir'])
    commit_prefix = auto_commit_config['commit_prefix'] || '[auto]'

    unless target_dir
      log 'auto_commit: target_dir が設定されていません'
      return { task: 'auto_commit', success: false, message: 'target_dir未設定' }
    end

    unless Dir.exist?(target_dir)
      log "auto_commit: ディレクトリが存在しません: #{target_dir}"
      return { task: 'auto_commit', success: false, message: 'ディレクトリなし' }
    end

    auto_commit_script = File.join(__dir__, 'auto_commit.rb')

    if File.exist?(auto_commit_script)
      # auto_commit.rb が存在する場合はそれを呼び出す
      cmd_args = [auto_commit_script, '-c', @config_path]
      cmd_args << '-n' if @dry_run
      cmd_args << '-v' if @verbose

      if @dry_run
        log "[dry-run] 実行: ruby #{cmd_args.join(' ')}"
        return { task: 'auto_commit', success: true, message: 'dry-run' }
      end

      log "実行: ruby #{cmd_args.join(' ')}" if @verbose
      success = system('ruby', *cmd_args)
      { task: 'auto_commit', success: success, message: success ? '完了' : '失敗' }
    else
      # auto_commit.rb がない場合は直接実行
      run_auto_commit_inline(target_dir, commit_prefix)
    end
  end

  def run_auto_commit_inline(target_dir, commit_prefix)
    Dir.chdir(target_dir) do
      status = `git status --porcelain`.strip

      if status.empty?
        log 'auto_commit: 変更なし'
        return { task: 'auto_commit', success: true, message: '変更なし' }
      end

      now = Time.now.strftime('%Y-%m-%d %H:%M')
      commit_message = "#{commit_prefix} #{now}"

      if @dry_run
        log "[dry-run] git add . && git commit -m '#{commit_message}'"
        return { task: 'auto_commit', success: true, message: 'dry-run' }
      end

      system('git', 'add', '.')
      success = system('git', 'commit', '-m', commit_message)

      if success
        log "auto_commit: コミット完了 - #{commit_message}"
        { task: 'auto_commit', success: true, message: 'コミット完了' }
      else
        log 'auto_commit: コミット失敗'
        { task: 'auto_commit', success: false, message: 'コミット失敗' }
      end
    end
  end

  def run_hatebu
    log '=== hatebu 開始 ==='

    hatebu_config = @config['hatebu'] || {}
    username = hatebu_config['username']
    count = hatebu_config['count'] || 10
    output_dir = expand_path(hatebu_config['output_dir'])

    unless username && !username.empty? && username != 'your_username'
      log 'hatebu: username が設定されていません'
      return { task: 'hatebu', success: false, message: 'username未設定' }
    end

    hatebu_script = File.join(__dir__, 'hatebu-to-md')

    unless File.exist?(hatebu_script)
      log "hatebu: スクリプトが見つかりません: #{hatebu_script}"
      return { task: 'hatebu', success: false, message: 'スクリプトなし' }
    end

    log_dir = determine_log_dir

    cmd_args = [hatebu_script, username, '-c', count.to_s]
    cmd_args += ['-o', output_dir] if output_dir
    cmd_args += ['-l', log_dir]
    cmd_args << '-q' unless @verbose

    if @dry_run
      log "[dry-run] 実行: #{cmd_args.join(' ')}"
      return { task: 'hatebu', success: true, message: 'dry-run' }
    end

    log "実行: #{cmd_args.join(' ')}" if @verbose
    success = system(*cmd_args)
    { task: 'hatebu', success: success, message: success ? '完了' : '失敗' }
  end

  def expand_path(path)
    return nil if path.nil? || path.empty?

    File.expand_path(path)
  end

  def log(message, level: :info)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    @logger&.send(level, message)
    puts "[#{timestamp}] #{message}"
  end

  def error(message)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    @logger&.error(message)
    warn "[#{timestamp}] ERROR: #{message}"
    puts "設定ファイル: #{@config_path}"
  end

  def log_start
    log '=' * 60
    log 'scheduled_tasks 開始'
    log "設定ファイル: #{@config_path}"
    log "dry-run: #{@dry_run}"
    log '=' * 60
  end

  def log_end(results)
    log '=' * 60
    log 'scheduled_tasks 終了'
    results.each do |r|
      status = r[:success] ? 'OK' : 'NG'
      log "  #{r[:task]}: #{status} (#{r[:message]})"
    end
    log '=' * 60
  end
end

def main
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "使用方法: #{$PROGRAM_NAME} [options]"

    opts.on('-c', '--config FILE', '設定ファイルパス') do |file|
      options[:config] = file
    end

    opts.on('-n', '--dry-run', '実際には処理せず、実行内容を表示') do
      options[:dry_run] = true
    end

    opts.on('-v', '--verbose', '詳細出力') do
      options[:verbose] = true
    end

    opts.on('-h', '--help', 'ヘルプを表示') do
      puts opts
      exit
    end
  end

  parser.parse!

  tasks = ScheduledTasks.new(options)
  success = tasks.run
  exit(success ? 0 : 1)
end

main if __FILE__ == $PROGRAM_NAME
