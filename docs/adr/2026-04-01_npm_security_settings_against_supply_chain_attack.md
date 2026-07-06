---
status: accepted
date: 2026-04-01
decision-makers:
  - kinushu
---

# npmサプライチェーン攻撃対策としてのパッケージマネージャセキュリティ設定導入

## Context and Problem Statement

2026年3月31日、npmパッケージ **axios** のメンテナーアカウントが侵害され、悪意あるバージョン（`1.14.1`, `0.30.4`）が約2〜3時間公開された。攻撃者は `plain-crypto-js` という新規パッケージを依存関係に追加し、`postinstall` スクリプト経由でRAT（リモートアクセスツール）をmacOS/Windows/Linuxにインストールする手法を取った。

本dotfilesプロジェクトでは現在axiosは未使用だが、以下の懸念がある:

- `.npmrc` が未配置であり、npmのセキュリティ設定が一切行われていない
- mise経由でグローバルnpmパッケージ（`@google/gemini-cli`, `@openai/codex`）をインストールしている
- `tmp/sandbox_boilerplate/` でnpmプロジェクトのテンプレートを管理している
- 今後、他のnpmパッケージが同様の攻撃を受ける可能性がある

dotfilesとして全環境に適用される `.npmrc` を管理し、サプライチェーン攻撃のリスクを軽減したい。

## Decision Drivers

* axiosの事例で `postinstall` スクリプトによるRAT配布が実証された
* `ignore-scripts` と `min-release-age` の2設定が各記事で共通して推奨されている
* dotfilesで `.npmrc` を管理すれば全環境に一貫して適用できる
* ネイティブモジュール（node-gyp等）を使うパッケージでは `ignore-scripts` が影響する可能性がある

## Considered Options

### Option 1: `.npmrc` に `ignore-scripts=true` + `min-release-age=7` を設定

`config/.npmrc` を作成し、dotfiles経由で `~/.npmrc` にデプロイする。

```ini
# サプライチェーン攻撃対策
# postinstall等のインストールスクリプト実行を無効化
ignore-scripts=true

# 公開から7日未満のパッケージ/バージョンのインストールをブロック
# 参考: 直近10件のサプライチェーン攻撃のうち8件は1週間以内に検知・削除された
min-release-age=7
```

**注意:** `min-release-age` の値は日数を数値で指定する（npm v11.10.0で追加）。`7d` のような文字列は不正値となりエラーになる。

**メリット:**
- `postinstall` スクリプトによる攻撃を根本的にブロック
- 公開直後の危険なバージョンを時間差で回避
- dotfiles管理で全環境に一貫適用

**デメリット:**
- ネイティブモジュール（`bcrypt`, `sharp`, `sqlite3`等）が `npm rebuild <pkg>` を別途必要とする
- `min-release-age` により、緊急のセキュリティパッチ適用が遅れる可能性がある
- 一部のパッケージで `postinstall` に依存するセットアップが動作しない

### Option 2: `ignore-scripts=true` のみ設定

`min-release-age` は設定せず、スクリプト実行のみ無効化する。

**メリット:**
- 最も危険な攻撃ベクトル（postinstallスクリプト）をブロック
- 新しいバージョンの即時利用が可能

**デメリット:**
- スクリプトを使わない悪意あるコード（require時に実行等）は防げない

### Option 3: 現状維持（設定なし）

**メリット:**
- 設定変更による副作用なし

**デメリット:**
- サプライチェーン攻撃に対して無防備

## Decision Outcome

選択: **Option 1** — `.npmrc` に `ignore-scripts=true` + `min-release-age=7` を設定

### 理由

- 本プロジェクトはdotfiles（開発環境設定）であり、ネイティブモジュールのビルドが必要なケースは限定的
- 個人開発環境では最新バージョンの即時利用より安全性を優先すべき
- ネイティブモジュールが必要な場合は `npm rebuild <パッケージ名>` で個別対応可能
- 緊急パッチが必要な場合は `--ignore-scripts=false` や `npm install --min-release-age=0` で一時的にオーバーライド可能

## Implementation Plan

1. `config/.npmrc` を作成（`ignore-scripts=true`, `min-release-age=7`）
2. `config/.config/uv/uv.toml` を作成（`exclude-newer = "7 days"`）
3. Mitamaeの dotfiles cookbook で `~/.npmrc` へ自動シンボリンク（cookbookは `config/` を動的スキャンするため変更不要）
4. `~/.config/uv/uv.toml` も同様に自動デプロイ
5. `make test` にセキュリティ設定の存在確認テストを追加検討

