---
status: accepted
date: 2026-02-28
decision-makers:
  - kinushu
---

# improve_check_links_with_directory_links_and_diff_output

## Context and Problem Statement

`make check-links`（`etc/check_links.sh`）は、`config/` 以下のファイルとホームディレクトリのシンボリックリンクを比較してリンク状態を確認するコマンドである。しかし、以下の2つの問題がある:

### 1. `directory_links` に対応していない

`node.json` の `directory_links` で指定されたディレクトリ（`.claude/skills`, `.claude/commands`, `.codex/skills`）はディレクトリ単位でシンボリックリンクされる（ADR: `2026-01-23_add_directory_link_mode`）。しかし、`check_links.sh` はこれを認識せず、ディレクトリ内の個別ファイルをチェック対象にしてしまう。

結果として、ディレクトリリンクが正しく張られていても `[WRONG]` と誤判定される:

```
[WRONG] .claude/skills/commit-message/SKILL.md -> /Users/.../config/.claude/skills/commit-message/SKILL.md
  (expected: /Users/.../dotfiles/config/.claude/skills/commit-message/SKILL.md)
```

### 2. deploy との差分が分かりにくい

現在の出力は `[OK]`, `[WRONG]`, `[FILE]`, `[MISSING]` の4状態を一覧表示するのみ。`make deploy` を実行したら何が変わるのか（どのリンクが新規作成され、どのリンクが修正されるか）を直感的に把握できない。

### 3. 孤立リンクの検出ができない

`config/` からファイルを削除した場合、ホームディレクトリ側にリンク先の存在しないシンボリックリンク（dangling symlink）が残る。現在の `check_links.sh` は「config/ にあるファイルのリンク状態」のみをチェックするため、この孤立リンクを検出できない。

## Decision Drivers

* `cookbooks/dotfiles/default.rb` のデプロイロジック（ファイル単位リンク + ディレクトリ単位リンク）と一致したチェックを行いたい
* `make deploy` 実行前に「何が変わるか」を差分形式で確認したい
* 既存の `make deploy-dry-run`（mitamae の `--dry-run`）は mitamae の内部出力形式であり、シンボリックリンクの状態に特化していない
* シンプルな bash スクリプトとして維持し、mitamae への依存を避けたい
* CI や pre-deploy フックでの利用も想定したい（exit code による成否判定）

## Considered Options

### Option 1: 既存の `check_links.sh` を改善

`check_links.sh` に以下の変更を加える:

1. `node.json` から `directory_links` を読み取り、ディレクトリ単位リンクも検証する
2. `directory_links` 配下のファイルは個別チェック対象から除外する
3. 出力形式に差分表示モード（`--diff` フラグ）を追加する

**疑似コード:**

```bash
# node.json から directory_links を取得（ファイル不在時は空配列にフォールバック）
if [ -f "$DOTPATH/node.json" ]; then
  directory_links=$(jq -r '.directory_links // [] | .[]' "$DOTPATH/node.json")
else
  directory_links=""
fi

# Phase 1: ディレクトリ単位リンクのチェック
for dir in $directory_links; do
  home_path="$HOME/$dir"
  expected_target="$CONFIG_PATH/$dir"
  # -h（not -L）でリンク判定（壊れたリンクも検出可能）
  # リンク先が通常ディレクトリの場合は [DIR] として報告
done

# Phase 2: ファイル単位リンクのチェック（directory_links 配下は除外）
for file in config/**/*; do
  # directory_links に該当するパスはスキップ
  # -h でリンク判定（dangling symlink も検出）
  # 既存のチェックロジック
done

# Phase 3: 孤立リンクの検出（任意、--orphans フラグ時のみ）
# ホームディレクトリ側で dotfiles/config/ を指すシンボリックリンクを検索し、
# 対応する config/ 側ファイルが存在しないものを報告
```

**実装上の注意点:**

- macOS の `readlink` は GNU 版と挙動が異なる。パスの正規化が必要な場合は `realpath` コマンドを使用する（macOS 13+ に標準搭載）
- シンボリックリンクの判定には `-L` ではなく `-h` を使用する。`-L` は壊れたリンク（dangling symlink）では false を返すが、`-h` はリンク自体の存在を判定するため壊れたリンクも検出できる
- `directory_links` のリンク先が通常ディレクトリ（シンボリックリンクではない）の場合、中にユーザー作成ファイルがある可能性がある。`[DIR]` 状態として報告し、`make deploy` 実行時に上書きされる旨を警告する

**出力形式（通常モード）:**

```
==> Directory links:
[OK]      .claude/skills -> /Users/.../config/.claude/skills
[MISSING] .codex/skills

==> File links:
[OK]      .bashrc
[WRONG]   .vimrc -> /old/path (expected: /Users/.../config/.vimrc)
[MISSING] .gemrc
```

**出力形式（通常モード、ディレクトリがリンクでない場合）:**

```
==> Directory links:
[OK]      .claude/skills -> /Users/.../config/.claude/skills
[DIR]     .codex/skills (not a symlink, directory exists - deploy will overwrite)
[MISSING] .other/dir

==> File links:
[OK]      .bashrc
[WRONG]   .vimrc -> /old/path (expected: /Users/.../config/.vimrc)
[MISSING] .gemrc
[DANGLING] .old_config -> /Users/.../config/.old_config (target does not exist)
```

