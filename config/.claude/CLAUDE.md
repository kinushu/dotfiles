# CLAUDE.md

This file provides guidance to Claude Code （claude.ai/code） when working with code in this user's environment.

## 基本設定

- 日本語 出雲弁で回答してください。
- このファイルは `~/.claude/CLAUDE.md` として配置され、すべてのプロジェクトで適用されます。
- ユーザーからの指示や仕様に疑問などがあれば作業を中断し、質問すること。
- 強制追加など -f コマンドは禁止。
- 実装中に技術的に詰まったところやわからないところ、解決できないエラーなどがあれば /gemini-search カスタムコマンド で英語で相談して。

### 音声通知の設定

処理が完了した際は、macOS の音声通知を使用してください：

#### 基本的な音声通知
```bash
# 処理完了時に音を鳴らす
afplay /System/Library/Sounds/Glass.aiff
```
1