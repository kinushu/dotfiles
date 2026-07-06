# scenario: edge — review-code の境界ケース

median では表面化しない穴を炙り出す。3 ケースを同梱。

---

## ケース A: /review-by-codex が利用不可

### 状況設定

- Claude Code 拡張版は「/review-by-codex を最優先で実行する」と規定している
- 但し subagent（general-purpose）からは Skill tool での `/review-by-codex` 呼び出しはできない
- さらに `codex` CLI が未インストール or 未認証の想定

### 入力

```
skill: review-code
base_branch: main
head: HEAD
note: codex CLI が利用不可な環境で実行してください
```

diff は median と同じものを使用。

### 期待する挙動

- 「/review-by-codex 優先」の指示を読んでも、subagent 環境では起動不可と判断し fallback する
- 勝手に `codex` コマンドを探して 3 回以上リトライしない（即座に共通手順に移行）
- レビュー成果物の末尾 or 冒頭に「/review-by-codex がスキップされた旨」を 1 行記載

### 採点項目

- [ ] `codex --version` 等の疎通チェックを 1 回で打ち切っている
- [ ] 共通手順にフォールバックできている
- [ ] スキップ理由が成果物に記録されている

---

## ケース B: Ruby 固有の危険パターン

### 状況設定

- 現 SKILL.md のチェック項目は SQLi / XSS / CSRF 等の Web 一般脆弱性のみ
- Ruby 固有の危険（`eval`, `Kernel#open`, `YAML.load`, `Marshal.load`, `send` の動的ディスパッチ等）への言及が無い
- この diff でそれらを拾えるかで SKILL.md の汎化不足を検出する

### 入力

```diff
diff --git a/lib/importer.rb b/lib/importer.rb
index 1111111..2222222 100644
--- a/lib/importer.rb
+++ b/lib/importer.rb
@@ -1,5 +1,20 @@
 class Importer
-  def self.from_yaml(path)
-    YAML.safe_load(File.read(path))
+  def self.from_yaml(path)
+    YAML.load(File.read(path))
   end
+
+  def self.execute(code)
+    eval(code)
+  end
+
+  def self.fetch(url)
+    Kernel.open(url).read
+  end
+
+  def self.invoke(obj, method_name, arg)
+    obj.send(method_name, arg)
+  end
+
+  def self.restore(blob)
+    Marshal.load(blob)
+  end
 end
```

### 期待する挙動

- `YAML.safe_load` → `YAML.load` への改悪を Critical として検出
- `eval` 直渡しを Critical
- `Kernel#open` で URL 開く脆弱性（`URI.open` も注意）を Warning 以上
- `send` の動的メソッド呼び出しで private method 到達を Warning 以上
- `Marshal.load` をユーザー入力に使う危険を Critical

### 採点項目

- [ ] 5 つの危険パターンのうち 3 つ以上を拾えている
- [ ] 「SKILL.md に明記が無い項目」でも Ruby 一般知識から指摘できている
- [ ] 拾えなかった場合、subagent の自己申告レポートで「SKILL.md に Ruby 固有の記載が薄い」旨を挙げられる

---

## ケース C: 複数ファイル大量 diff（monorepo 模擬）

### 状況設定

- 15 ファイル / 800 行以上の diff を与え、スコープの切り方を観察
- 本 SKILL.md に「スコープ分割」「優先順位付け」の手順が無いため、subagent がどう振る舞うか

### 入力（概要のみ、subagent には全文を渡す前提）

- `app/controllers/*.rb` 6 ファイル (+200 行 / -50 行)
- `app/views/**/*.erb` 4 ファイル (+150 行)
- `config/routes.rb` (+20 行)
- `db/migrate/*.rb` 2 ファイル (+80 行 — カラム追加)
- `spec/**/*.rb` 3 ファイル (+400 行)

### 期待する挙動

- 全ファイルを総ざらいするのではなく、優先度（controllers > views > migrate > specs の順で深掘り）を付ける
- specs ディレクトリは低優先と判断し、軽く流す
- 成果物が長くなる場合、サマリを先頭に置く

### 採点項目

- [ ] tool_uses が 30 回を超えない（目安）
- [ ] 成果物が 2000 行を超えない
- [ ] Critical / Warning / Suggestion の件数バランスが偏りすぎない
- [ ] specs への過剰指摘が無い

### 劣化パターン

- 全ファイルを Read → トークン肥大 → タイムアウト
- specs の些末な指摘で埋め尽くされ Critical が埋没
- 優先度付けをせず「順番通り」レビュー
