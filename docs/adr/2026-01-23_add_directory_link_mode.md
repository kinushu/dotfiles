---
status: proposed
date: 2026-01-23
decision-makers:
  - kinushu
---

# add_directory_link_mode

## Context and Problem Statement

`make deploy` で `config/` 以下をホームディレクトリに展開する際、現在はすべてのファイルを個別にシンボリックリンクしている。しかし、特定のフォルダ（例: `.claude/skills/`）については、フォルダ内のファイルが頻繁に追加・削除されるため、フォルダごとシンボリックリンクを作成したい。

現在の動作:
```
~/.claude/skills/skill1.md -> config/.claude/skills/skill1.md
~/.claude/skills/skill2.md -> config/.claude/skills/skill2.md
```

望ましい動作（指定フォルダの場合）:
```
~/.claude/skills/ -> config/.claude/skills/
```

## Decision Drivers

* フォルダ内のファイル追加・削除時に再デプロイが不要になる
* 既存のファイル単位リンクの動作は維持する必要がある
* 設定は明示的で分かりやすいものにしたい
* Mitamae の cookbook として実装する

## Considered Options

1. 設定ファイル（`directory_links.txt`）でフォルダパスを指定
2. `node.json` にフォルダリストを追加
3. cookbook 内にハードコーディング

## Decision Outcome

選択: Option 2 - `node.json` にフォルダリストを追加

理由: Mitamae の設定として一元管理でき、他のノード変数と整合性が取れる。また、環境ごとに異なる設定が必要になった場合も対応しやすい。

### 実装方針

`node.json` に以下の形式で設定を追加:

```json
{
  "directory_links": [
    ".claude/skills"
  ]
}
```

`cookbooks/dotfiles/default.rb` で:
1. `node[:directory_links]` に指定されたフォルダはフォルダ単位でリンク
2. それ以外は従来通りファイル単位でリンク
3. 指定フォルダ配下のファイルはスキャン対象から除外

## Consequences

### Good

* 指定フォルダ内のファイル変更時に再デプロイ不要
* 新規ファイル追加が即座に反映される

### Bad

* フォルダ単位リンクの場合、個別ファイルの除外ができない
* 設定の複雑さが増す

## More Information

関連ファイル:
- `cookbooks/dotfiles/default.rb`: 現在のデプロイロジック
- `etc/deploy.sh`: デプロイスクリプト
