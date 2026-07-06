---
status: accepted
date: 2026-01-29
decision-makers:
  - kinushu
---

# Claude CLI実行中のmacOSスリープ防止

## Context and Problem Statement

Claude CLIを長時間実行中にmacOSがスリープしてしまい、処理が中断される問題がある。特にエージェントモードや複雑なタスク実行時に、思考中・処理中のタイミングでスリープが発生すると作業が無駄になる。

## Decision Drivers

* sudo権限なしで実行できること
* シンプルな設定で済むこと
* Claude CLIの動作に影響を与えないこと
* Claude CLI終了時に自動でスリープ制御が解除されること

## Considered Options

1. エイリアスで `caffeinate` コマンドをラップ
2. 専用スクリプトを `~/bin` に配置
3. `pmset disablesleep` + Claude Code hooks
4. hooks で `caffeinate` プロセスを管理

## Decision Outcome

選択: **エイリアスで `caffeinate` コマンドをラップ**

理由:
- sudo権限が不要
- `.bashrc` に一行追加するだけで設定完了
- Claude CLIが終了すれば自動でスリープ制御も解除される
- 既存のCLIの使い方を変えずに利用可能

### 実装方法

`.bashrc` または `.zshrc` に以下を追加:

```bash
alias claude='caffeinate -i claude'
```

#### caffeinate オプション

| オプション | 効果 |
|-----------|------|
| `-i` | システムアイドルスリープを防止 |
| `-d` | ディスプレイスリープも防止 |
| `-s` | AC電源接続時のみスリープ防止 |

ディスプレイもスリープさせたくない場合:

```bash
alias claude='caffeinate -di claude'
```

## Consequences

### Good

* 設定が非常にシンプル（一行）
* sudo不要で安全
* Claude CLI終了時に自動解除されるため、スリープ制御の解除忘れがない
* 既存の `claude` コマンドをそのまま使える

### Bad

* エイリアスを設定したシェル環境でのみ有効
* `caffeinate` を使わずに直接 `claude` を実行したい場合は `\claude` またはフルパス指定が必要

## 却下した選択肢の理由

### 専用スクリプト

エイリアスで十分達成できるため、スクリプトファイルを管理する必要がない。

### pmset disablesleep + hooks

- `pmset disablesleep` はsudo権限が必要
- hooks内でsudoを使うのはセキュリティ上推奨されない
- 解除忘れのリスクがある

### hooks で caffeinate を管理

- hooks は各ツール呼び出しごとに発火するため、開始/終了の制御が複雑
- PIDファイル管理などの追加ロジックが必要
- オーバーエンジニアリング

## More Information

- macOS `caffeinate` man page: `man caffeinate`
- Claude Code hooks: `~/.claude/settings.json` の `hooks` セクション
