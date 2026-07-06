#!/usr/bin/env ruby
# frozen_string_literal: true

# install_scheduled_tasks.rb - launchdスケジューラーインストールスクリプト
# scheduled_tasks.rb を定期的に自動実行する設定を行う

require 'yaml'
require 'optparse'
require 'fileutils'

class SchedulerInstaller
  # 設定ファイルはプロジェクトルート（bin/ の親）に置く
  DEFAULT_CONFIG_PATH = File.join(__dir__, '..', 'config.local.yml')
  PLIST_DIR = File.expand_path('~/Library/LaunchAgents')

  def initialize(options = {})
    @config_path = options[:config] || DEFAULT_CONFIG_PATH
    @config = nil
  end

  def install
    load_config

    label = @config.dig('scheduler', 'label')
    interval_minutes = @config.dig('scheduler', 'interval_minutes') || 20
    log_dir = expand_path(@config.dig('scheduler', 'log_dir') || './log')

    unless label
      error("scheduler.label が設定されていません: #{@config_path}")
      exit 1
    end

    plist_path = File.join(PLIST_DIR, "#{label}.plist")
    script_path = File.join(__dir__, 'scheduled_tasks.rb')
    bin_dir = __dir__

    puts '=== scheduled_tasks スケジューラー インストール ==='
    puts ''

    # 既存のスケジューラーがあればアンロード
    existing = `launchctl list 2>/dev/null | grep #{label}`.strip
    unless existing.empty?
      puts '既存のスケジューラーをアンロードします...'
      system('launchctl', 'unload', plist_path)
    end

    # ログディレクトリを作成
    unless Dir.exist?(log_dir)
      puts "ログディレクトリを作成: #{log_dir}"
      FileUtils.mkdir_p(log_dir)
    end

    # LaunchAgentsディレクトリを確認
    unless Dir.exist?(PLIST_DIR)
      puts "LaunchAgentsディレクトリを作成: #{PLIST_DIR}"
      FileUtils.mkdir_p(PLIST_DIR)
    end

    # plistの内容を生成
    plist_content = generate_plist(
      label: label,
      script_path: script_path,
      config_path: @config_path,
      bin_dir: bin_dir,
      log_dir: log_dir,
      interval_seconds: interval_minutes * 60
    )

    # plistファイルを配置
    puts "plistファイルを作成: #{plist_path}"
    File.write(plist_path, plist_content)

    # launchctlでロード
    puts 'スケジューラーをロードします...'
    result = system('launchctl', 'load', plist_path)

    if result
      puts ''
      puts 'インストール完了しました！'
      puts ''
      puts '設定内容:'
      puts "  - ラベル: #{label}"
      puts "  - 実行間隔: #{interval_minutes}分（#{interval_minutes * 60}秒）"
      puts "  - 対象スクリプト: #{script_path}"
      puts "  - 設定ファイル: #{@config_path}"
      puts "  - ログ出力先: #{log_dir}/"
      puts ''
      puts "確認コマンド: launchctl list | grep #{label}"
      puts "手動実行: launchctl start #{label}"
    else
      error 'スケジューラーのロードに失敗しました。'
      exit 1
    end
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

  def generate_plist(label:, script_path:, config_path:, bin_dir:, log_dir:, interval_seconds:)
    # bash -l -c で実行することで ~/.bash_profile 等を読み込み、PATH等の環境変数を正しく設定する
    <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{label}</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/bash</string>
          <string>-l</string>
          <string>-c</string>
          <string>ruby #{script_path} -c #{config_path}</string>
        </array>
        <key>StartInterval</key>
        <integer>#{interval_seconds}</integer>
        <key>WorkingDirectory</key>
        <string>#{bin_dir}</string>
        <key>StandardOutPath</key>
        <string>#{log_dir}/scheduled_tasks.log</string>
        <key>StandardErrorPath</key>
        <string>#{log_dir}/scheduled_tasks_error.log</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
      </plist>
    PLIST
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

  installer = SchedulerInstaller.new(options)
  installer.install
end

main if __FILE__ == $PROGRAM_NAME