## 現プロジェクトのaxios検証結果

| 項目 | 結果 |
|------|------|
| axiosへの参照 | **なし** — リポジトリ内に一切存在しない |
| `plain-crypto-js` の参照 | **なし** |
| npm依存パッケージ | `prettier@^3.6.2`（sandbox_boilerplate のみ） |
| グローバルnpmパッケージ | `@google/gemini-cli`, `@openai/codex`（mise経由） |
| `.npmrc` の存在 | **なし** — 未構成 |
| `package-lock.json` | **なし**（`node_modules/.package-lock.json` のみ） |

**結論: 本プロジェクトはaxiosサプライチェーン攻撃の影響を受けていない。**

## macOS全体での感染検査（2026-04-01実施）

### 検査方法

axiosサプライチェーン攻撃の痕跡を以下6項目で網羅的に検査した。

#### 1. 悪意あるパッケージ `plain-crypto-js` の検索

```bash
find "$HOME" -type d -name "plain-crypto-js" -path "*/node_modules/*" 2>/dev/null
```

#### 2. グローバルnpmパッケージの確認

```bash
npm ls -g axios 2>/dev/null
```

#### 3. 全node_modules内のaxiosバージョン確認

```bash
find "$HOME" -path "*/node_modules/axios/package.json" 2>/dev/null
# 各package.jsonからバージョンを読み取り、1.14.1 / 0.30.4 に該当するか確認
```

#### 4. mise管理下のグローバルパッケージ確認

```bash
ls -la $(mise where node 2>/dev/null)/lib/node_modules/ 2>/dev/null
```

#### 5. RATバックドアファイルの検出

攻撃が成功した場合にmacOSに配置されるバイナリの存在確認:

```bash
ls -la /Library/Caches/com.apple.act.mond 2>/dev/null
ls -la ~/Library/Caches/com.apple.act.mond 2>/dev/null
```

#### 6. lockfileでの `plain-crypto-js` 参照検索

```bash
grep -r "plain-crypto-js" "$HOME" \
  --include="package-lock.json" \
  --include="yarn.lock" \
  --include="pnpm-lock.yaml" 2>/dev/null
```

### 検査結果

| # | 検査項目 | 結果 |
|---|---------|------|
| 1 | `plain-crypto-js` パッケージ | **検出なし** |
| 2 | グローバルnpmのaxios | **インストールなし** |
| 3 | ローカルnode_modules内のaxios（31件検出） | **全て安全なバージョン** — 下記詳細参照 |
| 4 | mise管理下のグローバルパッケージ | **axiosなし**（lib/node_modules は空） |
| 5 | RATバックドアファイル (`com.apple.act.mond`) | **検出なし** |
| 6 | lockfile内の `plain-crypto-js` 参照 | **検出なし** |

#### ローカルnode_modules内 axiosバージョン内訳

| バージョン | 件数 | 判定 |
|-----------|------|------|
| 0.18.0 | 1 | 安全 |
| 0.21.1 | 1 | 安全 |
| 0.21.2 | 3 | 安全 |
| 0.21.4 | 15 | 安全 |
| 0.26.1 | 1 | 安全 |
| 1.6.7 | 3 | 安全 |
| 1.6.8 | 1 | 安全 |
| 1.8.4 | 6 | 安全 |

悪意あるバージョン `1.14.1` および `0.30.4` は**いずれも検出されなかった**。

### 総合判定

**このマシンはaxiosサプライチェーン攻撃の影響を受けていない。**

## uv (Python) への同様の対策

npm以外のパッケージマネージャにも同様の防御を適用する。Pythonのパッケージマネージャ **uv** には `exclude-newer` 設定があり、指定期間より新しいパッケージのインストールをブロックできる。

`config/.config/uv/uv.toml`:
```toml
# サプライチェーン攻撃対策
# 公開から7日未満のパッケージをインストールしない
exclude-newer = "7 days"
```

これにより、npm (`min-release-age`) と uv (`exclude-newer`) の両方で、公開直後のパッケージを一定期間ブロックする多層防御が実現される。

## References

- [サプライチェーン攻撃が怖い話 - Zenn](https://zenn.dev/dely_jp/articles/supply-chain-kowai)
- [axiosサプライチェーン攻撃の詳細解説 - note](https://note.com/fujikou/n/nfb53c90ee2d9)
- [axios侵害の技術分析 - Flatt Security Blog](https://blog.flatt.tech/entry/axios_compromise)
