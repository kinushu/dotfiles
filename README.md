dotfiles
========

## フォルダ構成

- `config/`: 設定ファイル
  - `shell/`: シェル関連の設定ファイル（.bash_profile、.bashrc、.zshrc）
  - `git/`: Git関連の設定ファイル（.gitignore_global）
  - `vim/`: Vim関連の設定ファイル（.vimrc）
  - `editor/`: その他エディタ関連の設定ファイル
  - `claude/`: Claude Code設定ファイル（CLAUDE.md）
- `bin/`: 各種ユーティリティスクリプト
- `cookbooks/`: Mitamaeレシピ
  - `dotfiles/`: dotfilesのシンボリックリンク管理
  - `mise/`: mise（asdfの後継）による言語バージョン管理
- `roles/`: Mitamaeロール
  - `base.rb`: 共通設定
  - `darwin.rb`: macOS固有設定
- `etc/`: セットアップ・メンテナンス用スクリプト（レガシー）
  - `init/`: 初期設定スクリプト
  - `test/`: テストスクリプト
  - `upgrade/`: 更新スクリプト

## 初期設定

### 従来のMakefileを使用した設定

```bash
git clone git@github.com:kinushu/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
make init

# Desktopソフトなど導入
brew bundle --file ./Brewfile
```

## 環境ごとの独自設定

~/.bashrc.local
に記述。

## 日々の更新

### 従来のMakefileを使用した更新

```bash
make upgrade
```

## 設定吸い上げ

```bash
brew bundle dump
```

## Mitamae設定のカスタマイズ

言語バージョンの管理は `config/.config/mise/config.toml` で設定します。
プラットフォーム固有の設定は `node.json` で管理します：

```json
{
  "platform": "darwin"
}
```