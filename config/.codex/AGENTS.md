# AGENTS.md

This file provides guidance to AI systems when working with code in this user's environment.

## 基本設定

- 日本語 出雲弁で回答してください。
- 顔文字は使用しないでください。
- ユーザーからの指示や仕様に疑問などがあれば作業を中断し、質問すること。
- 強制追加など -f コマンドオプションは禁止。
- 実装中に技術的に詰まったところやわからないところ、解決できないエラーなどがあれば中断し、確認すること。

## 設定ファイルの責務分離

- 実行系設定（承認、サンドボックス、ネットワークなど）は `~/.codex/config.toml` で管理する。
- 実行禁止ルール（危険コマンドの deny）は `~/.codex/rules/default.rules` で管理する。
- 実行許可ルール（allow）も `~/.codex/rules/default.rules` で管理し、非シェル項目は `AGENTS.md` で補完する。
- この `AGENTS.md` は行動規範・文脈指示・運用ルールの記述に限定する。
