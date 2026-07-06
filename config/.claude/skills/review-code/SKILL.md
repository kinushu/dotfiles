---
name: review-code
description: セキュリティ重視のコードレビューを行う。レビュー、review、PRを見て、コードをチェック、と言われたときに使用。
---

# review-code（Claude Code 拡張版）

## 実施優先順位

以下のいずれかを実行する。

### 1. /review-by-codex（可能な場合のみ）

以下の **全て** を満たす場合に限り、/review-by-codex を最優先で実行する。

- 本セッションが Claude Code の **メインセッション**（subagent 内ではない）
- Bash で `codex --version` が 0 exit で応答する（疎通 OK）
- Bash で `codex auth status` 相当、もしくは直前の `codex` 呼び出しが成功している（認証 OK）

上記判定は skill 開始直後に 1 回だけ行う。いずれか失敗した時点で即座に「2.」にフォールバックし、**疎通/認証リトライはしない**。subagent 経由で呼ばれた場合は Skill tool が使えないため、必ず「2.」に進むこと。

### 2. /review-codeスキルの共通手順を実行する。

このスキルの共通手順は以下のファイルに定義されている。
**Read ツールで必ず読み込み、その指示に従ってから以下の拡張手順を実行すること。**
**読み込みに失敗した場合は、スキルの実行を中断しユーザーに報告すること。**

共通スキル定義: `~/.agents/skills/review-code/SKILL.md`

対象 diff が **15 ファイル以上または 800 行以上**（共通手順のスコープ分割発動条件と同じ閾値）の場合、共通手順の実行自体を Agent ツール（`model: "opus"`）の subagent へ委託する。委託先の subagent には共通スキル定義（`~/.agents/skills/review-code/SKILL.md`）を自分で Read させ、成果物形式は共通手順に従わせること。閾値未満の場合はセッションモデルでインライン続行する。

- この委託は「1.」の `/review-by-codex` をスキップする経路のため、下記「フォールバック時の明示」の footer 行は **呼び出し元が subagent 成果物の末尾に必ず追記** すること（委託先はこの wrapper 固有の後処理を知らないため）。
- `CLAUDE_CODE_SUBAGENT_MODEL` 等の環境変数が設定されていると per-invocation の `model` 上書きが無効化される場合がある。委託前に有無を確認し、固定指定があってセッションモデルへ倒れる場合はその旨を成果物に明記する。

### フォールバック時の明示

「1.」をスキップした場合（subagent 実行 / codex 不在 / 認証切れ等）、成果物の末尾に以下を 1 行記載すること。

```
> /review-by-codex はスキップ（理由: <codex 未検出 / subagent 環境 / 認証切れ / etc.>）
```
