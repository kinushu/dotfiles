---
name: audit-claude-config
description: Claude Code の設定ファイル類（ユーザースコープ / プロジェクトスコープ）を公式 Steering ガイドの 7 メカニズム観点で監査し、重大度付きの所見と HTML レポートを作成する。設定監査・config audit・steering 準拠チェック・設定の改善提案、と言われたときに使用。
---

# Claude Code 設定監査スキル（audit-claude-config）

## 目的

Anthropic 公式ガイド「Steering Claude Code: skills, hooks, rules, subagents, and more」の枠組みに照らし、Claude Code の設定ファイル類が適切に配置・運用されているかを監査する。トークンコスト・遵守強度・コンパクション動作のトレードオフ観点でギャップを洗い出し、**重大度付きの所見**と**優先対応プラン**を HTML レポートにまとめる。

- 出力は「提案」まで。設定の変更・破壊的操作は本スキルでは行わない（別途承認を得てから実装する）。
- 参考: https://claude.com/ja/blog/steering-claude-code-skills-hooks-rules-subagents-and-more

## 手順

### 1. 評価基準を確認する（必要なら最新化）

下記「評価ルーブリック（7 メカニズム）」を基準に用いる。鮮度を上げたい場合のみ、上記 URL を WebFetch して 7 メカニズムの推奨・アンチパターンの差分を取り込む（取得失敗時はルーブリックのみで続行してよい）。

### 2. インベントリを収集する

**収集前にスコープ確認ゲートを通す**: 対象スコープ（ユーザーのみ / プロジェクトのみ / 両方）が依頼で明示されていれば、それに従う。明示されておらず曖昧なら、推測で進めず確認する（同じ機会に出力形式も確認してよい。既定は HTML レポートのため、指定があればそれに従い、無ければ HTML で進める）。スコープ確定後、対象スコープのみを列挙する。

確定したスコープについて機械的に列挙する。推測で埋めず、実ファイルを確認する。

- **ユーザースコープ**（`~/.claude/`）: `CLAUDE.md`、`settings.json`、`settings.local.json`、`rules/`、`skills/`、`agents/`、`hooks/`、`output-styles/`、`commands/`。シンボリンク先の実体（dotfiles 管理なら `config/.claude/` 等）も追う。
- **共通スコープ**（`~/.agents/`）: `AGENTS.md`、`skills/`。
- **プロジェクトスコープ**（カレントリポジトリ）: ルート `CLAUDE.md` / `AGENTS.md`、`.claude/settings.json`（committed）、`.claude/settings.local.json`（gitignored）、`.claude/rules|skills|agents|output-styles/`。

収集の例（環境に合わせて調整）:

```bash
ls -la ~/.claude/ ~/.agents/ ./.claude/ 2>/dev/null
wc -l ~/.claude/CLAUDE.md ~/.agents/AGENTS.md ./CLAUDE.md ./AGENTS.md 2>/dev/null   # 行数。CLAUDE.md は 200 行以下が目安（200 行超で要注意、300 行超は肥大化＝High 寄り）
for d in rules agents output-styles hooks skills; do \
  for base in ~/.claude ./.claude; do [ -e "$base/$d" ] && echo "EXISTS $base/$d" || echo "MISSING $base/$d"; done; done
```

settings 系は中身（permissions.allow / deny、hooks、enabledPlugins、各種フラグ）を Read で精読する。

### 3. 評価ルーブリック（7 メカニズム）で突き合わせる

各メカニズムについて「適切な用途で使われているか」「アンチパターンに該当しないか」を判定する。

| メカニズム | ロード時期 / コスト | 適切な用途 | 主なアンチパターン |
|---|---|---|---|
| **CLAUDE.md（ルート）** | セッション開始・常時 / 高 | ビルドコマンド・構成・チーム規範 | 300 行超の肥大化（200 行超で要注意）、手続きの常駐 |
| **CLAUDE.md（サブディレクトリ）** | オンデマンド / 低 | ディレクトリ固有規約 | — |
| **Rules（path-scoped）** | 開始 or マッチ時 / 中 | 横断規約を `paths:` で限定 | API 固有規約をアンスコープ常駐、手続きを rules 化 |
| **Skills** | 呼び出し時 / 低 | 手順・チェックリスト | 30 行超の手続きを CLAUDE.md に常駐、単発ルールを skill 化 |
| **Subagents** | 呼び出し時 / 低 | 並列・隔離タスクの定義固定化 | 見守りが要る作業の subagent 化、委託前提なのに定義不在で即席多用 |
| **Hooks** | ライフサイクル / 低 | 「必ず実行」の決定論的自動化・禁止の強制 | 「毎回 X / 絶対 Y するな」を散文依存 |
| **Output styles** | 開始・非コンパクション / 高 | 大幅なロール変更時のみ | 些細なトーン変更で既定のセキュリティ/工学指示を上書き削除 |
| **append-system-prompt** | 開始・非コンパクション / 中 | 個別指示の加法的追加 | 大量追記で遵守率低下、ガード代替 |

