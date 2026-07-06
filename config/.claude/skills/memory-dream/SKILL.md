---
name: memory-dream
description: 記憶階層を定期的に再編し重複・矛盾・陳腐化を除去する consolidation 手順。記憶整理・dream・memory consolidation と言われたときに使用。
---

# memory-dream（Claude Code 拡張版）

## 共通手順

このスキルの共通手順（4 フェーズ方法論・重複排除の判定ルール・成果ファイルの書き方・絶対日付化・トリガー条件・採用前レビュー・チェックリスト）は以下のファイルに定義されている。
**Read ツールで必ず読み込み、その方法論に従ってから以下の Claude 拡張手順を実行すること。**
**読み込みに失敗した場合は、スキルの実行を中断しユーザーに報告すること。**

共通スキル定義: `~/.agents/skills/memory-dream/SKILL.md`

## Claude Code 拡張

以下は、共通手順の方法論をこの Claude Code 環境の実際の記憶階層へ適用するための固有手順である。共通手順に書かれた方法論は再掲しない。

### この環境の記憶階層への再マッピング

dream の **主対象** は Claude Code ビルトインの per-project memory ストアである。

- 実体: `~/.claude/projects/<canonical>/memory/`（`<canonical>` は cwd をエンコードしたディレクトリ名。例: `<プロジェクト名>` なら `~/.claude/projects/<プロジェクト名>/memory/`）。
- 構成: `MEMORY.md`（索引）＋ frontmatter 付きの `*.md`（個別記憶ファイル）。
- このストアは **セッションごとに自動追記** されるため、重複・矛盾・陳腐化が溜まる。共通手順の 4 フェーズはこのストアに対して適用する。

curated なルール定義元（`~/.agents/AGENTS.md` = `config/.agents/AGENTS.md`、`~/.claude/CLAUDE.md`、`dotfiles/AGENTS.md`、`dotfiles/CLAUDE.md`）は **「世界のルールの定義元」として参照はするが、原則として書き換えない**。共通手順の「上位レイヤが定めるルールを下位で再掲しない」判定において、これらは上位（定義元）であり、ビルトイン memory ストア側にこれらと重複する記述があれば memory 側から削除する（定義元側は触らない）。

### 記憶ファイル形式の保持

consolidation の際、ビルトイン memory の固有形式を必ず保つ。

- 個別 `*.md` の frontmatter: `name` / `description` / `metadata.type`（`type` は `user` / `feedback` / `project` / `reference` のいずれか）。この形式は Claude Code ビルトイン memory 機能の規約に準拠する。
- `MEMORY.md` は各記憶ファイルへの **1 行フック**（何がどこにあるかを引くための最小の索引行）で構成する。共通手順の「索引を lean に保つ」をこの 1 行フック規約として具体化する。
- 再編後もこの frontmatter と 1 行フックの形式を壊さないこと。

### 非破壊担保（git 管理外ストアのスナップショット＋別途生成）

ビルトイン memory ストアは **git 管理外** なので、git commit では非破壊を担保できない。共通手順の「再編結果は別途生成し、自動採用しない」を、この環境では次の手順で具体化する。

1. dream 実行前に memory ストア（`~/.claude/projects/<canonical>/memory/` 一式）を **スナップショット（バックアップコピー）** する。保存先はセッション scratchpad または `tmp/` を使い、最終成果物と混在させない。
2. 再編結果は **ライブの memory ストアを直接上書きせず、別の提案用の場所（scratchpad / `tmp/` 等）に生成** する。ライブストアはユーザーのレビュー・承認を得るまで無改変のまま保つ（＝共通手順の「自動採用禁止」を担保する）。
3. ユーザーが提案をレビューし承認した後に、はじめてライブストアへ反映する。不採用なら提案とスナップショットを破棄すればよく、ライブストアは元のまま残る。
4. コピー・反映に強制系オプション（`-f` 等）を使わない。削除が必要な場面は `rm` ではなく `trash` を使う（本スキルでは削除は原則発生しない）。

curated な `AGENTS.md` / `CLAUDE.md`（git 管理下）に触れる必要が生じた場合は、上記に代えて **論理単位ごとの commit** で非破壊を担保する（コミットは呼び出し元の運用に従う）。

再編案（consolidation 出力）の生成は判断負荷が高く hallucination リスクがあるため、高知能機（alias: `opus`）での実行を推奨する。subagent へ委託する場合は Agent ツールの `model: "opus"` 上書きを使うこと。ただし `CLAUDE_CODE_SUBAGENT_MODEL` 等の環境変数が設定されていると上書きが無効化される場合があるため、委託前に有無を確認する。

### 矛盾解消時の確認（AskUserQuestion）

共通手順の「判断がつかない矛盾は保留し確認する」を、Claude Code では **AskUserQuestion ツール** で行う。どちらの記述が正しいか判断できない矛盾に遭遇したら、推測で一本化せず AskUserQuestion で選択肢を提示して確認する。

AskUserQuestion を発火できない実行文脈（サブエージェント委託・非対話バッチ等）では、推測でフォールバックせず（「勝手にフォールバックをしない」規範）、当該矛盾を **保留（未解決マーク付き）** のまま提案に残し、確定手段を明記して呼び出し元へ差し戻すこと。

### transcript mining の所在

共通手順の Mine フェーズで使うセッション記録（transcript）は、Claude Code では `~/.claude/projects/<canonical>/*.jsonl` に格納されている。Bash でこのディレクトリの `*.jsonl` を確認し、未記憶化の有用な知見の採掘元とする。

### 完了時のプレビュー

再編結果を成果物としてユーザーへ提示する時点で、必要なら `~/bin/md-open "{ファイルの絶対パス}"` を 1 回だけ実行して内容を提示する（小刻みな編集の途中では実行しない）。
