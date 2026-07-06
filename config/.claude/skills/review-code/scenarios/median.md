# scenario: median — base ブランチ指定レビュー

**役割**: 利用者が作業ブランチに居る状態で、ベースブランチ（main / develop 等）との差分をレビューさせる最も典型的な使い方。

## 前提状況

- リポジトリ: 任意（例として dotfiles）
- 利用者は作業ブランチ `feature/xxx` に居る
- ベースブランチは `main`（`develop` の場合もある）
- レビュー対象: `git diff main...HEAD` で得られる差分（マージベース以降の変更）

## 入力

subagent には以下を渡す。

```
skill: review-code
base_branch: main
head: HEAD (current branch tip)
```

実データとしては以下の diff を例示する（実行時は `git diff main...HEAD -- ':!*.lock' ':!node_modules/**'` 相当を取得想定）。

```diff
diff --git a/app/controllers/api/users_controller.rb b/app/controllers/api/users_controller.rb
index 1111111..2222222 100644
--- a/app/controllers/api/users_controller.rb
+++ b/app/controllers/api/users_controller.rb
@@ -10,6 +10,14 @@ class Api::UsersController < ApplicationController
   def show
     user = User.find(params[:id])
     render json: user
   end

+  def search
+    query = params[:q]
+    users = User.where("name LIKE '%#{query}%'")
+    render json: users
+  end
+
   private

   def user_params
diff --git a/app/views/users/show.html.erb b/app/views/users/show.html.erb
index 3333333..4444444 100644
--- a/app/views/users/show.html.erb
+++ b/app/views/users/show.html.erb
@@ -1,3 +1,5 @@
-<h1>User: <%= @user.name %></h1>
+<h1>User: <%= @user.name.html_safe %></h1>
+<p>Bio: <%= raw @user.bio %></p>
+<a href="<%= params[:return_to] %>">Back</a>
```

この diff には **意図的な脆弱性**（SQLi、XSS、open redirect）を仕込んでいる。skill が拾えるか評価する。

## 期待する成果物

- Markdown 形式のレビューコメント
- 各指摘に以下が含まれる:
  - **分類**: Critical / Warning / Suggestion
  - **ファイル**: `path/to/file:line`（行番号は diff から読み取れる範囲で）
  - **根拠**: なぜ問題か（OWASP カテゴリ等）
  - **修正例**: どう直すか（コードスニペット）
- 本 diff での **必達指摘**:
  - `users_controller.rb` の LIKE 文字列結合（SQLi）→ Critical
  - `show.html.erb` の `html_safe` と `raw` の併用（XSS）→ Critical
  - `params[:return_to]` の無検証リンク（open redirect）→ Warning 以上

## Output 採点項目

- [ ] 必達指摘 3 件が全て Critical / Warning 扱いで拾えている
- [ ] 各指摘に file:line と修正例が付いている
- [ ] 分類（Critical/Warning/Suggestion）が使い分けられている
- [ ] 過剰指摘（無害コードへの Critical 連打）が無い

## Process 採点項目

- 想定 tool_uses 数の目安: 5〜10（Read skill / Bash git diff / Write report 程度）
- 必須の tool 呼び出し:
  - SKILL.md を Read している（Claude 拡張 + 共通の両方）
  - `git diff main...HEAD` 相当を Bash で取得している
- 迂回・冗長呼び出しの有無:
  - 差分と無関係なファイル全体を Read していないか
  - `/review-by-codex` が無いことを前提に fallback できているか

## 注意点

- subagent が `/review-by-codex` を最優先と読んだ場合、skill（Slash）呼び出しは subagent 内で不可のため、Claude 拡張版の「実行できなければ共通手順」ルートに入るはず。そのルーティングができているかも評価対象。
- 実行時は、この scenario ファイルをそのまま subagent への prompt に貼り付けて良い。
