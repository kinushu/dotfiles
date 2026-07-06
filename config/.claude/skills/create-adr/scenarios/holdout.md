# scenario: holdout — create-adr 未見ケース

**運用ルール**: Phase 7 まで開かない。median / edge の対策が打たれた後の過学習検出用。

---

## 未見ケース候補（Phase 7 でユーザーが選んで埋める）

### 候補 1: 非常に短命 ADR（即 deprecated 前提）

- 一時的な回避策（ワークアラウンド）を proposed ではなく最初から `deprecated-at` 見込み付きで記録する
- 例: 「2026-06 リリースまでの一時しのぎとして foo を bar で置き換える」
- 期待: template に無い「期限付き」を適切に扱う。Definition of Done に削除条件を書く

### 候補 2: 複数の既存 ADR を同時に superseded にする

- 例: 3 つの旧 ADR (`A`, `B`, `C`) を 1 本の新 ADR でまとめて上書き
- 期待: 新 ADR が 3 本全てに言及、旧 ADR 3 本の status 更新を一括提案

### 候補 3: 日本語タイトルで起案

- 「読み上げ機能の仕様策定」のような日本語タイトル
- 期待: 既存 ADR の日本語タイトル事例（`2026-01-01_ADR運用開始.md` 等）に倣い、命名ルールとの整合判断を行う

### 候補 4: 決定者が複数

- 利用者 + 他メンバー（架空）での共同 ADR
- 期待: `decision-makers:` リストが複数名対応できる

### 候補 5: プロジェクト外の汎用技術 ADR

- dotfiles 文脈を離れ、例えば「REST vs GraphQL」のような一般的な技術選定 ADR
- 期待: 汎用シナリオでも Considered Options の書き方が崩れない

## 選定タイミング

- median / edge で改訂が収束した直後
- 候補 1〜5 の中から 1 つ選び、具体的な状況（利用者発言・プロジェクト状態）を埋めて subagent に dispatch
- 劣化が出れば Phase 5 に戻る
