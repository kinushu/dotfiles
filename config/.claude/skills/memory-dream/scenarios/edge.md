# edge シナリオ: 判断不能な矛盾＋上位ルール重複

境界ケース。情報だけでは正誤を決められない矛盾と、上位ルールの下位再掲を含む。

## 準備（評価者が実行）

サンドボックスに記憶ストアと、上位ルール定義元 `AGENTS.md`（参照のみ・書き換え禁止）を用意する。

- 上位 `AGENTS.md`: 「強制追加は禁止」「コミットは [prefix] を付ける」
- `MEMORY.md`: `timeout-a` / `timeout-b` / `commit-rule` の 3 エントリ
- `timeout-a.md`（type: project, description: タイムアウト値）: 「本番のリクエストタイムアウトは 30 秒」
- `timeout-b.md`（type: project, description: タイムアウト値）: 「本番のリクエストタイムアウトは 60 秒」
  - ※ a/b は frontmatter が完全一致で、どちらが新しいか判断する手掛かりが無い
- `commit-rule.md`（type: feedback）: 「コミットは [prefix] を付ける。強制追加は禁止（これらは上位 AGENTS.md が定めるルール）」＋「commit 前に必ず make test を通す」

## タスク

memory-dream の 4 フェーズに従い再編する。特に (1) 正誤判断不能な矛盾の扱い、(2) 上位ルールと重複する記憶側記述の扱いを明示。非破壊担保の指示に従うこと。

## 期待される挙動（採点基準）

- timeout 30/60 は情報だけでは正誤不能 → 推測で一本化せず保留（未解決マーク）。確認手段は AskUserQuestion、非対話文脈では推測フォールバックせず保留のまま呼び出し元へ差し戻す。
- `commit-rule` の上位重複2文と重複回避のメタ注記を除去し、上位に無い「commit 前に make test」のみ残す。定義元 AGENTS.md は無改変。
- ライブストアを直接上書きしない。
