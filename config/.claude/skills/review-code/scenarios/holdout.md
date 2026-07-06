# scenario: holdout — review-code 未見ケース

**運用ルール**:

- このファイルは **Phase 7（収束判定）まで開かない**。
- 書き手が対策を打っていない角度から試すため、median / edge とは異なる切り口にする。

---

## 未見ケース候補（評価直前にユーザーが 1 つ選んで埋める）

### 候補 1: diff 無し / all-green PR

- `git diff main...HEAD` が空、もしくは空白・インデント変更のみ
- 期待: 「指摘なし」を明示して早期終了。勝手に周辺コードを探して指摘を「作らない」

### 候補 2: 認可ロジックの微細バグ

- Rails strong parameters の `permit` 漏れで mass assignment の余地が残る
- 一見正常に動くが attribute が過剰に書き込める
- 期待: Critical or Warning として拾う（SKILL.md の「認証・認可」項目が活きるか）

### 候補 3: TypeScript / JavaScript の diff

- 本 skill は Ruby 想定で書かれていないため、他言語の diff を渡したときの振る舞い
- 期待: 言語が異なっても SQLi / XSS / 認可 / 入力検証の一般論は指摘できる

### 候補 4: 既存コードのリファクタ（機能変更なし）

- 挙動変更を伴わない純粋な抽出・リネーム
- 期待: 「セキュリティ上の新しい問題なし」と判断し、Suggestion 程度で終える

---

## 採点方針

- median / edge で得たスコアと **同等以上** を維持できているか
- tool_uses が median の 1.5 倍以内
- 改訂後 SKILL.md の加筆項目に依存しすぎず、未見ケースでも破綻しないこと

## 選定タイミング

- Phase 7（convergence）に入る直前、median / edge での改訂が 2 周連続で無変化になった時点
- 書き手（= ユーザー）が候補 1〜4 から選ぶ、もしくは別の切り口を新規に追加
- 選んだ後、該当セクションを具体的な diff 付きに埋めて subagent に dispatch
