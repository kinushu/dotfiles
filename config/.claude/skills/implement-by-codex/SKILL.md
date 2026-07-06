---
name: implement-by-codex
description: 確定済みの計画書がある前提で、Codex CLI（codex exec）に実装を委託する。「Codex に実装」「実装を Codex に任せて」「実装委託」と言われたときに使用。計画書が無い・未確定なら起動しない。レビューのみのタスクには使わない（それは review-by-codex）。
---

# Codex Implementation Skill

## 概要

Codex CLI のヘッドレスモードを使い、確定済みの計画書（サブタスク単位）を入力として実装を委託する。
`review-by-codex`（read-only レビュー）と対になるスキルで、サンドボックスのみ `workspace-write` に変えた構成を取る。

## 禁止事項

- `--dangerously-bypass-approvals-and-sandbox` は**絶対に使用しない**（リポジトリ方針「force 系オプション禁止」に違反）。
- `-f` / `--force` 等の強制系オプションは**絶対に使用しない**。
- 計画書の内容が曖昧・未確定の状態で委託を開始しない。必ず利用者の承認を得た計画書を入力とする。

## 手順

### 1. 委託対象と実行条件を確認する

AskUserQuestion で以下を確認する:

- どの計画書（ファイルパスまたはプラン本文）を入力とするか
- 委託するサブタスクの範囲（計画書全体か、特定サブタスクのみか）
- 実装用モデル（例: `codex-mini-latest`、`o4-mini` 等）
- 推論レベル（`low` / `medium` / `high`）— 基本的に `high` を推奨

### 2. 計画書本文を一時ファイルへ書き出す

- **重要**: 対話的な `stdin` 待ちに見える状態を避けるため、計画書本文は必ず一時ファイルへ書き出してから `codex exec` に渡すこと。
- **重要**: 一時ファイルへの書き出しはシェル展開を防ぐため、シングルクォートのヒアドキュメントを使うこと。
- **重要**: `codex exec` には必ず `--json` を付け、JSONL イベントを進捗確認に使うこと。
- **重要**: 最終メッセージは `--output-last-message` でも別ファイルに保存し、JSONL のパース確認と突き合わせできる形にすること。
- **重要**: 手順 2〜4 のコマンド（`mktemp` / `trap` / `codex exec` / 結果参照）は **1 つの Bash 実行ブロックにまとめる**こと。別ブロックに分けると `trap ... EXIT` でシェル終了時に一時ファイルが先に削除され、`RESULT_FILE` が空になる。

### 3. `codex exec` を実行する

以下の中核コマンドを Bash ツールで実行する:

```bash
PROMPT_FILE=$(mktemp)
EVENTS_FILE=$(mktemp)
RESULT_FILE=$(mktemp)
trap 'rm -f "$PROMPT_FILE" "$EVENTS_FILE" "$RESULT_FILE"' EXIT

cat > "$PROMPT_FILE" <<'IMPL_EOF'
<確定済み計画書の本文 + 実装指示>
IMPL_EOF

codex exec -c model_reasoning_effort="<推論レベル>" \
  -m "<実装用モデル>" \
  -C "$(git rev-parse --show-toplevel)" \
  --sandbox workspace-write --json \
  --output-last-message "$RESULT_FILE" \
  - < "$PROMPT_FILE" | tee "$EVENTS_FILE"
```

オプションの説明:

| オプション | 意味 |
|---|---|
| `-c model_reasoning_effort="<レベル>"` | 推論レベルを指定（`low` / `medium` / `high`）|
| `-m "<モデル>"` | 実装用モデルを指定 |
| `-C "$(git rev-parse --show-toplevel)"` | リポジトリルートを作業ディレクトリとして明示 |
| `--sandbox workspace-write` | リポジトリ内への書き込みを許可（サンドボックスは維持） |
| `--json` | JSONL イベントを出力し進捗確認を可能にする |
| `--output-last-message "$RESULT_FILE"` | 最終メッセージを別ファイルに保存する |
| `- < "$PROMPT_FILE"` | TTY stdin 待ちを回避するためファイル経由で渡す |

### 4. JSONL イベントと最終メッセージの扱い

`codex exec --json` の出力は以下の方針で扱う:

4-1. JSONL イベント全体は進捗確認に使う。長時間実行時は、応答生成中・コマンド実行中・完了のイベントを見て処理継続を判断する。

4-2. Bash ツールの出力が逐次見える場合は、そのまま JSONL を確認してよい。見えにくい場合は `EVENTS_FILE` を読み、最後に出たイベント種別を確認する。

```bash
jq -r 'select(.type != null) | .type' "$EVENTS_FILE" | tail
```

4-3. ユーザーへ提示する最終実装メッセージは、まず `RESULT_FILE` の内容を使う。

```bash
cat "$RESULT_FILE"
```

4-4. `RESULT_FILE` が空、または欠落している場合に限り、JSONL イベントから assistant の最終メッセージを抽出して使う。

4-5. JSON パースに失敗した場合は、中途半端に要約せず中断し、JSONL の解釈に失敗したことをユーザーへ報告する。

4-6. `codex exec` 実行中に停止したように見える場合は、計画書本文が TTY の `stdin` 待ちになっていないかを確認し、必ず `- < "$PROMPT_FILE"` 形式で再実行する。

### 5. 委託後の検証（必須）

実装完了後、必ず以下を順番に実施する。問題が見つかれば中断してユーザーへ報告する。

5-1. `git diff` で変更内容を確認する:

```bash
git -C "$(git rev-parse --show-toplevel)" diff
```

5-2. `make test` または `make deploy-dry-run` で環境を検証する:

```bash
# テスト検証
make -C "$(git rev-parse --show-toplevel)" test

# または破壊的変更を伴わない場合の事前確認
make -C "$(git rev-parse --show-toplevel)" deploy-dry-run
```

5-3. 検証に問題がなければ、変更サマリーと Codex の最終メッセージを整形してユーザーへ報告する。

5-4. 検証で問題が見つかった場合は、即座に中断してエラー内容をユーザーへ報告する。自動修正は行わない。

### 6. 次のアクションを確認する

AskUserQuestion で以下を尋ねる:

- 次のサブタスクを委託するか
- 変更をコミットするか（コミットする場合は `commit-changes` スキルを使う）
- レビューが必要であれば `review-by-codex` スキルに引き継ぐ

## 実装プロンプトテンプレート

```
以下の確定済み計画書に従い、実装を行ってください。

## 前提
- リポジトリルートから作業してください。
- 計画書に記載のないファイルは変更しないでください。
- 実装後、変更したファイルの一覧と概要を最終メッセージに含めてください。

## 計画書

[計画書の本文]
```

## 関連スキル

- `review-by-codex` — 実装後のコードレビューに使用（`--sandbox read-only`）
- `commit-changes` — 検証後のコミットに使用
