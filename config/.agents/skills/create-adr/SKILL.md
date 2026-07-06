---
name: create-adr
description: MADR形式でArchitecture Decision Recordを作成する。ADR作成、ADR検討、意思決定記録、決定を記録、と言われたときに使用。
---

# ADR作成

## 手順概要

1. **情報収集フェーズ** — 必須情報が揃っているか点検。不足していれば AskUserQuestion で確認する
2. **環境情報取得** — 日付・利用者名・保存先パス・既存 ADR
3. **ドラフト作成** — テンプレートに沿って MADR を埋める
4. **関連 ADR 参照** — 既存 ADR を探して引用
5. **ファイル作成 + プレビュー** — `docs/adr/` 配下に書き出し、パスを表示
6. **README 更新**（指示があった場合のみ）
7. **レビュー**（任意）

---

## 1. 情報収集フェーズ

利用者の初回入力で **以下の必須項目が揃っているか** を点検する。

- 解決すべき問題（Context and Problem Statement）
- 検討した選択肢（Considered Options）— 少なくとも 2 案
- 判断基準（Decision Drivers）
- 選択肢ごとのメリット / デメリット / 影響範囲
- 起案ステータス（既定は `proposed`、明示があれば `accepted`）

**タイトルだけしか与えられない場合**、または必須項目のうち 2 つ以上が未記入の場合は、**ドラフト作成前に AskUserQuestion で対話的に補う** こと。推測で捏造した内容で ADR を書かない。

- 補う順序: Context → Drivers → Options（メリット・デメリット・影響範囲）
- 情報が十分に揃うまでファイルを作成しない（テンプレだけ先出しも禁止。空欄テンプレは混乱を招く）

`Auto mode` 等で AskUserQuestion が使えない場合は、**推測で埋めた箇所を自己申告として明記** し、ADR の More Information 末尾にも「確認中」の旨を追記する。

### Auto mode での補完範囲（捏造と補完の境界）

AskUserQuestion が使えない状況で迷ったら以下の優先順位で判断する。

- **Context / 解決すべき問題**: 利用者の発言から確実に読み取れる範囲を超えて拡張しない。根拠薄弱な背景ストーリーを書くのは禁止
- **Decision Drivers**: 利用者発言からの推定で 2〜3 個までは可。「Option を成立させるための後付け理由」は禁止
- **Considered Options**: **最低 2 案**（利用者の本命 + 自然な対立案 1 つ）までは補完可。3 案目以降を無理に並べるくらいなら、「確認中事項」として More Information に明記して 2 案で起案する
- **Decision Outcome の理由**: 利用者発言と Decision Drivers から直接導ける範囲のみ

「数合わせの選択肢」と「正直な不完全さ」を比べたら、後者を選ぶこと。

## 2. 環境情報取得

以下を実行して確定する。Bash が使える環境での例:

```bash
date +%Y-%m-%d          # 日付（今日）
date +%H%M              # 時刻（HHMM、ファイル名 prefix 用）
git config user.name    # 利用者名（decision-makers）
pwd                     # ワーキングディレクトリ（docs/adr/ の存在確認の足掛かり）
ls docs/adr/README.md   # README の有無
```

値が取れない場合は AskUserQuestion で確認。環境変数や CLAUDE.md の `currentDate` などが使える場合はそれを優先してよい。

## 3. ドラフト作成

後述のテンプレートに沿って MADR 本文を作成する。

### タイトル命名規則

- **英語 snake_case** を原則とし、動詞から始める（例: `introduce_trivy_for_weekly_security_scan`）
- 日本語タイトルが既存に多い領域（例: 既存ファイルが `ADR運用開始.md` のような命名）や、利用者が明示的に日本語を指定した場合は日本語可
- 判断に迷ったら `ls docs/adr/` で直近 5 件の命名規則を確認し、多数派に合わせる
- ファイル名は `<YYYY-MM-DD>_<HHMM>_<タイトル>.md`（ハイフン・コロン・スペース禁止、空白は `_`）
  - `HHMM` は 24 時間表記の時分（例: `0930`, `1745`）。同日内の複数 ADR を時系列で並べやすくするための prefix

### 検討仕様の書き方

- **疑似コード優先**。クラス定義・構造・インターフェース設計を中心に記述し、実装コードは書かない
- Considered Options は **3 案以上を推奨**（採用案 + 比較対象 2+）。各案に:
  - **メリット**（Good）
  - **デメリット**（Bad）
  - **影響範囲**（変更が及ぶファイル・運用・スケジューラ等）
