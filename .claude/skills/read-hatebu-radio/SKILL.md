---
name: read-hatebu-radio
description: はてブclippingsの最新記事をニュース原稿風にまとめて読み上げる。ラジオ、読み上げ、hatebu radio、と言われたときに使用。
---

# はてブラジオ読み上げスキル

Obsidianのclippingsディレクトリから最新の未読記事をニュース原稿風にまとめて読み上げる。

## 設定

### Clippingsディレクトリの解決順序

以下の順序でClippingsディレクトリを自動解決する（AskUserQuestionは不要）:

0. **ローカル設定解決**: 環境依存の Vault 名を、リポジトリ root の `config.local.yml`（scheduled_tasks と共用。テンプレートは `config.local.yml.example`）から取得する。
   - 次の順序で `config.local.yml` を探し、最初に見つかったものを使う:
     1. 環境変数 `$DOTFILES_LOCAL_CONFIG`（設定かつファイルが存在する場合）
     2. リポジトリ root の `config.local.yml`
   - 見つかれば `hatebu.obsidian_vault_name` を取得し、直下の既知パス探索の先頭（`~/Documents/Obsidian/<Vault名>/Clippings`）に使う。
   - 見つからない／`hatebu.obsidian_vault_name` が未設定の場合は、以降の従来フォールバック（自動検出 → 既知パス → AskUserQuestion）へ劣化する。
1. `bin/hatebu-to-md` のデフォルト出力先と同じObsidian Vault内の `Clippings/` を探す
2. 以下の既知パスを順に探索:
   - `~/Documents/Obsidian/<Vault名>/Clippings`
   - `~/Documents/Obsidian/clippings`
3. いずれも見つからない場合のみAskUserQuestionで確認

### ラジオ履歴ファイル

Clippingsディレクトリ内の `history.yaml` にラジオ化済みフラグを管理する。
`bin/hatebu-to-md` が生成する既存の `history.yaml` に `radio_at` フィールドを追加する形式。

```yaml
entries:
- url: https://example.com/article
  status: success
  # ... hatebu-to-md が管理するフィールド ...
  radio_at: '2026-02-06T15:08:00+0900'  # ← ラジオスキルが追加するフィールド
```

`history.yaml` が存在しない場合（Obsidian Web Clipperなど別経路でClippingsに保存された記事）は、
Clippingsディレクトリ内に `radio_history.yaml` を別途作成して管理する。

## 実行手順

### 1. パラメータ確認

AskUserQuestionで確認するのは **取得する記事数のみ**（デフォルト: 5）。

Clippingsディレクトリは自動解決する。

### 2. 最新ファイル取得（未ラジオ化のもの）

```
1. Bashで `ls -1t {clippings_dir}/*.md | head -N` で更新日時の新しい順にファイル一覧を取得
2. radio_history.yaml を読み込み、ラジオ化済みファイルを除外
3. 残ったファイルからn件を選択
4. n件に満たない場合はその件数で実行（0件なら「新しい記事はありません」と報告して終了）
```

**重要**: Globツールは更新日時順の保証がないため、Bashの `ls -1t` を使用する。
ただし `history.yaml` は対象外とする。

### 3. コンテンツ読み取り

各ファイルについて:
1. Readツールでファイル内容を取得
2. frontmatter（`---`で囲まれた部分）からtitle、sourceを抽出
3. frontmatter以降の本文を取得

### 4. ニュース原稿作成

各記事を以下の形式でニュース原稿にまとめる:

```
## {記事タイトル}

{記事の要点を簡潔にまとめた原稿文}

---
```

原稿作成のポイント:
- ニュースキャスターが読み上げるような口調
- 専門用語は簡潔に説明を添える
- 「〜とのことです」「〜が話題になっています」などのニュース調表現
- 通常の記事: 約300文字（読み上げ約1分）
- 長い・重要な記事: 最大約900文字（読み上げ約3分）
- **URLは絶対に本文中に含めない**（読み上げの邪魔になるため）
- マークダウン記号（`#`, `---`, `*`, `>`等）も読み上げに不適切なので本文中では使わない

### 5. ファイル出力

2つのファイルを出力する:

#### 保存用ファイル（参照元URL付き）
出力先: `tmp/%Y-%m-%d_%H%M_hatebu_radio_matome.md`

```markdown
# はてブラジオまとめ

作成日時: YYYY-MM-DD HH:MM

---

## {記事1タイトル}

{原稿文}

---

（以下続く）

---

以上、本日のはてブラジオでした。

## 参照元一覧

1. {記事1タイトル}: {source URL}
2. {記事2タイトル}: {source URL}
（以下続く）
```

#### 読み上げ用ファイル（URL・マークダウン記号なし）
出力先: `/tmp/hatebu_radio_say.txt`

読み上げ専用のプレーンテキスト。以下を除外:
- すべてのURL
- マークダウン記号（`#`, `---`, `*`, `>`, `` ` `` 等）
- 「参照元一覧」セクション全体

```text
はてブラジオまとめ

作成日時 YYYY年MM月DD日

{記事1タイトル}

{原稿文}

{記事2タイトル}

{原稿文}

（以下続く）

以上、本日のはてブラジオでした。
```

### 6. まとめファイルをClippingsへ移動

保存用ファイルをObsidian Clippingsディレクトリにコピーする。

```bash
cp tmp/%Y-%m-%d_%H%M_hatebu_radio_matome.md {clippings_dir}/
```

- `tmp/` のファイルは作業用としてそのまま残す
- Clippingsフォルダにコピーすることで、Obsidianからまとめ記事を参照可能になる

### 7. ラジオ履歴の更新

処理した各記事のsource URLについて、`radio_history.yaml` に `radio_at` タイムスタンプを記録する。

```yaml
# radio_history.yaml
entries:
- url: https://example.com/article1
  radio_at: '2026-02-06T15:08:00+0900'
  title: 記事タイトル1
- url: https://example.com/article2
  radio_at: '2026-02-06T15:08:00+0900'
  title: 記事タイトル2
```

この履歴は次回実行時に「ラジオ化済み」の判定に使用する。
判定はsource URLベースで行う（ファイル名ではなく）。

### 8. 読み上げ実行

```bash
say -v Kyoko -r 180 -f /tmp/hatebu_radio_say.txt
```

- 音声: Kyoko（日本語女性）
- 速度: 180（やや速め、ニュース調）
- 読み上げ用ファイル（URLなし）を使用

## 重要なルール

1. **Clippingsディレクトリは自動解決**: 既知パスから探索し、見つからない場合のみ質問
2. **記事数のみ確認**: AskUserQuestionで聞くのは取得件数のみ（デフォルト5件）
3. **ラジオ化済みをスキップ**: radio_history.yaml で管理し、同じ記事を再処理しない
4. **frontmatterをスキップ**: 読み上げ対象は本文のみ
5. **原稿は簡潔に**: 各記事300文字程度、専門用語は言い換え
6. **URLは読み上げない**: 読み上げ用ファイルにURLを含めない
7. **読み上げ前に確認**: ファイル保存後、読み上げ実行前にユーザーに確認（スキップ可能にする）
8. **ファイル一覧取得はBash**: `ls -1t` で更新日時順を保証する