#### 重点チェックリスト（よくあるギャップ）

- [ ] 「毎回◯◯せよ / 絶対◯◯するな」系がモデル遵守任せ → **hooks（PreToolUse 等）化**の余地
- [ ] 30 行超の手続きが CLAUDE.md に常駐 → **skills へ移送**の余地
- [ ] `permissions.allow` に広域パターン（例 `Bash(bash -c:*)`）があり **deny を迂回**できないか
- [ ] `permissions.deny` がユーザー / プロジェクトで**不整合・表記揺れ**（`.env` パターン等）でないか
- [ ] allow / skill 名に**実体と一致しない stale エントリ**（旧名・存在しない MCP 等）が無いか（照合元: `ls` した skills/agents の実体ディレクトリ名、`claude mcp list` の登録一覧と突き合わせる）
- [ ] 実装委託や並列を前提にしながら **`agents/` 定義が不在**でないか
- [ ] path-scoped にできる規約が**アンスコープ常駐**していないか（※ user-level の `paths:` 無視バグに留意）
- [ ] カスタム output-style で**既定指示を不用意に上書き**していないか

### 4. 所見を重大度付けする

各所見に ID（例 `F-01`）と重大度を割り当てる。

- **High**: セキュリティ / 破壊リスク・即対応（例: deny 迂回経路）
- **Medium**: 効率・保守性の改善（例: 手続きの skill 化、deny 不整合）
- **Low**: 軽微・任意（例: stale エントリ整理）
- **Good**: 公式準拠・維持推奨（褒める点も必ず挙げる）

各所見に「現状」「公式基準（ルーブリックの該当行）」「推奨対応」を添える。重大度が境界で迷う場合（例: High か Medium か）は安全側（上位の重大度）に倒し、判断根拠を所見に明記する。

### 5. HTML 監査レポートを生成する

自己完結（インライン CSS）の HTML を生成する。最低限、次の構成を含める。

1. ヘッダ（対象スコープ・基準ガイド・監査日）
2. エグゼクティブサマリー＋スコアカード（High/Med/Low/Good 件数）
3. 現状インベントリ表（メカニズム × スコープ）
4. 詳細所見（ID・重大度バッジ・現状・基準・推奨）
5. 優先対応プラン（順序・重大度・工数感・関連 ID）

- 保存先: `tmp/<YYYY-MM-DD>_claude_config_audit.html`（無ければ `mkdir -p tmp`）。
- 重大度はバッジ色で視認可能にする（High=赤系 / Med=橙系 / Low=黄系 / Good=緑系）。

### 6. 提示する

生成した HTML の絶対パスを表示し、ブラウザで開く（手段は各ツールの常時ロード文書に従う。本スキルの成果物は HTML のため `open <path>` を用いる。`.md` 成果物に適用される md-open 等の規範は HTML には及ばない）。所見の要点（特に High）はチャットでも数行に要約する。

## 適用範囲・確認ルール

- 本スキルは **監査と提案まで**。設定の変更・コミット・`make deploy` 等は行わない。改善を実装する場合は承認を得てから別途進める（大規模なら ADR / モデル分業ルールに従う）。
- 対象スコープが曖昧な場合（ユーザーのみ / プロジェクトのみ / 両方）は確認する。
- 既存 ADR や設定の経緯（例: 意図的な 2 層 skills 構造、既知バグによる保留）を**否定する前に確認**する。過去に決着済みの設計を「不整合」と誤断しない。
- 推測で所見を捏造しない。実ファイルで確認できた事実のみを根拠にする。

## 関連スキル・参考

- `create-adr` — 監査結果から改善方針を意思決定記録にする場合
- `delegate-by-model` — 改善実装を委託する場合（Claude Code 限定）
- 参考: Anthropic「Steering Claude Code」 https://claude.com/ja/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
