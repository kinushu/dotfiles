dotfiles
========

macOS / Ubuntu 開発環境の設定ファイルを管理するリポジトリです。

## 概要

このリポジトリでは以下のことができます：

- **シェル環境の構築**: bash/zsh の設定、エイリアス、関数を一括セットアップ
- **開発ツールの導入**: macOS は Homebrew、Ubuntu は apt + mise 経由で必要なツールを自動インストール
- **エディタ設定の同期**: Vim、VSCode などの設定を複数マシンで共有
- **言語バージョン管理**: mise を使った Ruby、Node.js などのバージョン管理
- **Git 設定の統一**: グローバル gitignore やエイリアスの設定

新しい Mac / Ubuntu 環境をセットアップする際に `make install` を実行するだけで、いつもの開発環境を再現できます。OS の判定は自動で行われ（`etc/lib/detect_os.sh`）、対応する Mitamae role が選択されます。

## 初期設定

```bash
git clone git@github.com:kinushu/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
make init

# Desktopソフトなど導入（macOS のみ）
brew bundle --file ./Brewfile
```

Ubuntu の場合、`make init` は内部で OS を自動判定し、システム変更（apt / locale / ログインシェル変更）を `sudo` 付きで実行したあと、dotfiles の展開や mise 等のユーザー設定を通常ユーザー権限で実行します（`$HOME` 配下が root 所有になるのを避けるための権限分離）。

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `make install` | 完全インストール（update → deploy → init） |
| `make deploy` | config/ から ~ へシンボリックリンク作成 |
| `make deploy-dry-run` | deploy の変更内容を事前確認（実際には適用しない） |
| `make check-links` | シンボリックリンクの状態を一覧表示（OK/WRONG/MISSING 等） |
| `make diff-links` | deploy で変更されるリンクのみ差分形式で表示 |
| `make init` | 初期環境セットアップ（OS を自動判定。macOS は Homebrew 導入等、Ubuntu は apt/locale/chsh を sudo で実行後、dotfiles・mise 等を通常ユーザー権限で実行。共通処理として git-secrets なども設定） |
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

## ローカル環境依存値（config.local.yml）

マシン・利用者ごとに異なる環境依存値（scheduled_tasks の設定や Obsidian Vault 名など）は、リポジトリ root の `config.local.yml` に集約します。実ファイルはバージョン管理せず（`.gitignore` の `/config.local.yml` で除外）、コミット対象はテンプレート `config.local.yml.example` のみです。実値をコミットに持たせないことで、private / public リポジトリ間の同期でマージ衝突や実値混入を防ぎます（→ ADR `docs/adr/2026-07-06_1627_introduce_config_local_yml_for_environment_specific_values.md`）。

### 設定手順

テンプレートをリポジトリ root の `config.local.yml` へコピーして実値を設定します。

```bash
cp config.local.yml.example config.local.yml
```

コピー後、`config.local.yml` を開いて実値を設定してください。

### 読み取り主体

- `bin/scheduled_tasks.rb` / `bin/install_scheduled_tasks.rb` / `bin/uninstall_scheduled_tasks.rb`（Ruby の `YAML` で読む）
- `read-hatebu-radio` スキル（`hatebu.obsidian_vault_name` を参照して Clippings を解決。未設定時は自動検出 → AskUserQuestion へフォールバック）

いずれもリポジトリ root の `config.local.yml` を参照します（read-hatebu スキルは `$DOTFILES_LOCAL_CONFIG` による明示指定にも対応）。

### 主なキー

| キー | 用途 |
|------|------|
| `scheduler.*` | launchd スケジューラーの設定（label / interval / log_dir） |
| `auto_commit.*` | 定期自動コミットの設定（対象リポジトリ・プレフィックス等） |
| `hatebu.*` | はてブ取得設定（username / count / output_dir） |
| `hatebu.obsidian_vault_name` | Obsidian Vault ディレクトリ名（`read-hatebu-radio` スキルの Clippings 解決に使用） |

