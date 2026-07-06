---
name: review-by-codex
description: Codex CLI を使ってプランやコード変更をレビューする
---

# Codex Review Skill

## 概要
Codex CLI のヘッドレスモードを使い、プランやコード差分のレビューを実行する。

## 手順

1. AskUserQuestion でレビュー対象を確認する:
   - 現コミットから指定ブランチの差分
   - 現在のプランファイル
   - git diff（ステージ済み変更）
   - 指定ファイル

2. Bash ツールで以下のコマンドを実行する:

   - 推論レベルは基本的に high を推奨。
   - **重要**: 対話的な `stdin` 待ちに見える状態を避けるため、レビュー依頼本文は必ず一時ファイルへ書き出してから `codex exec` に渡すこと。
   - **重要**: 一時ファイルへの書き出しはシェル展開を防ぐため、シングルクォートのヒアドキュメントを使うこと。
   - **重要**: `codex exec` には必ず `--json` を付け、JSONL イベントを進捗確認に使うこと。
   - **重要**: 最終レビュー本文は `--output-last-message` でも別ファイルに保存し、JSONL のパース確認と突き合わせできる形にすること。

   ```bash
   PROMPT_FILE=$(mktemp)
   EVENTS_FILE=$(mktemp)
   REVIEW_FILE=$(mktemp)
   trap 'rm -f "$PROMPT_FILE" "$EVENTS_FILE" "$REVIEW_FILE"' EXIT

   cat > "$PROMPT_FILE" <<'REVIEW_EOF'
   <レビュープロンプト>
   REVIEW_EOF

   codex exec -c model_reasoning_effort="<推論レベル>" \
     --sandbox read-only --ephemeral --json \
     --output-last-message "$REVIEW_FILE" \
     - < "$PROMPT_FILE" | tee "$EVENTS_FILE"
   ```

3. `codex exec --json` の出力は、以下の2つに分けて扱う。
  3-1. JSONL イベント全体は進捗確認に使う。長時間実行時は、応答生成中・コマンド実行中・完了のイベントを見て処理継続を判断する。
  3-2. Bash ツールの出力が逐次見える場合は、そのまま JSONL を確認してよい。見えにくい場合は `EVENTS_FILE` を読み、最後に出たイベント種別を確認する。
  3-3. ユーザーへ提示する最終レビュー本文は、まず `REVIEW_FILE` の内容を使う。
  3-4. `REVIEW_FILE` が空、または欠落している場合に限り、JSONL イベントから assistant の最終メッセージを抽出して使う。
  3-5. JSON パースに失敗した場合は、中途半端に要約せず中断し、JSONL の解釈に失敗したことをユーザーへ報告する。
  3-6. `codex exec` 実行中に停止したように見える場合は、レビュー依頼本文が TTY の `stdin` 待ちになっていないかを確認し、必ず `- < "$PROMPT_FILE"` 形式で再実行する。

   進捗確認の例:

   ```bash
   jq -r 'select(.type != null) | .type' "$EVENTS_FILE" | tail
   ```

   最終レビュー本文の確認例:

   ```bash
   cat "$REVIEW_FILE"
   ```

4. 最終レビュー本文を整形して表示する。
  4-1. レビュー対象にADRの.mdファイルが含まれている場合は、レビュー内容をADRのテンプレートに沿って整理する。
  4-2. レビュー対象がコード差分の場合は、指摘内容を「計画からの逸脱」「エッジケースの欠落」「不要な複雑性」「パフォーマンスの問題」のカテゴリに分類して表示する。
  4-3. ADRを更新した場合は Bashツールで `~/bin/md-open "{ADRファイルパス}"` 実行する。
5. レビュー内容に基づいてユーザーに AskUserQuestion でアクションを尋ねる。

## レビュープロンプトテンプレート

### プランレビュー用
「以下の実装計画をレビューしてください。以下の観点で問題を指摘してください:
1. 正確性: 技術的に正しいか
2. スコープ: 過不足がないか
3. 保守性: 長期的に維持しやすいか
4. エッジケース: 見落としがないか
5. セキュリティ: 脆弱性がないか

計画内容:
[プラン内容]」

### コードレビュー用
「以下の git diff をレビューしてください。実装が計画通りか確認し、以下を指摘してください:
1. 計画からの逸脱
2. エッジケースの欠落
3. 不要な複雑性
4. パフォーマンスの問題

diff:
[diff 内容]」
