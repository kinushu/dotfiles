#!/usr/bin/env ruby
# frozen_string_literal: true

# uninstall_scheduled_tasks.rb - launchdスケジューラーアンインストールスクリプト
# scheduled_tasks.rb の自動実行設定を解除する

require 'yaml'
require 'optparse'
require 'fileutils'

class SchedulerUninstaller
  # 設定ファイルはプロジェクトルート（bin/ の親）に置く
  DEFAULT_CONFIG_PATH = File.join(__dir__, '..', 'config.local.yml')
  PLIST_DIR = File.expand_path('~/Library/LaunchAgents')

  def initialize(options = {})
    @config_path = options[:config] || DEFAULT_CONFIG_PATH
    @config = nil
  end

  def uninstall
    load_config

    label = @config.dig('scheduler', 'label')
    log_dir = expand_path(@config.dig('scheduler', 'log_dir') || './log')

    unless label
      error 'scheduler.label が設定されていません'
      exit 1
    end

    plist_path = File.join(PLIST_DIR, "#{label}.plist")

    puts '=== scheduled_tasks スケジューラー アンインストール ==='
    puts ''

    # スケジューラーが登録されているか確認
    existing = `launchctl list 2>/dev/null | grep #{label}`.strip

    if existing.empty? && !File.exist?(plist_path)
      puts 'スケジューラーは登録されていません。'
      exit 0
    end

    # launchctlでアンロード
    unless existing.empty?
      puts 'スケジューラーをアンロードします...'
      system('launchctl', 'unload', plist_path)
    end

    # plistファイルを削除
    if File.exist?(plist_path)
      puts "plistファイルを削除: #{plist_path}"
      FileUtils.rm(plist_path)
    end

    puts ''
    puts 'アンインストール完了しました！'
    puts ''

    # ログファイルの削除を確認
    return unless Dir.exist?(log_dir) && !Dir.empty?(log_dir)

    puts "ログファイルが残っています: #{log_dir}"
    puts "手動で削除する場合: rm -rf #{log_dir}"
  end

  private

  def load_config
    unless File.exist?(@config_path)
      error "設定ファイルが見つかりません: #{@config_path}"
      error 'config.local.yml.example をコピーして設定してください'
      exit 1
    end

    @config = YAML.load_file(@config_path)
  end

  def expand_path(path)
    return nil if path.nil? || path.empty?

    if path.start_with?('./', '../')
      File.expand_path(File.join(__dir__, path))
    else
      File.expand_path(path)
    end
  end

  def error(message)
    warn "ERROR: #{message}"
  end
end

def main
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "使用方法: #{$PROGRAM_NAME} [options]"

    opts.on('-c', '--config FILE', '設定ファイルパス') do |file|
      options[:config] = file
    end

    opts.on('-h', '--help', 'ヘルプを表示') do
      puts opts
      exit
    end
  end

  parser.parse!

  uninstaller = SchedulerUninstaller.new(options)
  uninstaller.uninstall
end

main if __FILE__ == $PROGRAM_NAME