**出力形式（`--diff` モード）:**

```
==> Changes needed (run 'make deploy' to apply):
+ .codex/skills -> /Users/.../config/.codex/skills  (directory link, new)
~ .vimrc: /old/path -> /Users/.../config/.vimrc      (fix target)
+ .gemrc -> /Users/.../config/.gemrc                  (new link)
```

### Option 2: 新規スクリプト `etc/diff_links.sh` を作成し、check-links はそのまま残す

差分表示に特化した別スクリプトを作成。`make diff-links` として Makefile に追加。`check_links.sh` は既存のまま維持。

**メリット:**
- 既存の check-links の動作を壊さない
- 差分表示に特化した設計が可能

**デメリット:**
- 2つのスクリプトでリンク検証ロジックが重複する
- `check_links.sh` の `directory_links` 未対応問題が残る
- メンテナンス対象が増える

### Option 3: `check_links.sh` を Ruby（mitamae 非依存）で書き直す

`node.json` をネイティブに扱える Ruby で再実装し、`cookbooks/dotfiles/default.rb` と同じロジックを共有する。

**メリット:**
- `node.json` の JSON パースが容易
- デプロイロジックとの整合性を保ちやすい
- `cookbooks/dotfiles/default.rb` から共通ロジックを抽出可能

**デメリット:**
- bash スクリプトの簡潔さを失う
- Ruby 実行環境への依存が増す（ただし mitamae 利用時点で Ruby 的な環境はある）
- 既存の check_links.sh とのインターフェース変更

## Decision Outcome

選択: **Option 1 — 既存の `check_links.sh` を改善**

理由:
- 既存のスクリプトを拡張するため、新規ファイル追加やロジック重複を避けられる
- bash + `jq` で `node.json` を読み取ることで、Ruby 依存を追加せずに `directory_links` 対応が可能
- `--diff` フラグによる差分モードは、既存の状態表示モードと共存でき、CI での利用にも適する
- `jq` は `Brewfile` に含まれている前提（含まれていなければ追加）

## Consequences

### Good

* `directory_links` で指定されたディレクトリリンクが正しく検証され、誤判定がなくなる
* `--diff` モードにより `make deploy` 実行前に変更内容を直感的に確認できる
* 既存の出力形式（`[OK]`, `[WRONG]` 等）は維持されるため、後方互換性がある
* exit code で成否判定が可能（CI / pre-deploy フック利用）

### Bad

* `jq` への依存が追加される（ただし Brewfile で管理済み: `Brewfile:49`）
* `node.json` のスキーマが変更された場合、`check_links.sh` の更新も必要になる
* `cookbooks/dotfiles/default.rb` のリンクロジックと check_links.sh のチェックロジックが別々に実装されるため、両者の同期を人手で維持する必要がある

### 保守性リスクの軽減策

`default.rb` と `check_links.sh` のロジック同期リスクに対して:
- `node.json` のスキーマはシンプルに保つ（`directory_links` 配列のみで、新しいリンクモードの追加は慎重に検討する）
- `check_links.sh` の冒頭コメントに「このスクリプトは `cookbooks/dotfiles/default.rb` と同じリンクロジックを前提とする」旨を明記し、変更時の同期忘れを防ぐ
- 将来的にリンクモードが複雑化した場合は、Option 3（Ruby 化）への移行を検討する

## Definition of Done

- [ ] `check_links.sh` が `node.json` の `directory_links` を読み取り、ディレクトリ単位リンクを検証する
- [ ] `directory_links` 配下のファイルが個別チェック対象から除外される
- [ ] `--diff` フラグで差分表示モードが利用できる
- [ ] `make check-links` が既存の出力形式を維持する（後方互換）
- [ ] 壊れたシンボリックリンク（dangling symlink）を `-h` で検出できる
- [ ] `directory_links` 先が通常ディレクトリの場合に `[DIR]` 警告を表示する
- [ ] `node.json` が存在しない場合や `directory_links` キーが未定義の場合にエラーなく動作する
- [ ] Brewfile に `jq` が含まれていることを確認（確認済み: `Brewfile:49`）
- [ ] `make test` が通ること

## More Information

### 関連 ADR

- `2026-01-02_deploy-dry-run-and-link-check.md`: check-links の初期設計
- `2026-01-23_add_directory_link_mode.md`: directory_links 機能の追加

### 関連ファイル

- `etc/check_links.sh`: 改善対象のスクリプト
- `cookbooks/dotfiles/default.rb`: デプロイロジック（期待状態の定義元）
- `node.json`: `directory_links` 設定
- `Brewfile:49`: `jq` の依存定義

### スコープ外

- **孤立リンクの自動削除**: 検出のみ行い、削除は `make deploy` や `make clean` に委ねる。誤削除のリスクを避けるため、check-links は読み取り専用の検証に留める

### Makefile の変更

```makefile
check-links: ## Check for unlinked files in config/
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/check_links.sh

# 差分表示のショートカット（任意）
diff-links: ## Show diff between expected and actual symlinks
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/check_links.sh --diff
```
