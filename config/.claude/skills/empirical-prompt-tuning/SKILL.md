---
name: empirical-prompt-tuning
description: skill の品質を客観評価して改訂をライトに回す。新規 skill 作成や大幅改訂の時に使用。
---

# empirical-prompt-tuning

skill を知らない状態の subagent を Task tool で dispatch し、実行ログ・成果物・`<usage>` メタデータを客観指標として回収して、SKILL.md の曖昧点を差分修正で潰していく経験的プロンプトチューニングのワークフロー。

**前提: Claude Code 専用。** Task tool と `<usage>` メタデータに依存するため、Codex CLI / Gemini CLI では動作しない。他ツール経由で呼ばれた場合は実行を中断し、Claude Code での再実行を案内すること。

関連 ADR: `docs/adr/2026-04-23_adopt_empirical_prompt_tuning_for_skill_quality.md`

## When to Apply

### 適用する（必須）

- 新規 skill を追加するとき
- 既存 skill の SKILL.md 行数が **30% 以上** 変わる改訂
  - 判定式: `(追加行数 + 削除行数) ÷ 変更前の総行数 ≥ 0.30`
  - `git diff --stat HEAD -- <path>/SKILL.md` の値を使う
  - YAML frontmatter の行は除外してカウント
- 既存 skill の `description` を変更するとき（呼び出し条件が変わるため）

### 適用しない（不要）

- typo 修正・表記ゆれ統一・リンク追加のみの変更
- 参考文献セクションの追加
- YAML frontmatter の軽微な修正（name の kebab-case 統一など）
- 30% 未満の本文改訂で description に変更がないもの

迷ったら AskUserQuestion で適用するかどうかをユーザーに確認すること。

## 対象 skill の指定

本 skill を起動する際、**評価対象の skill 名を必ず引数または対話で特定する** こと。推測しない。

- 引数で渡される例: `empirical-prompt-tuning review-code`
- 未指定の場合: AskUserQuestion で候補を提示して選ばせる（`config/.agents/skills/` と `config/.claude/skills/` 配下を列挙）

## 評価の 2 軸

| 軸 | 観測対象 | 目的 |
|---|---|---|
| **Output 評価** | 成果物（生成された Markdown・コミットメッセージ・ADR 等） | 書き手が期待した完成形に達しているか |
| **Process 評価** | subagent の tool_use 列・所要 tool_uses 数・`<usage>` の tokens・手順の遵守状況 | 指示通りに辿れているか、無駄な探索・迂回が起きていないか |

**乖離は曖昧指示のサイン。** Output が良いのに Process が荒れている場合は「たまたま当たっただけ」で再現性がない。Process が綺麗なのに Output が外れている場合は「手順は書けているが狙いが伝わっていない」。どちらの症状が出たかで差分修正の方向を決める。

## `[critical]` チェックリスト

subagent に skill を実行させる前と後に、以下を必ずチェックする。これらは **省略不可**。

- `[critical]` 評価対象 skill の **SKILL.md を未改訂状態でコミット済みにする**（baseline の再現性担保）
- `[critical]` subagent には SKILL.md の **description だけを渡し**、body は「subagent が自分で読む」状態にする（書き手バイアス回避）
- `[critical]` `scenarios/median.md` `scenarios/edge.md` は **改訂前に作成済み**（後から追加すると対策バイアスが入る）
- `[critical]` `scenarios/holdout.md` は **改訂の最終回まで開かない**（書き手が対策を打ったケースで過学習していないかの検証用）
- `[critical]` 各イテレーションで `<usage>` の `tool_uses` 数・`input_tokens`・`output_tokens` を記録する
- `[critical]` 収束判定が 2 回連続で満たされるまで打ち切らない（1 回の偶然で判定しない）
- `[critical]` holdout で劣化が出たら **収束とみなさず** 再度差分修正に戻る

## subagent dispatch テンプレ

Task tool で subagent を起こす際の擬似コード。`subagent_type` は原則 `general-purpose`（skill を知らない状態にするため）。

```text
Agent({
  description: "Run <skill-name> against scenario <scenario-file>",
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: """
  以下の scenarios ファイルの内容に沿って skill "<skill-name>" を実行し、
  成果物と自己申告レポートを返してください。

  ## 実行する skill
  - 名前: <skill-name>
  - 場所: <path-to-SKILL.md>
  - SKILL.md は自分で Read して解釈してください（この prompt には本文を含めていません）

  ## 入力シナリオ
  <scenarios/median.md などの内容をそのまま貼る>

  ## 返してほしいもの
  1. 成果物そのもの（Markdown なら Markdown を、コミットメッセージならその文字列を）
  2. 自己申告レポート:
     - skill の手順のうち、迷ったステップ
     - SKILL.md で曖昧だと感じた表現（引用付き）
     - 代替解釈が生じた箇所
  """
})
```

