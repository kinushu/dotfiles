# median シナリオ（典型ケース）

利用者の発話:

> さっき承認した計画書 `docs/adr/2026-06-12_0942_delegate_implementation_to_subagents_by_model.md` の実装を Codex に任せて。

期待される挙動:
- implement-by-codex スキルが発火する
- AskUserQuestion で入力計画書・サブタスク範囲・モデル・推論レベルを確認する
- 計画書本文を一時ファイルへ書き出し、`codex exec --sandbox workspace-write --json --output-last-message ... - < "$PROMPT_FILE"` を実行する
- 委託後に `git diff` と `make test` / `make deploy-dry-run` で検証する
- `--dangerously-bypass-*` や `-f` を使わない
