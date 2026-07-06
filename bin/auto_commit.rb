#!/usr/bin/env ruby
# frozen_string_literal: true

# auto_commit.rb - 自動コミットスクリプト
# Gitリポジトリの変更を自動的にコミットする

require 'yaml'
require 'optparse'
require 'time'
require 'logger'
require 'fileutils'

class AutoCommit
  # 設定ファイルはプロジェクトルート（bin/ の親）に置く
  DEFAULT_CONFIG_PATH = File.join(__dir__, '..', 'config.local.yml')

  def initialize(options = {})
    @config_path = options[:config] || DEFAULT_CONFIG_PATH
    @target_dir = options[:target_dir]
    @dry_run = options[:dry_run] || false
    @verbose = options[:verbose] || false
    @config = nil
    @logger = nil
  end

  def run
    load_config
    target_dir = determine_target_dir
    commit_prefix = @config.dig('auto_commit', 'commit_prefix') || '[auto]'

    unless target_dir
      error '対象ディレクトリが指定されていません'
      error '設定ファイルの auto_commit.target_dir を設定するか、-d オプションで指定してください'
      return false
    end

    unless Dir.exist?(target_dir)
      error "ディレクトリが存在しません: #{target_dir}"
      return false
    end

    log "対象ディレクトリ: #{target_dir}" if @verbose

    Dir.chdir(target_dir) do
      unless git_repository?
        error "Gitリポジトリではありません: #{target_dir}"
        return false
      end

      status = `git status --porcelain`.strip

      if status.empty?
        log '変更がありません。コミットするものがありません。'
        return true
      end

      log '変更を検出しました:' if @verbose
      log status if @verbose

      now = Time.now.strftime('%Y-%m-%d %H:%M')
      commit_message = "#{commit_prefix} #{now}"

      if @dry_run
        log '[dry-run] 以下のコマンドを実行予定:'
        log '  git add .'
        log "  git commit -m '#{commit_message}'"
        return true
      end

      log '変更をステージングしています...'
      system('git', 'add', '.')

      log "コミット中: #{commit_message}"
      success = system('git', 'commit', '-m', commit_message)

      if success
        log 'コミット完了しました。'
        true
      else
        error 'コミットに失敗しました。'
        false
      end
    end
  end

  private

  def load_config
    @config = if File.exist?(@config_path)
                YAML.load_file(@config_path)
              else
                {}
              end
    setup_logger
    log "設定ファイル読み込み: #{@config_path}" if @verbose
  end

  def setup_logger
    log_dir = determine_log_dir
    FileUtils.mkdir_p(log_dir)

    log_file = File.join(log_dir, 'auto_commit.log')
    @logger = Logger.new(log_file, 'daily')
    @logger.formatter = proc do |severity, datetime, _progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [#{severity}] #{msg}\n"
    end

    # 標準出力にも出力（verbose時のみ詳細）
    @stdout_logger = Logger.new($stdout)
    @stdout_logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end
  end

  def determine_log_dir
    config_log_dir = @config.dig('scheduler', 'log_dir')
    if config_log_dir
      if config_log_dir.start_with?('./')
        File.join(__dir__, config_log_dir[2..])
      elsif config_log_dir.start_with?('../')
        File.join(__dir__, config_log_dir)
      else
        File.expand_path(config_log_dir)
      end
    else
      File.join(__dir__, '..', 'log')
    end
  end

  def determine_target_dir
    # コマンドライン引数が優先
    return File.expand_path(@target_dir) if @target_dir

    # 設定ファイルから取得
    config_dir = @config.dig('auto_commit', 'target_dir')
    return File.expand_path(config_dir) if config_dir

    nil
  end

  def git_repository?
    system('git', 'rev-parse', '--git-dir', out: File::NULL, err: File::NULL)
  end

  def log(message, level: :info)
    @logger&.send(level, message)
    @stdout_logger&.info(message)
  end

  def error(message)
    @logger&.error(message)
    warn "ERROR: #{message}"
    puts "設定ファイル: #{@config_path}"
  end
end

def main
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "使用方法: #{$PROGRAM_NAME} [options]"

    opts.on('-c', '--config FILE', '設定ファイルパス') do |file|
      options[:config] = file
    end

    opts.on('-d', '--dir DIR', '対象ディレクトリ（設定ファイルより優先）') do |dir|
      options[:target_dir] = dir
    end

    opts.on('-n', '--dry-run', '実際にはコミットせず、処理内容を表示') do
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

  auto_commit = AutoCommit.new(options)
  success = auto_commit.run
  exit(success ? 0 : 1)
end

main if __FILE__ == $PROGRAM_NAME
