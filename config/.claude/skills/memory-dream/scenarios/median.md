# median シナリオ: 典型的な記憶ストアの consolidation

数十セッション運用した結果、記憶ストアに重複・矛盾・相対日付・陳腐化参照が溜まった状態。memory-dream スキルを適用し、記憶を再編する典型ケース。

## 準備（評価者が実行）

サンドボックスの記憶ストアを scratchpad 等に用意する。Claude Code ビルトイン memory と同形式（`MEMORY.md` 索引 ＋ frontmatter `name`/`description`/`metadata.type` 付きの個別ファイル）とみなす。親ディレクトリに実在ファイル `build.sh` を置き、`old_deploy.rb` は置かない（陳腐化参照の検出用）。

- `MEMORY.md`: `pref-editor` / `deploy-notes` / `api-v1` / `api-note` の 4 エントリ索引
- `pref-editor.md`（type: user）: 「ファイル削除には rm ではなく trash を使う（上位 AGENTS.md でも定められた世界のルール）」＋「エディタは vim を使う」
- `deploy-notes.md`（type: project）: 「昨日デプロイした際、build.sh を実行してから deploy した」＋「デプロイ前に old_deploy.rb を確認すること」
- `api-v1.md`（type: project）: 「API は v1 エンドポイントを使う」
- `api-note.md`（type: project）: 「API は現在 v2 に移行済み。v1 は廃止された」

## タスク

memory-dream の 4 フェーズに従い再編する。非破壊担保（スナップショット＋別途生成、ライブストア無改変）の指示に厳密に従うこと。

## 期待される挙動（採点基準）

- ライブストアを直接上書きせず、スナップショット＋別提案先に生成する。
- api の v1/v2 矛盾を最新の v2 に一本化（判断可能な矛盾）。
- 上位 AGENTS.md 由来の「rm→trash」ルールと、その旨のメタ注記を memory 側から除去。「vim を使う」は残す。
- 相対日付「昨日」を絶対日付化または削除、陳腐化参照 `old_deploy.rb` を除去、`build.sh`（実在）は残す。
- 索引を lean な 1 行フックに再生成し、統合を反映。
