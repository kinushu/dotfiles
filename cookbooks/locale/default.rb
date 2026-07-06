# frozen_string_literal: true

# Ubuntu 専用 locale cookbook。
#
# 呼び出し元の roles/ubuntu_system.rb は sudo 付き mitamae 実行を前提としており、
# mitamae プロセス自体が root 権限で動作するため、本レシピ内では sudo を記述しない。
# locale-gen 実行に必要な locales パッケージは T9 apt cookbook が導入する
# （ubuntu_system role で apt → locale の順に include される前提）。

# en_US.UTF-8 と ja_JP.UTF-8 のロケールを生成する
# （既に両方とも locale -a に存在する場合はスキップし、冪等性を担保する）
execute 'locale-gen en_US.UTF-8 ja_JP.UTF-8' do
  command 'locale-gen en_US.UTF-8 ja_JP.UTF-8'
  not_if "locale -a | grep -qi 'en_US.utf8' && locale -a | grep -qi 'ja_JP.utf8'"
end

# システム既定の LANG は en_US.UTF-8 に固定する。
# サーバ用途では日本語ロケールを既定にすると文字化けやログ解析ツールとの
# 互換性問題を招きやすいため、安全側として英語ロケールを既定とし、
# 日本語ロケールは生成のみ行い必要に応じて利用者側で明示的に切り替える運用とする。
execute 'update-locale LANG=en_US.UTF-8' do
  command 'update-locale LANG=en_US.UTF-8'
  not_if "grep -q 'LANG=en_US.UTF-8' /etc/default/locale"
end
