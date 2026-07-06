---
status: accepted
date: 2026-03-04
decision-makers:
  - kinushu
---

# move_user_scripts_to_config_bin

## Context and Problem Statement

`bin/` ディレクトリが `~/bin` に手動でシンボリックリンクされているが、これはデプロイシステム（Mitamae）で管理されていない。また、`bin/` にはインフラスクリプト（`mitamae` バイナリ、`setup` 等）とユーザーユーティリティスクリプト（`format`、`md-open`、`hatebu-to-md` 等）が混在している。

現在の状態:
```
~/bin -> ~/dotfiles/bin  （手動リンク、2023年12月作成）
```

`bin/` の内容:
- **インフラ**: `mitamae`（バイナリ）、`setup`、`install_scheduled_tasks.rb`、`uninstall_scheduled_tasks.rb`、`scheduled_tasks.rb`、`auto_commit.rb`、`config.local.yml`、`config.yml.example`
- **ユーザーユーティリティ**: `md-open`、`create_sandbox_project`

問題点:
1. `~/bin` に `mitamae` バイナリやインフラスクリプトが直接配置される（意図しない動作）
2. シンボリックリンクがデプロイシステムで管理されていない
3. `cookbooks/dotfiles/default.rb` の bin リンク処理はコメントアウト済み（L95-99）
4. `make check-links` で `bin/` のリンク状態が検証されない

## Decision Drivers

* ユーザーユーティリティのみを `~/bin` に展開したい
* `directory_links` の仕組み（ADR: `2026-01-23_add_directory_link_mode`）を活用したい
* インフラスクリプトは `dotfiles/bin/` に残し、リポジトリ内部でのみ使用したい
* 既存の `config/` ベースのデプロイパターンに統一したい

## Considered Options

### Option 1: `config/bin/` を作成し、`directory_links` で管理

ユーザーユーティリティスクリプトを `config/bin/` に移動し、`node.json` の `directory_links` に `bin` を追加する。インフラスクリプトは `bin/` に残す。

```
dotfiles/
├── bin/                    # インフラスクリプト（リポジトリ内部用）
│   ├── mitamae
│   ├── setup
│   ├── install_scheduled_tasks.rb
│   ├── uninstall_scheduled_tasks.rb
│   ├── scheduled_tasks.rb
│   ├── auto_commit.rb
│   ├── config.local.yml
│   └── config.yml.example
└── config/
    └── bin/                # ユーザーユーティリティ（~/bin にリンク）
        ├── md-open
        └── create_sandbox_project
```

### Option 2: `bin/` を `etc/bin/` にリネームし、`config/bin/` を新設

インフラスクリプトを `etc/bin/` に移動し、`bin/` ディレクトリ自体を `config/bin/` のリンク先として使用する。

### Option 3: 現状維持で `bin/` 全体を `directory_links` で管理

`bin/` を `config/bin/` に移動せず、現在の `bin/` ディレクトリをそのまま `directory_links` に追加する（ただしインフラスクリプトも `~/bin` に展開されてしまう）。

## Decision Outcome

選択: **Option 1 — `config/bin/` を作成し、`directory_links` で管理**

理由:
- ユーザーユーティリティとインフラスクリプトを明確に分離できる
- 既存の `directory_links` パターン（`.agents`、`.claude/commands` 等）と統一的に管理できる
- `bin/` ディレクトリの役割が明確になる（リポジトリ内部のインフラ用 vs ユーザー向けユーティリティ用）
- `make check-links` でリンク状態の検証対象になる

### 実装方針

1. `config/bin/` ディレクトリを作成
2. ユーザーユーティリティスクリプトを `bin/` → `config/bin/` に移動（git mv）
3. `node.json` の `directory_links` に `"bin"` を追加
4. `cookbooks/dotfiles/default.rb` のコメントアウト済み bin リンク処理（L95-99）を削除
5. 既存の手動シンボリックリンク `~/bin` を削除し、`make deploy` で再作成

### 移動対象ファイル

| ファイル | 移動先 | 備考 |
|---------|--------|------|
| `bin/md-open` | `config/bin/md-open` | Markdown プレビュー |
| `bin/create_sandbox_project` | `config/bin/create_sandbox_project` | サンドボックス作成 |

### bin/ に残すファイル

| ファイル | 理由 |
|---------|------|
| `bin/mitamae` | Mitamae バイナリ（`.gitignore` 対象） |
| `bin/setup` | リポジトリセットアップ用（deploy 前に使用） |
| `bin/format` | コードフォーマッター（リポジトリ内部用） |
| `bin/hatebu-to-md` | はてブ変換ツール（リポジトリ内部用） |
| `bin/hatebu-to-md-selectors.yaml` | 上記の設定ファイル |
| `bin/install_scheduled_tasks.rb` | スケジュールタスク管理 |
| `bin/uninstall_scheduled_tasks.rb` | スケジュールタスク管理 |
| `bin/scheduled_tasks.rb` | スケジュールタスク管理 |
| `bin/auto_commit.rb` | 自動コミット機能 |
| `bin/config.local.yml` | ローカル設定（`.gitignore` 対象） |
| `bin/config.yml.example` | 設定テンプレート |
| `bin/.keep` | ディレクトリ維持用 |

## Consequences

### Good

* ユーザーユーティリティのみが `~/bin` に展開される（`mitamae` 等のインフラスクリプトは含まれない）
* デプロイシステム（Mitamae）で一元管理され、手動リンクが不要になる
* `make check-links` でリンク状態が検証される
* `config/bin/` にスクリプトを追加すれば自動的に `~/bin` に反映される（再デプロイ不要）

### Bad

* 既存の `bin/` スクリプトを参照するパスが変わるため、他のスクリプトからの参照がある場合は更新が必要
* 既存の手動シンボリックリンクの削除が必要（一度だけの作業）

## Definition of Done

- [ ] `config/bin/` ディレクトリを作成
- [ ] ユーザーユーティリティスクリプトを `config/bin/` に移動（git mv）
- [ ] `node.json` の `directory_links` に `"bin"` を追加
- [ ] `cookbooks/dotfiles/default.rb` のコメントアウト済み bin リンク処理を削除
- [ ] 既存の `~/bin` 手動シンボリックリンクを削除
- [ ] `make deploy` で `~/bin -> config/bin/` のリンクが作成されることを確認
- [ ] `make check-links` で `bin` のリンク状態が検証されることを確認
- [ ] `AGENTS.md` の `bin/` の説明を更新
- [ ] `make test` が通ること

## More Information

### 関連 ADR

- `2026-01-23_add_directory_link_mode.md`: `directory_links` 機能の追加
- `2026-02-28_improve_check_links_with_directory_links_and_diff_output.md`: check-links の `directory_links` 対応

### 関連ファイル

- `bin/`: 現在のスクリプト配置場所
- `config/bin/`: 新しいユーザーユーティリティ配置場所（新規作成）
- `node.json`: `directory_links` 設定
- `cookbooks/dotfiles/default.rb`: デプロイロジック（L95-99 のコメントアウト削除）
- `AGENTS.md`: ディレクトリ構造の説明
