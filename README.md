dotfiles
========

macOS 開発環境の設定ファイルを管理するリポジトリです。

## 概要

このリポジトリでは以下のことができます：

- **シェル環境の構築**: bash/zsh の設定、エイリアス、関数を一括セットアップ
- **開発ツールの導入**: Homebrew 経由で必要なツールを自動インストール
- **エディタ設定の同期**: Vim、VSCode などの設定を複数マシンで共有
- **言語バージョン管理**: mise を使った Ruby、Node.js などのバージョン管理
- **Git 設定の統一**: グローバル gitignore やエイリアスの設定

新しい Mac をセットアップする際に `make install` を実行するだけで、いつもの開発環境を再現できます。

## 初期設定

```bash
git clone git@github.com:kinushu/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
make init

# Desktopソフトなど導入
brew bundle --file ./Brewfile
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `make install` | 完全インストール（update → deploy → init） |
| `make deploy` | config/ から ~ へシンボリックリンク作成 |
| `make init` | 初期環境セットアップ（Homebrew, git-secrets など） |
| `make list` | 管理対象の設定ファイル一覧を表示 |
| `make test` | 環境が正しく設定されているか検証 |
| `make update` | 最新の変更を pull しサブモジュールを更新 |
| `make upgrade` | インストール済みツールを一括更新 |
| `make clean` | 作成したシンボリックリンクを削除 |

## bin スクリプト

`bin/` ディレクトリには以下のユーティリティスクリプトが含まれています：

| スクリプト | 説明 |
|-----------|------|
| `create_sandbox_project` | サンドボックスプロジェクトを作成。`~/develop/sandbox/年/日付_プロジェクト名` にディレクトリを作成し、boilerplate を展開して git init する |
| `format` | RuboCop を使ってコードフォーマットを実行 |
| `setup` | 開発環境のセットアップ（bundler インストール、bundle install） |

### create_sandbox_project の使い方

```bash
create_sandbox_project <プロジェクト名>
```

例：`create_sandbox_project my-app` を実行すると `~/develop/sandbox/2025/2025-12-30_my-app` が作成されます。

## シェル設定

### 設定ファイルの読み込み順序

シェル起動時に以下の順序で設定ファイルが読み込まれます：

1. **`.bash_profile`**: PATH や環境変数の設定
2. **`.bashrc`**: エイリアス、関数、ツール固有の設定
3. **`.zshrc`**: `.bash_profile` を読み込み、Oh My Zsh を設定
4. **`~/.bashrc.local`**: マシン固有のカスタマイズ（バージョン管理対象外）

### カスタマイズのベストプラクティス

| 設定内容 | 記述場所 |
|---------|---------|
| PATH・環境変数 | `.bash_profile` |
| エイリアス・関数 | `.bashrc` |
| Zsh 固有設定 | `.zshrc` |
| マシン固有設定 | `~/.bashrc.local` |

`~/.bashrc.local` はバージョン管理されないため、個人的な設定や機密情報を含む環境変数などを安全に記述できます。

## 日々の更新

```bash
make upgrade
```

## 設定吸い上げ

```bash
brew bundle dump
```

## フォルダ構成

- `config/`: 設定ファイル
  - `shell/`: シェル関連の設定ファイル（.bash_profile、.bashrc、.zshrc）
  - `git/`: Git関連の設定ファイル（.gitignore_global）
  - `vim/`: Vim関連の設定ファイル（.vimrc）
  - `editor/`: その他エディタ関連の設定ファイル
  - `claude/`: Claude Code設定ファイル（CLAUDE.md）
- `bin/`: 各種ユーティリティスクリプト（詳細は [bin スクリプト](#bin-スクリプト) を参照）
- `cookbooks/`: Mitamaeレシピ
  - `dotfiles/`: dotfilesのシンボリックリンク管理
  - `mise/`: mise（asdfの後継）による言語バージョン管理
- `roles/`: Mitamaeロール
  - `base.rb`: 共通設定
  - `darwin.rb`: macOS固有設定
- `etc/`: セットアップ・メンテナンス用スクリプト
  - `init/`: 初期設定スクリプト
  - `test/`: テストスクリプト
  - `upgrade/`: 更新スクリプト

## Mitamae について

[Mitamae](https://github.com/itamae-kitchen/mitamae) は Ruby 製の構成管理ツールで、宣言的かつ冪等性のあるセットアップを実現します。Chef や Itamae に影響を受けており、シンプルな DSL で環境構築を自動化できます。

### Mitamae のインストール

```bash
./etc/install_mitamae.sh
```

### セットアップの実行

```bash
./bin/mitamae local roles/darwin.rb --node-json node.json
```

### cookbook の構造

cookbook は `cookbooks/` ディレクトリ配下にモジュール単位で配置されています：

- `cookbooks/dotfiles/`: シンボリックリンクの管理
- `cookbooks/mise/`: mise によるプログラミング言語・ツールのバージョン管理

各 cookbook は `default.rb` をエントリーポイントとして持ちます。

### 新しい cookbook の追加方法

1. `cookbooks/` 配下に新しいディレクトリを作成
2. `default.rb` ファイルを作成してレシピを記述
3. `roles/darwin.rb` または `roles/base.rb` から include する

### node.json の役割

`node.json` はプラットフォーム固有の変数を定義するファイルです：

```json
{
  "platform": "darwin"
}
```

レシピ内では `node[:platform]` でアクセスでき、プラットフォームごとの条件分岐に使用します。
