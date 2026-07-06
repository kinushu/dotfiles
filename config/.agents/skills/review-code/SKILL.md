---
name: review-code
description: セキュリティ重視のコードレビューを行う。レビュー、review、PRを見て、コードをチェック、と言われたときに使用。
---

# セキュリティ重視コードレビュー

## レビュー対象スコープ

- **原則**: レビュー対象は `git diff <base>...HEAD` 相当で与えられる差分のみ。差分外のファイルは **指摘の根拠を補うために必要最小限** だけ参照する（例: `ApplicationController` の `before_action` 確認）。
- **ベースブランチ**: 呼び出し時に指定が無ければ `main` を仮定。ただし `develop` 運用のリポジトリもあるため、曖昧な場合は AskUserQuestion で確認すること。
- **スコープ分割**: 差分が 15 ファイル以上 or 800 行以上のときは優先度を付け、以下の順で深掘りする。
  1. controller / handler / endpoint（外部入力の受口）
  2. view / template / serializer（出力経路）
  3. model / service（ビジネスロジック）
  4. migration / schema（データ境界）
  5. spec / test（深掘り対象外、軽く流す）

## チェック項目（優先度順）

### 1. セキュリティ（最重要）
- [ ] SQLインジェクション対策
- [ ] XSS対策（エスケープ、サニタイズ、`html_safe` / `raw` の濫用）
- [ ] 認証・認可の適切な実装（`before_action`, Pundit/CanCan 等の policy scope）
- [ ] 機密情報のハードコード
- [ ] 入力値バリデーション（nil / 空文字 / 長さ上限）
- [ ] CSRF対策
- [ ] パストラバーサル
- [ ] オープンリダイレクト（`redirect_to params[...]` 系）

### 2. データ保護
- [ ] 個人情報の適切な取り扱い
- [ ] ログに機密情報を出力していないか
- [ ] 暗号化が必要な箇所
- [ ] API レスポンスでの過剰カラム漏洩（`render json: model` の素返し等）

### 3. 基本的な品質
- [ ] エラーハンドリング
- [ ] 境界条件のチェック
- [ ] リソースリーク

### 4. Ruby 固有の危険パターン

Ruby / Rails の diff を扱うときは以下も必ず確認する。

- [ ] `eval` / `instance_eval` / `class_eval` への外部入力
- [ ] `send` / `public_send` の動的メソッドディスパッチに外部入力（private method 到達のリスク）
- [ ] `YAML.load` / `YAML.unsafe_load`（`YAML.safe_load` を推奨）
- [ ] `Marshal.load` へのユーザー入力（RCE 直結）
- [ ] `Kernel#open` / `URI.open` の URL 渡し（SSRF）
- [ ] `Object.const_get` / `constantize` に外部入力（任意クラス取得）
- [ ] `system` / `exec` / バッククォートへの shell メタ文字の注入

## 言語/フレームワーク前提

- diff のファイル拡張子・ディレクトリ構造・import 文から言語と FW を推定し、成果物の冒頭で明示すること（例: 「Rails 7 / PostgreSQL と推定」）。
- 推定が割れる場合は AskUserQuestion で確認。
- Ruby 以外の diff が来た場合も、このチェックリストの 1〜3 節（Web 一般脆弱性）は適用可能。4 節（Ruby 固有）は該当言語の等価な危険パターンに読み替える。

## レビューコメントの形式

### 分類ラベル

- **Critical**: セキュリティ上の問題（マージ前に必ず修正）
- **Warning**: 潜在的な問題（修正推奨）
- **Suggestion**: 改善提案（任意）

### 各指摘に含める情報（必須）

```markdown
#### [Critical-N] 端的なタイトル

- **分類**: <Critical / Warning / Suggestion> / <サブ分類: SQLi / XSS / 認可 など>
- **ファイル**: `path/to/file.rb:LINE`（diff 上の新ファイル行番号）
- **該当コード**:
  ```<lang>
  <該当行の抜粋>
  ```
- **根拠**: なぜ問題か。可能なら OWASP / CWE / Rails Guide 等への参照
- **修正例**:
  ```<lang>
  <直した後のコード>
  ```
```

### 成果物全体の構造

1. 冒頭: 対象 diff の要約（ファイル数・変更行数・推定言語/FW）と **Critical / Warning / Suggestion の件数サマリ**
2. 本体: 指摘を Critical → Warning → Suggestion の順に列挙
3. 末尾: `/review-by-codex` をスキップした場合はその旨を 1 行記載
4. 該当なしのチェック項目は、以下の方針で「確認済み（該当なし）」節にまとめる。
   - **チェック項目 1 節（セキュリティ）と 4 節（Ruby 固有）は全項目を走査した旨を列挙**（過剰指摘防止 + 網羅性の明示）
   - 2 節（データ保護）・3 節（基本品質）は特筆すべきもののみ

## 差分外ファイルを参照できない場合の判断

- 認可判定等で `ApplicationController` や `routes.rb` など **差分外ファイルの確認が必要** だが、以下の理由で参照不能な場合がある。
  - diff 埋め込み実行モード（リポジトリ本体が手元に無い）
  - subagent 環境でワーキングディレクトリ制約
- この場合、**保守的に Warning 止まり** とし、「差分外ファイル未確認のため根拠不足」と根拠欄に明記する。
  - 例外: diff 内のコードだけで脆弱性が確定するもの（SQLi / XSS / Marshal.load 等）は参照不要で Critical。
- 「本来 Critical の疑いだが Warning で留めた」旨を指摘に併記し、読み手が実コードで確認できるようにする。

## 成果物の提出方法

- **既定**: レビュー成果物はチャット（呼び出し元）に Markdown で返す。ファイル化は不要。
- **.md 化する場合**（例: ユーザーが「ファイルに保存して」と明示した場合、PR コメントへ貼る用の下書きを作る場合）は、保存後に上位 CLAUDE.md の規定に従い `~/bin/md-open` を 1 回実行する。
- 中間的な成果物（診断の途中経過・スコアシート等）は原則ファイル化しない。
