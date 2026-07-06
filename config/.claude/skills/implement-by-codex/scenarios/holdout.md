# holdout シナリオ（誤発火検証用・最終回まで開かない）

以下はいずれも implement-by-codex を**発火させるべきでない**ケース。trigger precision を測る。

1. > この差分を Codex でレビューして。
   → review-by-codex を選ぶべき。implement-by-codex は誤発火。

2. > README の typo を1箇所直して。
   → 小規模修正。現モデルが直接実装。実装委託スキルは不要。

3. > 計画をレビューしてほしい。
   → review-by-codex。

4. > このプランを Sonnet サブエージェントで実装して。
   → Codex 指定がない。Agent(model=sonnet) による委託で、implement-by-codex（Codex 専用）ではない。

正発火させるべきケース（対照）:
5. > 確定した計画書をもとに Codex に実装を委託して。 → implement-by-codex 発火が正しい。
