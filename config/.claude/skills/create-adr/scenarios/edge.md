# scenario: edge — create-adr の境界ケース

---

## ケース A: 入力がタイトルのみで Context/Options が不足

### 状況設定

利用者の発言:

> zshrc 整理の ADR を作って。

これだけしか情報がない。Context, Drivers, Options などは空白。

### 期待する挙動

- SKILL.md の J 項（対話粒度）に沿って、**AskUserQuestion で必要情報を段取りよく収集** する
  - 解決すべき問題（現状の何が困っているか）
  - 検討した選択肢（何を比べるか）
  - 判断基準（パフォーマンス / 可読性 / 保守性 / etc.）
- 勝手に「zshrc を oh-my-zsh から prezto に移行」等の具体案を捏造しない
- 情報が揃うまでファイルを作成しない（もしくは空テンプレのまま作成してその旨明示）

### 採点項目

- [ ] AskUserQuestion が呼ばれている（3 回以内）
- [ ] 捏造が無い（利用者が言っていない技術選定を勝手に書かない）
- [ ] 情報不足のまま強引にファイルを作成していない
- [ ] 自己申告レポートで「どの情報が足りないと判断したか」を列挙できる

---

## ケース B: 既存 ADR を supersede する新 ADR を起案

### 状況設定

利用者の発言:

> 2026-02-25 の `unify_ai_tool_skills_and_instructions` ADR を見直したい。Claude と Codex/Gemini の共通 skill 置き場戦略を根本から変える新 ADR を起こして、旧 ADR は superseded に切り替えたい。

### 期待する挙動

- 既存 ADR（`docs/adr/2026-02-25_unify_ai_tool_skills_and_instructions.md`）を Read し、
  - 新 ADR の More Information に参照リンクを入れる
  - 新 ADR の Context に「旧 ADR の何を変えるのか」明記
- 旧 ADR 側の status を `superseded` に更新し、`superseded-by` のような参照を追加する提案（自動更新する / しないは要確認）
- 旧 ADR の内容をちゃんと引用（重複を避ける書き方）

### 採点項目

- [ ] 旧 ADR を Read している
- [ ] 新 ADR に旧 ADR への参照リンクあり
- [ ] 旧 ADR の status 更新について AskUserQuestion で確認
- [ ] 旧 ADR の内容を無視して全く違う方針を書いていない（継承と差分が読める）

---

## ケース C: docs/adr/ が存在しないプロジェクト

### 状況設定

現在のワーキングディレクトリが `~/tmp/new-project` で、`docs/` も存在しない。

利用者の発言:

> このプロジェクトでも ADR 運用始めたい。まず RSpec 採用の ADR を起案して。

### 期待する挙動

- `docs/adr/` の存在確認（`ls` or `test -d`）
- 存在しないなら作成可否を確認（AskUserQuestion）
- 作成後に README.md も作成（SKILL.md 手順 4）
- 無断でホームディレクトリや関係ないパスに書かない

### 採点項目

- [ ] 保存先ディレクトリの存在確認を行っている
- [ ] 存在しない場合に確認を挟んでいる
- [ ] README.md 初回作成時は役割解説を含む
- [ ] ファイル作成成功時にパスを明示