実行系 subagent は標準機（alias: `sonnet`）に固定する。`[critical]` のベースライン要件が求める再現性を、セッションモデルの偶然に依存させないため。なお `CLAUDE_CODE_SUBAGENT_MODEL` 等の環境変数が設定されていると `model` 上書きが無効化される場合があるため、dispatch 前に有無を確認し、固定指定があってモデルが変わる場合はその旨をスコアシートに明記する（再現性の前提が崩れるため）。

subagent が終了したら、返答の `<usage>` ブロックから `tool_uses` 数、`input_tokens`、`output_tokens` を抜き出して記録する。

## 8 フェーズ ワークフロー

| フェーズ | 名称 | やること | 完了条件 |
|---|---|---|---|
| 0 | description-body alignment | SKILL.md の description（呼び出し条件）と body（実行内容）が一致しているか静的チェック | 不整合ゼロ |
| 1 | baseline prep | 改訂前 skill で `scenarios/median.md` と `scenarios/edge.md` を subagent に実行させ、tool_uses・成果物・自己申告レポートをベースラインとして保存 | ベースライン 2 本取得 |
| 2 | bias-free reading | 別 subagent に SKILL.md を「実行せず読むだけ」dispatch し、description と body から誤解が生じないかヒアリング | 解釈の分岐点が洗い出されている |
| 3 | execution | フェーズ 1 と同じシナリオで再実行し、今度は Output/Process の両軸で採点 | スコアシート記入完了 |
| 4 | dual-sided eval | Output 軸と Process 軸の乖離を検出し、曖昧指示箇所（引用付き）を列挙 | 乖離リスト作成 |
| 5 | differential application | 曖昧点 1 箇所ずつに **最小差分の修正** を SKILL.md に入れる（一度に複数箇所を変えない） | 差分コミット（1 箇所 1 コミット推奨） |
| 6 | re-eval | 改訂後 skill で同じ `median.md` + `edge.md` を再実行し、差分修正の効果を測定 | スコア比較表作成 |
| 7 | convergence | 同シナリオで **2 回連続でスコア変化なし** かつ **未見の `scenarios/holdout.md` で劣化なし** を確認 | 収束判定 OK |

収束しない場合はフェーズ 4 に戻って別の曖昧点を特定する。3 周回しても収束しない skill は **SKILL.md の構造そのものが問題** の可能性があるため、ADR を起こして設計から見直す。

フェーズ 4（乖離分析）とフェーズ 7（収束判定）の採点・乖離分析は判断負荷が高いため、高知能機（alias: `opus`）の subagent へ委託してよい。

## scenarios/ サンプル

本 skill ディレクトリ直下の `scenarios/` に、骨組みサンプルを同梱している。

- `scenarios/median.md`: 典型的な利用ケース。ほとんどの利用者が想定する使い方
- `scenarios/edge.md`: 境界ケース。引数が曖昧・入力が不完全・外部ツールが落ちている等
- `scenarios/holdout.md`: 未見ケース。書き手が対策を打っていないことを担保するため、**評価の最終回まで開かない**

新しい skill を評価対象にするときは、対象 skill ディレクトリ直下に `scenarios/` を作り、median / edge / holdout の 3 本を用意する。サンプルはあくまで雛形。

## スコアシート例

```markdown
## iteration-N / scenario: median

### Output
- [ ] 成果物フォーマットが期待通り
- [ ] 必須項目が埋まっている
- [ ] 過不足のある記述がない

### Process
- tool_uses: N
- input_tokens: N
- output_tokens: N
- 迷いのあった手順: <subagent の自己申告>
- 書き手が意図しない tool_use の迂回: 有 / 無

### Delta vs previous iteration
- Output: +0 / -0 / 変化なし
- Process: tool_uses N → N (Δ)
```

スコアシートは `docs/skill-evaluations/<target-skill>/iteration-N.md` に保存する運用（C3）を将来的に高優先 skill で導入する可能性があるが、現時点では skill 利用者の好きな場所で良い。

## 実行時の確認ルール

- 評価対象 skill が未指定 → AskUserQuestion で確認
- 30% 判定がグレー（25〜35% など）→ AskUserQuestion で「適用するかどうか」を確認
- subagent dispatch が 3 回連続で失敗する → 実行を中断しユーザーに報告
- holdout を途中で開いてしまった疑いがある → 収束判定前に正直に申告する

## .md 成果物のプレビュー

イテレーションログ (`iteration-N.md`) や改訂後の SKILL.md 等、**成果物として提示する .md を作成・更新した場合は** Bash で以下を実行する（上位 CLAUDE.md のルールに準拠）。

```bash
~/bin/md-open "/absolute/path/to/file.md"
```

小刻みな編集の途中では不要。ユーザーに最終成果物を見せる時点で 1 回だけ。

## 参考文献

- mizchi「Empirical Prompt Tuning」: https://zenn.dev/mizchi/articles/empirical-prompt-tuning
- 参考 SKILL.md: https://github.com/mizchi/chezmoi-dotfiles/blob/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md
