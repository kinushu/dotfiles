---
name: create_adr
description: MADR形式でArchitecture Decision Recordを作成する。ADR作成、意思決定記録、決定を記録、と言われたときに使用。
---

# ADR作成

## 手順

1. ユーザーにADRのタイトルを確認
  1-1. タイトルは簡潔に、内容を反映したものにする
  1-2. タイトルは基本的に英語、半角数字、_ で記述する。
2. 以下のテンプレートで `docs/adr/YYYY-MM-DD_タイトル.md` を作成
3. `docs/adr/README.md` のADR一覧テーブルに追記

## テンプレート

```markdown
---
status: proposed
date: {今日の日付}
decision-makers:
  - kinushu
---

# {タイトル}

## Context and Problem Statement

{解決すべき問題や背景を記述}

## Decision Drivers

* {決定に影響を与える要因1}
* {決定に影響を与える要因2}

## Considered Options

1. {選択肢1}
2. {選択肢2}
3. {選択肢3}

## Decision Outcome

選択: {選んだオプション}

理由: {なぜこのオプションを選んだか}

## Consequences

### Good

* {良い結果1}

### Bad

* {悪い結果1}

## More Information

{追加情報があれば}
```

## ステータスの種類

- proposed: 提案段階
- accepted: 承認済み
- deprecated: 廃止
- superseded: 他のADRに置き換え
