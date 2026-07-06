# CLAUDE.md

This file provides guidance to Claude Code （claude.ai/code） when working with code in this user's environment.

Read @~/.agents/AGENTS.md

## 基本設定

- このファイルは `~/.claude/CLAUDE.md` として配置され、すべてのプロジェクトで適用されます。
- 実装中に技術的に詰まったところやわからないところ、解決できないエラーなどがあれば /gemini-search カスタムコマンド で英語で相談すること。

## スキル作成時のルール

- スキルを新規作成する際は、配置場所を確認すること:
  1. **ホームフォルダ（`~/.agents/skills/`）**: 全プロジェクトで共通利用するスキル
  2. **現プロジェクト（`.claude/skills/`）**: 特定プロジェクト専用のスキル
- AskUserQuestionツールを使って、どちらに配置するか選択させること
- スキル名は英語の小文字ハイフン区切りで命名すること（例: commit-message）、動詞をなるべく先にすること。

## スキル実行時の確認ルール（Claude Code 固有の実装）

- 確認すべき場面の共通規範（曖昧さ・スコープ不明・前提未確認・破壊的操作前は中断して確認）は `~/.agents/AGENTS.md`「スキル実行時の確認ルール」を参照。Claude Code では確認手段として AskUserQuestion ツールを使用すること。推測で補完せず、明示的に質問する。
- .md ファイルの最終成果物を「ユーザーが即座に確認できる手段」（共通規範は AGENTS.md 参照）の Claude Code 固有実装として、Bash ツールで `~/bin/md-open "{ファイルの絶対パス}"` を実行すること。
  - ファイルパスは必ず実際のパスを埋めること。プレースホルダを残さない。
  - 小刻みな編集の途中では不要。成果物としてユーザーに提示する時点で1回実行する。

## スキル品質担保ルール（empirical-prompt-tuning）

- 次のいずれかに該当する場合、`empirical-prompt-tuning` スキルによる客観評価を実施すること。
  - 新規スキルを追加するとき
  - 既存スキルの SKILL.md 本文が 30% 以上変わる改訂（YAML frontmatter 除く、`git diff --stat` の追加 + 削除行数 ÷ 変更前総行数で判定）
  - 既存スキルの description を変更するとき
- 以下は適用不要。
  - typo 修正・表記ゆれ統一・リンク追加のみ
  - 参考文献セクションの追加
  - YAML frontmatter の軽微修正（kebab-case 統一等）
- 適用可否が曖昧な場合（25〜35% のグレーゾーン等）は AskUserQuestion でユーザー確認すること。
- 本ルールは Claude Code 限定。Codex CLI / Gemini CLI では Task tool と `<usage>` メタデータに依存する本スキルが動作しないため、対応する場合は Claude Code に切り替えてから実行すること。
- 根拠 ADR: private リポジトリの ADR に記録。

## 大規模タスクのモデル分業ルール

- ADR や計画書を伴う大規模タスクでは、解析・設計・計画は現モデルが担い、実装は確定計画を入力にサブエージェントへ委託する（現モデルは直接実装しない）。
- 委託の具体手順（実装モデルの明示選択 / よしなに一任の判定、委託先カテゴリの動的列挙、codex は implement-by-codex 経由 等）は `delegate-by-model` skill に従う。
- 小規模タスクには適用しない。本ルールは Claude Code 限定。
- 根拠 ADR: private リポジトリの ADR に記録。
