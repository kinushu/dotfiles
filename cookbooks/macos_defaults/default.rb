# frozen_string_literal: true

# macOS の defaults write 系設定をまとめる cookbook（darwin 専用）

# 共有フォルダで .DS_Store ファイルを作成しない
execute 'Disable .DS_Store creation on network shares' do
  command 'defaults write com.apple.desktopservices DSDontWriteNetworkStores true'
  not_if 'test "$(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null)" = "true"'
end
