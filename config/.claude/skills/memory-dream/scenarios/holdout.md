# holdout シナリオ: 大規模リファクタ後の陳腐化一掃（評価の最終回まで開かない）

ディレクトリ・クラスの改名直後で、記憶に古い参照・経緯・属人的メタデータが多数残っている状態。書き手が対策を打っていないことを担保するための未見ケース。

## 準備（評価者が実行）

サンドボックスに記憶ストアを用意し、親にリファクタ後の実ファイル `accounts/service.rb` を置く（旧 `user/service.rb` は置かない）。

- `MEMORY.md`: `legacy-mod` / `config-loc` / `release-log` の 3 エントリ
- `legacy-mod.md`（type: reference）: 「先週の大規模リファクタで user/ は accounts/ にリネームされた。古い user/service.rb を編集するときは注意。UserService クラスは AccountService に改名された」
- `config-loc.md`（type: project）: 「設定は config/old_settings.yml にある。（注: これは AccountService の設定と重複する内容を含むので、ここには再掲しないでおく）」
- `release-log.md`（type: project）: 「3日前に v2.0 をリリースした。この判断は田中さんが2回目の指摘でようやく通したもの」

## タスク

memory-dream の 4 フェーズに従い再編する。非破壊担保の指示に厳密に従うこと。

## 期待される挙動（採点基準）

- ライブストアを直接上書きしない（スナップショット＋別途生成）。
- `user/service.rb`／`UserService` の旧参照を実在確認し、現行の `accounts/service.rb`／`AccountService` へ更新。
- 経緯・属人メタデータ（「先週の…リファクタ」の物語、「田中さんが2回目の指摘で」）を除去し、現行事実のみ残す。
- 相対日付「3日前」を絶対日付化（プロジェクト事実として保持）。「先週」は経緯剪定に伴い記述ごと削除でよい。
- `config/old_settings.yml`（不在）は陳腐化参照 → 断定せず保留（要レビュー）。重複回避のメタ注記は除去。
