---
name: audit-claude-config
description: Claude Code の設定ファイル類（ユーザースコープ / プロジェクトスコープ）を公式 Steering ガイドの 7 メカニズム観点で監査し、重大度付きの所見と HTML レポートを作成する。設定監査・config audit・steering 準拠チェック・設定の改善提案、と言われたときに使用。
---

# audit-claude-config（Claude Code 拡張版）

## 共通手順

このスキルの共通手順は以下のファイルに定義されている。
**Read ツールで必ず読み込み、その指示に従ってから以下の拡張手順を実行すること。**
**読み込みに失敗した場合は、スキルの実行を中断しユーザーに報告すること。**

共通スキル定義: `~/.agents/skills/audit-claude-config/SKILL.md`

## Claude Code 拡張

### インベントリ収集（Claude Code 固有）

- ユーザースコープは `~/.claude/`、共通は `~/.agents/`、プロジェクトは `./.claude/` を対象とする。
- dotfiles でシンボリンク管理されている場合、`~/.claude/settings.json` 等の実体（例: `config/.claude/settings.json`）を辿って精読する。
- 評価ルーブリックの鮮度を上げたい場合は、本文記載の Steering ガイド URL を **WebFetch** で取得して差分を取り込む（失敗時はルーブリックのみで続行）。
- スコープが曖昧なら **AskUserQuestion** で対象（ユーザー / プロジェクト / 両方）を確認する。
- ルーブリック突き合わせ・重大度判定は判断負荷が高いため、高知能機（alias: `opus`）での実行を推奨する（強制はしない）。

### HTML レポートの提示

- 生成した HTML（`tmp/<YYYY-MM-DD>_claude_config_audit.html`）は、Bash ツールで `open "{絶対パス}"` を実行してブラウザで開く。
- HTML は最終成果物のため、提示時に 1 回だけ開く（小刻みな生成途中では開かない）。
- 改善実装に進む場合は、本スキルでは行わず承認を得てから別フロー（必要なら `create-adr` →（Claude Code 限定）`delegate-by-model`）へ繋ぐ。
