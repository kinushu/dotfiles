# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read @AGENTS.md

## スキル作成時の配置場所

このdotfilesプロジェクトでスキルを作成する際は、以下の3つから選択させること:

1. **ホームフォルダ（`~/.agents/skills/`）**: 全プロジェクトで共通利用、バージョン管理なし
2. **現プロジェクト（`.claude/skills/`）**: dotfilesプロジェクト専用
3. **dotfiles管理（`config/.agents/skills/`）**: 全プロジェクトで共通利用、dotfilesでバージョン管理される（ホームにシンボリンク展開）
