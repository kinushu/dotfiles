---
status: proposed
date: 2026-01-02
decision-makers:
  - kinushu
---

# make deploy に dry-run 機能とリンクチェック機能を追加

## Context and Problem Statement

現在の `make deploy` コマンドには以下の課題がある:

1. **dry-run機能がない**: 実行前にどのようなシンボリックリンクが作成されるか確認できない
2. **リンク漏れの検出ができない**: `config/` 以下にファイルを追加しても、`cookbooks/dotfiles/default.rb` の `config_files` リストに追加し忘れると、リンクが作成されない

現時点で5ファイルがリンクされていない状態:
- `.claude/commands/dig.md`
- `.claude/commands/discuss-with-gemini.md`
- `.claude/skills/code-review/SKILL.md`
- `.claude/skills/commit-message/SKILL.md`
- `.claude/skills/create_adr/SKILL.md`

## Decision Drivers

* デプロイ前に変更内容を確認したい
* config/以下のファイル追加時にリンク漏れを防ぎたい
* 既存のmitamaeの仕組みを活用したい

## Considered Options

### Option 1: Makefileに環境変数でdry-run制御 + チェックスクリプト追加

```makefile
deploy: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/deploy.sh

deploy-dry-run: ## Dry-run deploy (show what would be done)
	@echo '==> Dry-run: showing what would be deployed.'
	@DOTPATH=$(DOTPATH) DRY_RUN=1 bash $(DOTPATH)/etc/deploy.sh

check-links: ## Check for unlinked files in config/
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/check_links.sh
```

### Option 2: mitamaeのdry-runオプションを直接使用

deploy.shを修正して `--dry-run` フラグを渡せるようにする。

### Option 3: 動的にconfig/以下を全て自動リンク

`config_files` リストを廃止し、`config/` 以下のファイルを全て自動的にリンクする。

## Decision Outcome

選択: **Option 1 + Option 3 の組み合わせ**

理由:
- dry-run機能はmitamaeの `--dry-run` オプションを活用
- `config_files` リストを廃止し、`config/` 以下を動的にスキャンして全てリンク
- チェックスクリプトは「現在リンクされていないファイル」を検出するために残す（移行期間用）

## Implementation Plan

### 1. Makefile の変更

```makefile
deploy: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/deploy.sh

deploy-dry-run: ## Dry-run deploy (show what would be done)
	@echo '==> Dry-run: showing what would be deployed.'
	@DOTPATH=$(DOTPATH) DRY_RUN=1 bash $(DOTPATH)/etc/deploy.sh

check-links: ## Check for unlinked files in config/
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/check_links.sh
```

### 2. etc/deploy.sh の変更

```bash
#!/bin/zsh

set -eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $script_dir
cd ../

bash ./etc/install_mitamae.sh

if [ "${DRY_RUN:-}" = "1" ]; then
  bin/mitamae local --dry-run ./cookbooks/dotfiles/default.rb
else
  bin/mitamae local ./cookbooks/dotfiles/default.rb
fi
```

### 3. etc/check_links.sh の作成

config/以下のファイルとホームディレクトリのシンボリックリンクを比較し、リンクされていないファイルを検出する。

### 4. cookbooks/dotfiles/default.rb の変更（オプション）

`config_files` リストを動的生成に変更することで、リンク漏れを根本的に防止。

## Consequences

### Good

* デプロイ前に変更内容を確認できる
* リンク漏れを検出・防止できる
* 既存のmitamae資産を活用

### Bad

* 新規ファイル追加時に意図せずリンクされる可能性（動的スキャンの場合）
* チェックスクリプトのメンテナンスが必要

## More Information

### 使用方法

```bash
# dry-runで確認
make deploy-dry-run

# リンクされていないファイルをチェック
make check-links

# 実際にデプロイ
make deploy
```
