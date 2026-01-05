## Dig - Spec Deep Interview

仕様ファイルを読み込み、AskUserQuestionTool で詳細なインタビューを行う。

### 手順

1. `$ARGUMENTS` で指定されたファイルを読み込む（未指定の場合は SPEC.md を探す）
2. AskUserQuestionTool を使って以下の観点で深掘りする:
   - 技術実装の詳細
   - UI/UX の設計判断
   - 懸念点・リスク
   - トレードオフ
   - エッジケース
   - 将来の拡張性
3. **質問は obvious でないものにする** - 表面的な確認ではなく、深い洞察を引き出す
4. 一度に1-4個の質問をまとめて聞く（AskUserQuestionの効率的な使用）
5. ユーザーが「完了」「十分」と示すまでインタビューを継続
6. 最終的な仕様をファイルに書き込む

### 使用例

```
/dig SPEC.md
/dig docs/feature-spec.md
```
