---
status: accepted
date: 2026-01-02
decision-makers:
  - kinushu
---

# /dig コマンド追加

## Context and Problem Statement

大規模な機能開発において、仕様が曖昧なまま実装を進めると手戻りが発生しやすい。Claude Codeを使った開発で、仕様を事前に深掘りし、詳細なspec文書を作成するワークフローを確立したい。

## Decision Drivers

* 仕様の曖昧さによる実装の手戻りを減らしたい
* Claude Codeの AskUserQuestionTool を活用したい
* spec-based development のワークフローを標準化したい
* trq212氏のX投稿で紹介されたアプローチが有効に見えた

## Considered Options

1. `/dig` コマンドとして Commands に追加
2. Skills として追加（セマンティックトリガー）
3. 都度プロンプトを手入力

## Decision Outcome

選択: `/dig` コマンドとして Commands に追加

理由:
- 明示的に `/dig SPEC.md` で呼び出す使い方が直感的
- 引数でファイルパスを指定できる
- 既存の gemini-search.md と同様のパターンで一貫性がある

## Consequences

### Good

* 仕様策定フェーズが構造化され、漏れが減る
* AskUserQuestionTool による対話的な深掘りで、技術実装・UI/UX・トレードオフなど多角的に検討できる
* 新しいセッションで実装に集中できる（spec作成と実装の分離）

### Bad

* インタビューに時間がかかる場合がある（40問以上になることも）
* 質問の品質はClaude Codeの解釈に依存する

## More Information

### 参考

- 元ネタ: trq212氏のX投稿（spec-based development with Claude Code）
- 実装ファイル: `config/.claude/commands/dig.md`

### 使用例

```
/dig SPEC.md
/dig docs/feature-spec.md
```