- Decision Outcome には「なぜこの選択肢を選んだか」の根拠を明記

### Definition of Done の書き方

- 本 ADR が完了したと判断できる **チェックリスト形式** で書く
- 以下のうち該当するものを選んで列挙:
  - 対象ファイル（Brewfile, Makefile, cookbooks/\*）に変更が反映されたこと
  - テスト / `make test` / CI 等で検証できていること
  - 関連ドキュメント（README, AGENTS.md 等）への追記が完了していること
  - ADR のステータスが accepted に遷移していること

## 4. 関連 ADR 参照

新 ADR が既存 ADR と関連する場合、**必ず引用する**。機械的に探す手順:

```bash
# キーワードで既存 ADR を grep
grep -l -i "<キーワード>" docs/adr/*.md | grep -v README

# 既存 ADR 一覧から最近のものを見る
ls -t docs/adr/20*.md | head -10
```

- 関連が強いものは More Information に「関連 ADR」節を設け、**リポジトリルート基準の相対パス** で列挙（例: `docs/adr/2026-04-01_*.md`）
- 既存 ADR を **supersede する場合**: 新 ADR の Context に変更理由を明記し、旧 ADR の status を `superseded` に変更するかを AskUserQuestion で確認
  - 変更合意が取れたら旧 ADR を編集（`status: superseded` + `superseded-by:` コメント）

## 5. ファイル作成 + プレビュー

- `docs/adr/` が存在しない場合: AskUserQuestion で作成可否を確認してから `mkdir -p docs/adr`
- Write ツールで `docs/adr/<YYYY-MM-DD>_<HHMM>_<title>.md` を作成
- **作成直後に絶対パスを画面に表示**（ユーザーがすぐ開ける状態にするため）
- `~/bin/md-open <絶対パス>` を **最終成果物提示時に 1 回のみ** 実行（編集途中の md-open は抑制）

## 6. README 更新

- 既定: `docs/adr/README.md` の ADR 一覧は **自動更新しない**。指示がなければ触らない
- `README.md に追加しておいて` 等の明示があった場合のみ、表の最終行に本 ADR のエントリを追記
- README.md 自体が存在しない場合は、役割解説テンプレ + 空の ADR 一覧で新規作成

## 7. レビュー（任意）

利用者から明示的にレビュー依頼があった場合のみ実施。

- 文章の網羅性・論理構造の確認が主目的。セキュリティ特化の `/review-code` とは目的が異なる
- 代替: Claude Code の `/review-by-codex` で文章レビュー、または AskUserQuestion で人手レビュー依頼
- 自動呼び出しはしない（skill 連鎖の無限ループ防止）

---

## テンプレート

```markdown
---
status: proposed
date: {今日の日付 (YYYY-MM-DD)}
decision-makers:
  - {git config user.name}
---

# {タイトル}

## Context and Problem Statement

{解決すべき問題や背景を記述}

## Decision Drivers

* {決定に影響を与える要因1}
* {決定に影響を与える要因2}

## Considered Options

1. **{選択肢1}**
   - Good: {メリット}
   - Bad: {デメリット}
   - 影響範囲: {変更が及ぶ箇所}
2. **{選択肢2}**
   - Good: ...
   - Bad: ...
   - 影響範囲: ...
3. **{選択肢3}**
   - ...

## Decision Outcome

選択: **{選んだオプション}**

理由: {なぜこのオプションを選んだか}

### 疑似的な実装イメージ

```
{pseudocode or config snippets}
```

## Consequences

### Good

* {良い結果1}

### Bad

* {悪い結果1}

## Definition of Done

- [ ] {完了条件1}
- [ ] {完了条件2}

## More Information

### 関連 ADR

- `docs/adr/<関連ADR>.md`: {関連の要約}

### 参考文献

- {URL や書籍}
```

## ステータスの種類

- `proposed`: 提案段階（既定）
- `accepted`: 承認済み（利用者が明示した場合、または既に合意が取れている場合のみ）
- `deprecated`: 廃止
- `superseded`: 他の ADR に置き換え。`superseded-by: docs/adr/<新ADR>.md` を frontmatter に追加

## 実行時の確認ルール

- 必須情報が 2 項目以上欠けていたら AskUserQuestion で対話補完する
- 日付 / 利用者名が取得できない場合も AskUserQuestion で確認
- `docs/adr/` 存在確認の結果で分岐判断が必要な時も AskUserQuestion
- 既存 ADR を supersede する場合は、旧 ADR を編集してよいかを AskUserQuestion