環境依存値が増えるたびに、テンプレート `config.local.yml.example` へキーとスキーマ説明コメントを追記して集約します。

## 公開リポジトリへの展開（継続同期）

このリポジトリは private リポジトリで開発し、公開してよい変更のみを選別してこの public リポジトリへ展開する運用です。選別は許可リスト方式（既定非公開）で行い、リストに載っていないパスは公開されません。

### 仕組み

| ファイル | 役割 |
|---------|------|
| `etc/public_allowlist.txt` | 公開してよいパスパターンの許可リスト（公開判断の台帳） |
| `etc/check_public.sh` | ステージ済み変更を許可リストと突合し、git-secrets によるシークレットスキャンも実施 |
| `.gitallowed` | git-secrets の誤検知を許容登録するリスト |

### 同期手順

```bash
# 1. private 側で開発し、公開候補の変更をステージする
git add <公開したい変更>

# 2. 公開可否チェックを実行する（許可リスト突合 + シークレットスキャン）
bash etc/check_public.sh

# 3. 「公開可」判定（終了コード 0）を確認してからコミットする
#    リスト外の項目が検出された場合は unstage するか、
#    公開してよいものであれば etc/public_allowlist.txt に追記する
git restore --staged <非公開にする項目>

# 4. public リポジトリへ push する（fast-forward のみ。force push 禁止）
git push public_dotfiles <ブランチ>
```

公開してよいファイルを新規追加した場合は、`etc/public_allowlist.txt` への追記を忘れないでください（追記漏れは「公開されない」側に倒れるため、情報漏洩にはなりません）。

### 公開リポジトリへのコミット作成（private 履歴を混ぜない）

上記の「private 側でコミットしてから public へ fast-forward push する」フローは、public と private が履歴を共有するため、private のコミット・メッセージ・作業過程がそのまま public に流れ込みます。**公開履歴に private のコミット履歴を混ぜたくない**場合は、public 側に独自コミットを作成する方式を使います。

この方式は Claude Code スキル `publish-to-public`（`.claude/skills/publish-to-public/SKILL.md`）として用意しています。概要は次のとおりです。

- 公開先ブランチ（既定候補 `main`、任意ブランチも指定可）・公開元・公開用コミットメッセージを対話（AskUserQuestion）で取得します。private のコミットメッセージは流用せず、公開用に書き起こします。
- public 用の作業ツリー（別 clone または `git worktree`）を最新化し、`etc/public_allowlist.txt` に合致するファイルの**内容だけ**を private 側から同期します（リスト外は同期しません）。
- 同期後、public 側で `etc/check_public.sh` 相当（許可リスト突合 + git-secrets スキャン）を実行し、「公開可」の場合のみ公開用メッセージで commit します。
- **commit までで停止します。push は行いません**。public への push は利用者の明示指示があった場合のみ、別ステップで fast-forward・force 禁止で行います。

削除・リネームは初版では自動反映せず、必要時に個別確認する運用です。詳細な手順・ガードはスキル本文および `docs/adr/2026-07-06_1846_create_public_repo_commits_without_mixing_private_history.md` を参照してください。

## フォルダ構成

- `config/`: 設定ファイル
  - `shell/`: シェル関連の設定ファイル（.bash_profile、.bashrc、.zshrc）
  - `git/`: Git関連の設定ファイル（.gitignore_global）
  - `vim/`: Vim関連の設定ファイル（.vimrc）
  - `editor/`: その他エディタ関連の設定ファイル
  - `claude/`: Claude Code設定ファイル（CLAUDE.md）
