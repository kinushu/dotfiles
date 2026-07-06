# frozen_string_literal: true

# Ubuntu 専用 apt cookbook。
# CLI ツール調達方針は「apt 優先、apt に無いものは mise で導入」であり、
# 本レシピは apt 担当分のパッケージ導入を受け持つ。
#
# 呼び出し元の roles/ubuntu_system.rb は sudo 付き mitamae 実行を前提としており、
# mitamae プロセス自体が root 権限で動作するため、本レシピ内では sudo を記述しない。

# 対話プロンプトの発生を防ぐため、apt-get update 実行時は非対話モードに固定する
# 注: mitamae の execute リソースは Chef のような environment 属性を持たないため、
# 環境変数はコマンド行に直接インラインで指定する。
execute 'apt-get update' do
  command 'DEBIAN_FRONTEND=noninteractive apt-get update'
end

# apt 担当分の CLI ツール群を package リソースで冪等に導入する
# （specinfra が実行環境の apt を自動認識するため、provider の明示指定は不要）
apt_packages = %w[
  git
  tig
  zsh
  build-essential
  curl
  vim
  less
  tree
  jq
  fzf
  ripgrep
  direnv
  trash-cli
  locales
  ca-certificates
  unzip
]

apt_packages.each { |pkg| package pkg }
