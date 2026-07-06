---
status: proposed
date: 2026-04-02
decision-makers:
  - Shuhei Kinukawa
---

# generate_local_codex_config_from_template_on_deploy

## Context and Problem Statement

このリポジトリでは Codex の設定を `config/.codex/` 配下で管理している。  
しかし `config/.codex/config.toml` のようなローカル状態を持つファイルをそのまま `~/` 配下へシンボリックリンクすると、Codex が実行中に追記する trusted projects などのローカル状態がそのまま Git 差分として現れる。

特に `[projects."..."]` 配下の `trust_level` は、利用マシンの絶対パスやユーザーごとの信頼状態に依存する。  
この情報をリポジトリ管理下に置くと、共有すべき設定とローカル状態が混在し、以下の問題が起きる。

* Codex 起動や利用のたびに不要な差分が発生する
* 別マシンや別ユーザーでは再利用しにくい絶対パスが混入する
* リポジトリの方針である「実行系設定は `~/.codex/config.toml` で管理する」と整合しにくい

このため、共有したい初期設定と、Codex が更新するローカル状態をどのように分離するか決める必要がある。

## Decision Drivers

* Codex の trusted projects による Git 差分を防ぎたい
* `make deploy` によるセットアップ体験は維持したい
* 共有すべき初期設定はテンプレートとして保持したい
* 既存の `AGENTS.md` にある責務分離方針と整合させたい
* 再実行してもローカルの trust 状態を壊さない idempotent な挙動にしたい

## Considered Options

1. `config/.codex/config.toml` のシンボリックリンク運用を継続する
2. `config/.codex/config.toml` を Git 管理したまま、各環境で `skip-worktree` などを使って差分を隠す
3. `.example` テンプレート群を管理し、`make deploy` 時に対応するローカル実ファイルが未存在のときだけコピー生成する
4. `config.toml` 自体はローカル専用とし、テンプレートもリポジトリに置かない

## Decision Outcome

選択: Option 3

理由: 共有したい初期設定をテンプレートとしてリポジトリ管理しつつ、Codex が更新する `~/.codex/config.toml` のようなローカル状態ファイルはローカル実ファイルとして分離できるため。  
これにより、`trust_level` などのローカル状態が Git 差分へ混入する問題を避けながら、`make deploy` による初期セットアップも維持できる。

また、`make deploy` 時の挙動を「未存在時のみコピー」に限定すれば、Codex が後から追記した trusted projects を上書きせず、再実行時の安全性も確保できる。  
一方で、テンプレート更新を既存ローカルファイルへ自動反映しない点は残るが、ローカル状態保護を優先する。

## Consequences

### Good

* `trust_level` などのローカル状態が Git 管理から分離される
* `config.toml` の初期値は引き続きテンプレートとして共有できる
* `make deploy` だけで初回セットアップできる
* 再 deploy 時に既存の `~/.codex/config.toml` を上書きせず、Codex が追記した内容を保持できる
* 将来的に他のローカル専用設定ファイルにも同じ仕組みを流用できる

### Bad

* テンプレート更新が既存ローカルファイルへ自動反映されない
* `~/.codex/config.toml` がテンプレートから乖離しても即座には気づきにくい
* 実装として「コピー生成対象」を symlink デプロイ対象から除外し、別途テンプレート展開する追加ロジックが必要になる

## Implementation Notes

想定する実装方針:

* `node.json` に `template_copy_targets` を追加し、「テンプレートからローカル実ファイルを生成する対象」を定義する
* 例として `config/.codex/config.toml.example` -> `~/.codex/config.toml` をそのマッピングで表現する
* 通常の symlink デプロイ対象から `.example` テンプレート自体を除外する
* `make deploy` の内部処理で、定義された対象についてローカル実ファイルが未存在の場合のみテンプレートからコピーする
* 既存ファイルがある場合は何もしない

`node.json` の想定例:

```json
{
  "platform": "darwin",
  "arch": "arm64",
  "directory_links": [
    ".agents",
    ".claude/commands",
    ".claude/skills",
    "bin"
  ],
  "alias_links": {},
  "template_copy_targets": [
    {
      "source": ".codex/config.toml.example",
      "destination": ".codex/config.toml"
    }
  ]
}
```

`template_copy_targets` の仕様:

* `source`: `config/` ディレクトリからの相対パス
* `destination`: `HOME` ディレクトリからの相対パス
* deploy 時は `destination` が未存在の場合のみコピーする
* 親ディレクトリが無ければ作成する
* 既存ファイル、既存シンボリックリンク、既存ディレクトリがある場合は上書きしない
* 初版では変数展開、動的レンダリング、権限変更は扱わない

この設計により、`directory_links` は「ディレクトリ単位リンク」、`alias_links` は「HOME 内の別名リンク」、`template_copy_targets` は「初回のみローカル実ファイル生成」という責務分離になる。

疑似コード:

```text
for each template_mapping in template_copy_targets
  if destination does not exist
    create parent directory if needed
    copy source template to destination
  end
end
```

## Definition of Done

* ローカル生成対象ファイルを宣言するパラメータが導入されている
* そのパラメータは `node.json` の `template_copy_targets` として定義されている
* `config/.codex/config.toml.example` -> `~/.codex/config.toml` のマッピングがそのパラメータで表現されている
* `make deploy` 実行時に対象ファイルが未存在なら生成される
* `make deploy` を再実行しても、既存のローカル実ファイルは上書きされない
* trusted projects の追記が Git 差分として現れない運用に移行できる
* 必要に応じて README や運用文書にテンプレート運用が記載されている

## More Information

関連ファイル:

* `config/.codex/AGENTS.md`
* `cookbooks/dotfiles/default.rb`
* `etc/deploy.sh`
