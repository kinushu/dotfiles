# frozen_string_literal: true

# Homebrew の導入と個別パッケージのインストールをまとめる cookbook（darwin 専用）
# etc/init/init.sh の Homebrew 関連処理を挙動を変えずに移設したもの。
# brew bundle（Brewfile）への統一は行わず、個別 brew install リストの挙動を維持する。
# 本レシピは roles/darwin.rb の darwin 分岐からのみ include される前提。

# Homebrew 本体の導入
execute 'Homebrew をインストール' do
  command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  not_if { File.exist?('/opt/homebrew/bin/brew') || File.exist?('/usr/local/bin/brew') }
end

# Homebrew のパッケージ情報を最新化
execute 'brew update' do
  command 'brew update'
end

# /usr/local/ 以下をユーザー権限書込みにしておく
# これがないと Rubymine などのコマンドラインツールが入れられない
# 注意: Apple Silicon では /opt/homebrew が主流のため、このブロックは要否再評価対象。
%w[/usr/local/bin /usr/local/lib].each do |dir|
  execute "#{dir}/ の所有者をユーザーへ変更" do
    command "sudo mkdir -p #{dir}/ && sudo chown $(whoami):admin #{dir}/"
    not_if "[ -d #{dir} ] && [ -O #{dir} ]"
  end
end

# brew install 対象パッケージ（init.sh の有効な個別 install 行を移設。
# コメントアウトされていた ruby/asdf/google-cloud-sdk は対象外）
brew_packages = %w[
  git tig gibo zlib mise git-secrets zsh vim less lesspipe trash tree mas
  curl peco fzf jump yq jq ghq mountain-duck direnv
]

brew_packages.each do |pkg|
  execute "brew install #{pkg}" do
    command "brew install #{pkg}"
    not_if "brew list --formula #{pkg} >/dev/null 2>&1 || brew list --cask #{pkg} >/dev/null 2>&1"
  end
end
