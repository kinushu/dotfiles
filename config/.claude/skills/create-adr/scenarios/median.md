# scenario: median — dotfiles 技術選定 ADR 起案

**役割**: dotfiles リポジトリで新しいツール/方針を採用する際の ADR 起案。最も多い使い方。

## 前提状況

- リポジトリ: `/Users/username/dotfiles`
- ADR 保存先: `docs/adr/`（既存、README.md あり）
- 既存 ADR の命名: `YYYY-MM-DD_動詞_目的.md`（日本語タイトルも一部混在）
- 利用者: username（git user）
- 起案ステータス: `proposed`

## 入力

利用者の発言（想定）:

> Brewfile に trivy を追加してセキュリティスキャンを導入したい。週次で `make security-scan` から呼び出す想定。`make upgrade` で trivy 自体も自動更新する。ADR を起こしておいて。

## 期待する成果物

- ファイル: `docs/adr/<today>_introduce_trivy_security_scan.md`（日付は実行日）
- 中身: MADR 形式
  - frontmatter に `status: proposed` / `date: <today>` / `decision-makers: [username]`
  - タイトル: 「`introduce_trivy_security_scan`」相当（英語、動詞先頭）
  - Context and Problem Statement: 現状のセキュリティスキャン有無と trivy 採用の背景
  - Decision Drivers: 定期実行・自動更新・既存 Brewfile 運用との整合
  - Considered Options: 少なくとも 3 選択肢（例: trivy / grype / 未導入で放置）を メリット・デメリット・影響範囲付きで
  - Decision Outcome: 推奨と理由
  - Consequences: Good / Bad
  - Definition of Done: 具体的なチェックリスト
  - More Information: 参考リンクがあれば

## Output 採点項目

- [ ] frontmatter が MADR 形式で揃っている
- [ ] ファイル名が `YYYY-MM-DD_` プレフィックス + kebab/snake_case
- [ ] Considered Options が 2 つ以上、各案のメリット・デメリット付き
- [ ] Decision Outcome に「なぜ選んだか」の根拠
- [ ] Consequences の Good/Bad が空でない
- [ ] Definition of Done が具体的なチェックリスト（動作確認手順や成果物）
- [ ] 関連する既存 ADR がある場合は引用（`npm_security_settings_against_supply_chain_attack.md` 等）
- [ ] 作成直後にファイルパスを表示している
- [ ] ADR が作成されたら `~/bin/md-open` でプレビューが開かれる

## Process 採点項目

- 想定 tool_uses 数: 5〜10（Read skill + 既存 ADR 確認 + Write + md-open + 必要なら AskUserQuestion）
- 必須 tool:
  - SKILL.md の Read（共通 + Claude 拡張）
  - `docs/adr/` 既存ファイル確認（命名規則の準拠確認）
  - Write（新 ADR ファイル）
  - Bash (`~/bin/md-open`)
- 迂回チェック:
  - 日付取得を推測で進めず `date` 系で確認しているか
  - decision-makers を勝手に補完せず確認しているか
  - タイトル命名で既存 ADR を参照しているか

## 注意

subagent には「利用者の発言」を発話として渡し、以下の環境情報も明示する。

- 今日の日付（prompt 側で明示）
- 利用者名（username）
- リポジトリパス（/Users/username/dotfiles）
- 既存 ADR 一覧へのパス（`docs/adr/README.md`）

成果物のファイル作成は実環境には行わず、**subagent の返答として ADR 本文を文字列で返させる** 方式にする（実ファイル汚染を避ける）。