- `bin/`: 各種ユーティリティスクリプト（詳細は [bin スクリプト](#bin-スクリプト) を参照）
- `cookbooks/`: Mitamaeレシピ
  - `dotfiles/`: dotfilesのシンボリックリンク管理（OS共通）
  - `mise/`: mise本体の導入とツールのバージョン管理（OS共通。macOSはHomebrew経由、Ubuntuは公式インストーラ経由で導入）
  - `homebrew/`: Homebrew導入と個別パッケージのインストール（macOS専用）
  - `macos_defaults/`: `defaults write` 系のmacOS環境設定（macOS専用）
  - `apt/`: apt によるパッケージ導入（Ubuntu専用、sudo前提）
  - `locale/`: ロケール生成・設定（Ubuntu専用、sudo前提）
  - `zsh/`: oh-my-zsh導入（OS共通、通常ユーザー権限）
  - `mise_tools/`: aptに無いUbuntu固有CLIツールをmiseのconf.d経由で導入（Ubuntu専用）
- `roles/`: Mitamaeロール
  - `base.rb`: OS共通・ユーザーレベルの基本ディレクトリ作成
  - `darwin.rb`: macOS入口（base + dotfiles + Xcode CLT + homebrew + macos_defaults + mise）
  - `ubuntu_system.rb`: Ubuntuのsudo実行前提role（apt + locale + chsh、desktopプロファイル拡張点はスタブ）
  - `ubuntu_user.rb`: Ubuntuの通常ユーザー実行role（base + dotfiles + zsh + mise + mise_tools）
- `etc/`: セットアップ・メンテナンス用スクリプト
  - `init/`: 初期設定スクリプト（OSを判定し対応するroleを実行）
  - `lib/detect_os.sh`: OS/CPUアーキテクチャ判定ライブラリ（`detect_platform`はdarwin/ubuntu、`detect_arch`はamd64/arm64を返す）
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
# macOS
./bin/mitamae local roles/darwin.rb --node-json node.json

# Ubuntu（systemはsudo前提、userは通常ユーザーで実行）
sudo ./bin/mitamae local roles/ubuntu_system.rb --node-json node.json
./bin/mitamae local roles/ubuntu_user.rb --node-json node.json
```

### cookbook の構造

cookbook は `cookbooks/` ディレクトリ配下にモジュール単位で配置されています：

- `cookbooks/dotfiles/`: シンボリックリンクの管理（OS共通）
- `cookbooks/mise/`: mise本体とプログラミング言語・ツールのバージョン管理（OS共通）
- `cookbooks/homebrew/`: Homebrew導入と個別パッケージインストール（macOS専用）
- `cookbooks/macos_defaults/`: macOSの `defaults write` 系設定（macOS専用）
- `cookbooks/apt/`: aptパッケージ導入（Ubuntu専用、sudo前提）
- `cookbooks/locale/`: ロケール設定（Ubuntu専用、sudo前提）
- `cookbooks/zsh/`: oh-my-zsh導入（OS共通、通常ユーザー権限）
- `cookbooks/mise_tools/`: aptに無いUbuntu固有CLIツールのmise導入（Ubuntu専用）

各 cookbook は `default.rb` をエントリーポイントとして持ちます。

### 新しい cookbook の追加方法

1. `cookbooks/` 配下に新しいディレクトリを作成
2. `default.rb` ファイルを作成してレシピを記述
3. 対象OSに応じて `roles/darwin.rb`（macOS）、`roles/ubuntu_system.rb`（Ubuntu・sudo前提）、`roles/ubuntu_user.rb`（Ubuntu・通常ユーザー）、または `roles/base.rb`（OS共通）から include する

### node.json の役割

`node.json` は環境非依存の変数（`directory_links` によるシンボリックリンク対象など）を定義するファイルです。以前存在した `platform` / `arch` キーは廃止されています。OS 判定は以下の2箇所に一本化されています：

- レシピ内: mitamae/specinfra が自動検出する `node[:platform]` でアクセスし、プラットフォームごとの条件分岐に使用（例: `roles/darwin.rb` の `case node[:platform]`）
- 入口スクリプト: `etc/lib/detect_os.sh` の `detect_platform` / `detect_arch` で判定し、実行する role を選択
