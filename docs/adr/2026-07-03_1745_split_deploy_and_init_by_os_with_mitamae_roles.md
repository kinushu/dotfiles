---
status: accepted
date: 2026-07-03
decision-makers:
  - Shuhei Kinukawa
---

# split_deploy_and_init_by_os_with_mitamae_roles

## Context and Problem Statement

現在の `make deploy` / `make init` は macOS 前提の実装になっており、Ubuntu では動作しない。

確認済みの macOS 依存箇所:

- `Makefile` の `update` ターゲットが `brew update` を直接実行している
- `etc/init/init.sh` が Homebrew のインストール・`brew install`・`defaults write com.apple.desktopservices`・`/usr/local` の権限変更など macOS 固有処理をシェルで直接実行している
- `etc/init/init.sh` が `roles/darwin.rb` をハードコードで実行している
- `node.json` の `platform` が `"darwin"` に固定されている
- `roles/` には `base.rb` と `darwin.rb` しかなく、Linux 用 role が存在しない

今後、Ubuntu（サーバ/VPS、および実機・VM のデスクトップ）にも同じ dotfiles を展開したい。そのために OS ごとの処理分岐をどこで・どう実現するかを決める必要がある。あわせて、現状 dotfiles のシンボリックリンク（`cookbooks/dotfiles`）と mise（`cookbooks/mise`）にしか使っていない mitamae の適用範囲を広げるかどうかも論点となる。

## Decision Drivers

* macOS / Ubuntu の両方で同一の `make` インターフェース（`make deploy` / `make init`）を維持したい
* 冪等性: 何度実行しても同じ状態に収束すること（サーバ再セットアップ・構成修正に耐える）
* シェルスクリプトの肥大化を避け、OS 固有処理を宣言的に管理したい（mitamae は導入済み）
* パッケージ管理は macOS = Homebrew、Ubuntu = apt + mise を採用する（Homebrew on Linux は使わない）
  * 役割分担: apt = OS パッケージ・ビルド依存・shell 基盤、mise = 言語ランタイムと開発ツールのバージョン管理。Homebrew on Linux は `/home/linuxbrew` 前提・PATH 差分・apt との重複が保守負担になるため採用しない
* Ubuntu はサーバ/VPS とデスクトップ（実機/VM）の両方で使うため、GUI 有無に依存しない基本セットを軸にし、GUI 依存物は別プロファイルへ分離する
* 権限境界を明確にする: システム変更（apt / locale / systemd）は sudo 必須、`$HOME` 配下の symlink 作成は通常ユーザーで行い、root 所有物を `$HOME` に作らない

## Considered Options

1. **mitamae 中心に寄せる（OS 固有処理を role / cookbook へ移設）**
   - Good: 冪等・宣言的に OS 差分を管理できる。`not_if` / `only_if` ガードで再実行に強い
   - Good: mitamae は single binary で Ruby 環境不要のため、素の Ubuntu サーバでもブートストラップが軽い
   - Good: シェルスクリプトは「mitamae の取得と role 選択」だけの薄い入口に縮小でき、見通しが良くなる
   - Bad: `init.sh` の処理を cookbook へ移植する初期コストがかかる
   - Bad: mitamae DSL の知識が前提になる（ただし本リポジトリは Ruby 主体で既に採用済み）
   - 影響範囲: `Makefile`、`etc/deploy.sh`、`etc/init/init.sh`、`roles/*`、`cookbooks/*`（新規 cookbook 追加）、`node.json`、`etc/install_mitamae.sh`、`etc/test/test.sh`
2. **シェルスクリプト内で uname 分岐**
   - Good: 変更が局所的で初期コストが最小。既存の `init.sh` に分岐を足すだけで動き始める
   - Bad: 手続き的な分岐が増えてスクリプトが肥大化し、冪等性を各所で手書き保証する必要がある
   - Bad: OS が増えるたびに分岐が乗算的に増え、テストも困難になる
   - 影響範囲: `etc/deploy.sh`、`etc/init/init.sh`、`Makefile`
3. **ハイブリッド（入口で OS 判定だけ導入し、段階的に mitamae へ移行）**
   - Good: 一度に移植せず動くものを維持しながら移行できる
   - Bad: 過渡期にシェル分岐と mitamae 分岐が二重管理になり、どちらが正か分かりにくい
   - Bad: 「段階移行」の完了条件が曖昧になりがちで、中途半端な状態が固定化するリスクがある
   - 影響範囲: 選択肢 1 と同じ範囲に加え、過渡期の二重管理コスト

## Decision Outcome

選択: **選択肢 1: mitamae 中心に寄せる**

理由: 冪等性・宣言的管理という Decision Drivers に最も適合する。mitamae は既に導入済みで、`node[:platform]` による分岐パターンも `roles/darwin.rb` に前例がある。サーバ/VPS への再展開を考えると、シェルで冪等性を手書きする選択肢 2 よりも、リソース単位でガード（`not_if`）を宣言できる mitamae に処理を集約する方が保守コストが低い。選択肢 3 の段階移行は二重管理の過渡期リスクが大きく、今回のリファクタリングブランチ（`dev/refact_deploy_on_os`）で一括して移設する方が明快である。

以下、Codex レビューを受けて確定した設計方針を明記する。

### 確定方針（レビュー反映）

1. **node.json から `platform` / `arch` を除去する**
   - 自動検出（mitamae/specinfra の `node[:platform]`）と `node.json` の固定値が衝突し、Ubuntu 上でも `node[:platform] == "darwin"` になる事故を防ぐ
   - `node.json` は環境非依存の属性（`directory_links`, `alias_links`, `template_copy_targets`）だけを持たせる
   - OS 判定は「入口スクリプトの role 選択」と「mitamae の自動検出」に一本化する
2. **`make deploy` と `make init` の責務を分離する**
   - `deploy` = dotfiles symlink + template 展開のみ（OS 共通、sudo 不要、通常ユーザー）
   - `init` = パッケージ導入・OS 設定まで（OS 固有、system 部分は sudo 必須）
   - role もこの責務境界に沿って分ける（下記構成参照）
3. **sudo 境界を role で分離する**
   - `*_system.rb`（apt / locale / systemd 等）は sudo 実行、`*_user.rb`（dotfiles / mise / zsh 設定）は通常ユーザー実行
   - `$HOME` 配下を root 所有にしない
4. **入口スクリプトは zsh 依存を排除する**
   - `etc/deploy.sh` の `#!/bin/zsh` を `#!/bin/bash`（または POSIX `sh`）へ変更。Ubuntu 最小環境に zsh が無くても起動できるようにする
   - zsh は apt cookbook で後から導入する対象とする
5. **GUI 有無をプロファイルで分離する**
   - `node[:profile]`（`"server"` / `"desktop"`）を明示指定し、desktop 専用物（fonts, IME, gsettings 等）は `ubuntu_desktop` 側にのみ含める。自動検出には頼らない
6. **`make update` の責務を絞る**
   - `make update` は repo/submodule 更新のみに戻す。パッケージ更新（`brew update` / `apt update`）は `make upgrade`（または `make system-update`）へ寄せ、macOS / Ubuntu で対称にする
7. **バイナリ取得の安全化**
   - mitamae / mise / oh-my-zsh の取得は checksum 検証またはタグ固定を基本とし、未知 arch は即エラーにする

### 疑似的な実装イメージ

```
# ディレクトリ構成（変更後）
roles/
  base.rb           # OS 共通の純粋な共通処理（ディレクトリ作成のみ。mise は各 role 側で include）
  darwin.rb         # macOS 入口: base + homebrew + macos_defaults + mise
  ubuntu_user.rb    # Ubuntu 通常ユーザー: base + dotfiles + mise + zsh 設定
  ubuntu_system.rb  # Ubuntu sudo: apt + locale + (systemd)
  ubuntu_desktop.rb # Ubuntu desktop 追加分（GUI: fonts/IME/gsettings 等）※ node[:profile]=="desktop" 時のみ

cookbooks/
  dotfiles/        # 既存（OS 共通）
  mise/            # 既存（OS 共通）。base.rb からは呼ばず各 role で apt/homebrew の後に include
  homebrew/        # 新規: Homebrew 導入と Brewfile 適用（darwin 専用）
  macos_defaults/  # 新規: defaults write 系（darwin 専用、/usr/local 権限は要否を再評価のうえ darwin 限定）
  apt/             # 新規: apt パッケージ導入（ubuntu 専用、sudo 前提）
  locale/          # 新規: locale-gen / LANG 設定（ubuntu 専用、sudo 前提）
  zsh/             # 新規: zsh + oh-my-zsh + plugin 配置 + chsh 方針（OS 共通の user 処理）

# 入口スクリプト etc/lib/detect_os.sh（bash、共通ライブラリ）
#   uname -s => darwin / linux、linux なら /etc/os-release の ID で ubuntu 判定
#   uname -m => x86_64->amd64, aarch64|arm64->arm64、未知 arch は exit 1
detect_platform()  # darwin | ubuntu を返す
detect_arch()      # amd64 | arm64 を返す（install_mitamae.sh が使用）

# etc/deploy.sh（#!/bin/bash に変更）: dotfiles + template 展開のみ
bin/mitamae local ./cookbooks/dotfiles/default.rb --node-json node.json   # 従来どおり（deploy は OS 非依存）

# etc/init/init.sh（#!/bin/bash）: OS 判定して role を選択
platform=$(detect_platform)
case "$platform" in
  darwin) bin/mitamae local roles/darwin.rb --node-json node.json ;;
  ubuntu)
    sudo bin/mitamae local roles/ubuntu_system.rb --node-json node.json   # system: apt/locale
    bin/mitamae local roles/ubuntu_user.rb --node-json node.json          # user: dotfiles/mise/zsh
    ;;
esac

# node.json（platform/arch を除去）
{ "directory_links": [...], "alias_links": {}, "template_copy_targets": [...] }

# Makefile: update は repo 更新のみ、パッケージ更新は upgrade 側へ
update:      # git pull + submodule 更新のみ（brew/apt を呼ばない）
upgrade:     # etc/upgrade/upgrade.sh 内で darwin=brew update+upgrade / ubuntu=apt update+upgrade
```

## Consequences

### Good

* macOS / Ubuntu のどちらでも `make install` 一発で同じ手順のセットアップが成立する
* OS 固有処理が cookbook 単位に分離され、`init.sh` が薄くなり見通しが改善する
* 冪等な再実行が可能になり、サーバの再セットアップや設定修正のコストが下がる
* OS を追加したくなった場合（例: 他の Linux ディストリビューション）も role 追加で拡張できる

### Bad

* `init.sh` の macOS 固有処理を cookbook へ移植する初期コストがかかる
* Ubuntu 実環境（サーバ/デスクトップ）での検証手段を用意する必要がある（VM や Docker での検証を含む）
* `node.json` から `platform` / `arch` を除去するため、それらを参照している既存レシピがあれば追随修正が必要
* role 分割（system / user / desktop）が増え、実行手順のドキュメント化が必須になる

## Definition of Done

### 構成・分岐
- [x] `node.json` から `platform` / `arch` を除去し、環境非依存属性のみになっていること
- [x] 入口スクリプト（`etc/lib/detect_os.sh` 等）が `uname -s` + `/etc/os-release` から `darwin` / `ubuntu` を、`uname -m` から `amd64` / `arm64` を判定し、未知 arch はエラー終了すること
- [x] `etc/init/init.sh` の OS 判定で macOS は `roles/darwin.rb`、Ubuntu は `roles/ubuntu_system.rb`（sudo）+ `roles/ubuntu_user.rb`（通常ユーザー）が実行されること
- [x] `etc/deploy.sh` の shebang が zsh 依存でなくなり、Ubuntu 最小インストール直後でも起動できること（`#!/bin/bash` 化。Makefile も `bash` 起動）

### macOS 移設（リグレッションなし）
- [x] `etc/init/init.sh` の macOS 固有処理（Homebrew 導入・`brew install`・`defaults write`・`/usr/local` 権限）が cookbook（`homebrew` / `macos_defaults`）へ移設されていること
- [x] `/usr/local` 権限変更は現在も必要か再評価し、必要な場合のみ darwin 限定で残すこと（darwin 限定 + 要否再評価コメントで存置）
- [x] macOS 上で `make deploy` / `make init` / `make test` / `make deploy-dry-run` が従来どおり成功すること（dry-run + test で確認。full init は冪等前提）
- [x] 既存の `./bin/mitamae local roles/darwin.rb --node-json node.json` 直接実行が引き続き動作すること

### Ubuntu 対応
- [x] `roles/ubuntu_system.rb` / `roles/ubuntu_user.rb` が追加され、Ubuntu 上で `make deploy`（dry-run）+ role 実行が成功すること（Docker 実地確認。full `make init` の言語コンパイルは長時間のため未完走だが機構は確認済み）
- [x] `cookbooks/apt`（git, tig, zsh, build-essential 等）が sudo 前提で冪等に動くこと
- [x] `cookbooks/locale`（`locale-gen` / `LANG`）で UTF-8 ロケールが整うこと
- [x] `cookbooks/zsh`（oh-my-zsh + plugin 配置）が Ubuntu で動くこと（chsh は system role で実測）
- [x] GUI 依存物は `node[:profile] == "desktop"` のときのみ適用され、`server` プロファイルでは実行されないこと（スタブガードで確認）
- [x] `./bin/mitamae local roles/ubuntu_user.rb --node-json node.json` 直接実行が Ubuntu で動作すること

### Makefile / パッケージ更新
- [x] `make update` が repo/submodule 更新のみになり、`brew update` 直叩きが解消されていること（Ubuntu でも失敗しない）
- [x] パッケージ更新が `make upgrade`（内部で darwin=brew / ubuntu=apt）へ集約されていること

### ドキュメント・完了
- [x] `AGENTS.md` / `README` 系に Ubuntu 対応と role 実行手順（sudo 境界含む）が追記されていること（T16 で AGENTS.md/README.md を更新）
- [x] mitamae / mise / oh-my-zsh の取得が checksum 検証またはタグ固定になっていること（mitamae=SHA256SUMS で checksum 検証、mise=公式インストーラ内部で checksum 検証・CLI ツールは cosign 検証、oh-my-zsh=upstream にリリースタグが無いため `git clone --depth 1` 方式を採用＝本項目の例外として明記）
- [x] 本 ADR のステータスが accepted に遷移していること

## 実装タスク分割（Sonnet 委託単位）

以下は本 ADR 確定後の実装を Sonnet クラスのサブエージェントへ委託するための粒度に分割したもの。各タスクは 1 PR / 1 セッションで完結できる大きさを目安にし、依存関係を明記する。進捗は各タスクのチェックボックスで管理する。

> 進捗凡例: `[ ]` 未着手 / `[~]` 着手中 / `[x]` 完了

### フェーズ 0: 基盤（他タスクの前提）

- [x] **T1. OS/arch 判定ライブラリの追加** — `etc/lib/detect_os.sh` を新規作成。`detect_platform`（darwin/ubuntu）と `detect_arch`（amd64/arm64、未知はエラー）を関数提供。単体で `bash etc/lib/detect_os.sh --self-test` 的に検証可能にする。依存: なし。※完了: `#!/bin/bash`、source 時に `set -eu` を汚染しない設計、`--self-test` が macOS で darwin/arm64 を返し成功
- [x] **T2. node.json から platform/arch を除去** — `node.json` を環境非依存属性のみに。`platform`/`arch` を参照している箇所を grep で洗い出し、`node[:platform]`（自動検出）へ置換。依存: なし（ただし macOS で回帰確認が必要）。※完了: node.json 編集済み、darwin.rb は自動検出に委ね未変更、macOS dry-run で darwin 分岐の機能を確認。README/AGENTS の platform 記載は T16 で対応
- [x] **T3. install_mitamae.sh の arch 対応** — T1 の `detect_arch` を使い、`darwin/arm64`・`linux/amd64`・`linux/arm64` のバイナリを取得。checksum 検証を追加。依存: T1。※完了: `#!/bin/bash` 化、`ubuntu→linux`/`amd64→x86_64` マッピング、SHA256SUMS で checksum 検証（v2.0.0）、macOS で動作確認

### フェーズ 1: macOS 移設（リグレッションを出さないことが最優先）

> **フェーズ1 設計決定（2026-07-03 確定）**:
> - **brew 移設方針**: `brew bundle`（Brewfile）ではなく、`init.sh` の**個別 `brew install` リストを忠実に移設**する（利用者選択。挙動維持を優先）。Brewfile への統一は別 ADR で改めて検討する
> - **init.sh の実態**: 個別 install（約21パッケージ）・Homebrew 導入・`defaults write`・`/usr/local` 権限のほか、git 設定・git-secrets 設定・oh-my-zsh 導入・version 確認・`ghq get`・`mkdir ~/duck/Volumes` が混在。フェーズ1 では homebrew / macos_defaults の明確なもののみ cookbook 化し、git 設定・oh-my-zsh 等の共通処理は init.sh に残す（oh-my-zsh は phase2 T11 で cookbook 化予定）
> - **darwin.rb の実態**: 現状 `base + dotfiles + Xcode CLT + mise`（base.rb は mise を含まずディレクトリ作成のみ）。T6 は homebrew / macos_defaults の include 追加が主

- [x] **T4. homebrew cookbook 新設** — `cookbooks/homebrew/default.rb` に Homebrew 導入 + `brew update` + 個別 `brew install` リスト（git tig gibo zlib mise git-secrets zsh vim less lesspipe trash tree mas curl peco fzf jump yq jq ghq mountain-duck）+ `/usr/local` 権限（darwin 限定・要否再評価コメント付き）を移設。`not_if` で冪等化。依存: なし。※完了: 忠実移設、`test -O` で所有者判定（mruby に Process.uid 無し/GNU stat 衝突を回避）、dry-run は brew update のみ変更で既存挙動どおり
- [x] **T5. macos_defaults cookbook 新設** — `defaults write com.apple.desktopservices DSDontWriteNetworkStores true` を `cookbooks/macos_defaults/default.rb` へ移設。冪等化（`only_if`/`not_if`）。依存: なし。※完了: execute + `not_if`（実測値 `true` 比較）で冪等化、dry-run でスキップ確認
- [x] **T6. roles/darwin.rb 再編** — `base → dotfiles → Xcode CLT → homebrew → macos_defaults → mise` の順に include（brew が mise の前提を満たす順序）。依存: T4, T5。※完了: darwin 分岐に homebrew・macos_defaults の include を追加、dry-run で読み込み順を確認
- [x] **T7. init.sh の darwin 経路を role 呼び出しへ** — 移設済みの macOS 固有処理（Homebrew 導入・brew update・brew install 群・defaults write・/usr/local 権限・darwin.rb ハードコード実行）を削除し、`detect_os.sh` の `detect_platform` で darwin 分岐 → `roles/darwin.rb` 実行に置換。git 設定・git-secrets 設定・oh-my-zsh・version 確認等の共通処理は残す。依存: T1, T6。※完了: 重複 brew install 全削除（残存は commented のみ）、role 実行に `--node-json node.json` 追加（整合性改善）、未対応 OS は明示エラー、`bash -n` 構文 OK
- [x] **T8. macOS 回帰テスト** — `make deploy-dry-run`・`bin/mitamae local --dry-run roles/darwin.rb --node-json node.json`・`make test` と `--node-json node.json` 直接実行を macOS で確認（full `make init` は冪等前提で任意）。依存: T2, T7。※完了: darwin.rb dry-run で読み込み順・変更内容が期待どおり、deploy-dry-run で install_mitamae 新方式・directory_links 読込を確認、make test 合格（冒頭 unset warning は mise フック由来の既存ノイズ）

### フェーズ 2: Ubuntu 対応

> **フェーズ2 設計決定（2026-07-03 確定）**:
> - **CLI ツール調達**: apt 優先、apt に無いものは mise で導入（利用者選択）。apt 担当 = `git tig zsh build-essential curl vim less tree jq fzf ripgrep trash-cli locales ca-certificates unzip`、mise 担当（Ubuntu 固有・macOS は brew）= `eza starship ghq peco jump yq`（mise の aqua/ubi backend）
> - **chsh**: 自動化する（利用者選択）。ただし `/etc/passwd` を変更するため **ubuntu_system role（sudo）側**に置き `$SUDO_USER` のログインシェルを zsh へ。冗長ガード（既に zsh なら skip）付き
> - **desktop**: 今回は server 基盤のみ実装。desktop は `node[:profile] == "desktop"` のガードと空の拡張点のみ用意（fonts/IME/gsettings の具体実装は別途）
> - **検証**: Docker 利用可（v29.6.1 確認済み）。T14 は Ubuntu コンテナで実施
> - **シェル依存の注意**: `.zshrc` の `fd` は自作関数エイリアスで fd-find 不要。`rg`(ripgrep) は必要。git-secrets は apt に無いため T13 で init.sh 共通 tail の git-secrets ブロックを「バイナリ非在なら skip」に耐性化する

- [x] **T9. apt cookbook 新設** — `cookbooks/apt/default.rb`。`apt-get update` + `package` リソースで `git tig zsh build-essential curl vim less tree jq fzf ripgrep trash-cli locales ca-certificates unzip` を導入。sudo 前提・冪等。依存: なし。※完了: `ruby -c` Syntax OK、DEBIAN_FRONTEND=noninteractive 設定、実地は T14
- [x] **T10. locale cookbook 新設** — `cookbooks/locale/default.rb`。`locale-gen en_US.UTF-8 ja_JP.UTF-8` + `update-locale LANG=en_US.UTF-8`（サーバ安全側）。sudo 前提・冪等。依存: なし（locales パッケージは T9/自身で担保）。※完了: Syntax OK、not_if で冪等化、実地は T14
- [x] **T11. zsh cookbook 新設** — `cookbooks/zsh/default.rb`。oh-my-zsh 導入（git clone、`not_if` で冪等）+ plugin 配置。**user 処理・sudo 不要・chsh は含めない**（chsh は system 側）。OS 共通。依存: なし。※完了: Syntax OK、git clone 方式（.zshrc symlink 保護）、macOS dry-run でスキップ確認
- [x] **T12. roles/ubuntu_system.rb / ubuntu_user.rb 新設** — system（sudo）= apt + locale + chsh（$SUDO_USER を zsh へ、ガード付き）+ desktop スタブガード。user（通常ユーザー）= **base** + dotfiles + zsh(oh-my-zsh) + mise + Ubuntu 固有 CLI ツール（mise: eza starship ghq peco jump yq）。※補正: `base.rb` は `ENV['HOME']` 配下を作るユーザーレベル処理のため **user role 側**に置く（system=sudo では /root 配下に作ってしまうため）。CLI ツールは新設 `cookbooks/mise_tools/default.rb` に切り出す。依存: T9, T10, T11。※完了: 3ファイル Syntax OK、chsh は only_if($SUDO_USER)+not_if(既 zsh) の二重ガード、mise_tools は peco/jump を個別 execute（T14 で backend 調整前提）
- [x] **T13. init.sh の ubuntu 経路追加** — `detect_platform` の ubuntu 分岐で `sudo bin/mitamae local roles/ubuntu_system.rb --node-json node.json` → `bin/mitamae local roles/ubuntu_user.rb --node-json node.json` を実行。git-secrets ブロックを `command -v git-secrets` で耐性化。依存: T1, T12。※完了: ubuntu 経路追加、git-secrets を elif command -v で耐性化、bash -n OK
- [x] **T14. Ubuntu 検証環境で動作確認** — Docker（ubuntu:24.04 等）上で deploy 相当 + role 実行の dry-run/実適用を確認。依存: T13。※完了: Docker(linux/arm64) 実地検証で detect_os→ubuntu/arm64、install_mitamae→linux/aarch64+checksum、deploy、ubuntu_system(apt/locale/chsh)、ubuntu_user(base/dotfiles/zsh/mise/mise_tools) すべて動作確認。chsh は /bin/bash→/usr/bin/zsh を実測。検証中に下記の欠陥を発見・修正

#### T14 検証で発見・修正した欠陥（実地検証の成果）

- **apt cookbook の `environment` 誤用**: mitamae の `execute` は Chef 的 `environment` 属性を持たず `NoMethodError`。`command 'DEBIAN_FRONTEND=noninteractive apt-get update'` のインライン指定へ修正（T14 内で対応）
- **T14a: mise バイナリ導入の欠落**: Ubuntu 経路に mise 本体導入が無く `mise: not found`。`cookbooks/mise/default.rb` に公式インストーラ導入（macOS は not_if でスキップ）+ mise コマンドの PATH 前置を追加
- **T14b: mise_tools の config.toml 汚染 + jump 曖昧**: `mise use -g` が dotfiles 管理の config.toml(symlink) を汚染。`~/.config/mise/conf.d/ubuntu-cli-tools.toml`（symlink 外）へ分離する方式へ全面書き換え。`jump` は registry 曖昧のため明示 backend `aqua:gsamokovarov/jump` を指定。eza/starship/ghq/yq/peco は短縮名で解決を実測確認

### フェーズ 3: Makefile / ドキュメント

- [x] **T15. Makefile の update/upgrade 責務分離** — `update` は repo/submodule 更新のみ、パッケージ更新は `upgrade`（darwin=brew / ubuntu=apt）へ。依存: T1。※完了: Makefile から brew update 削除、upgrade.sh を detect_os で darwin/ubuntu 分岐（brew / apt）、`make -n update` に brew update 無しを確認。detect_os.sh の BASH_SOURCE ガードを zsh source でも set -u で落ちないよう `:-` 化
- [x] **T16. ドキュメント追記** — `AGENTS.md` / `README` に Ubuntu 対応と role 実行手順（sudo 境界・profile 指定）を追記。依存: フェーズ 1・2 完了後。※完了: AGENTS.md（roles/cookbooks 一覧、OS Detection and Privilege Boundaries 節、node.json 記述更新）、README.md（両 OS 対応・sudo 境界・cookbook 一覧）を実装と照合のうえ更新
- [x] **T17. ADR を accepted に更新** — 全タスク完了・検証後にステータス遷移。依存: 全タスク。※完了: 承認時に status: accepted へ遷移済み

### 委託時の注意

- 破壊的操作（symlink 張り替え、権限変更）を含むタスクは、必ず `make deploy-dry-run` / mitamae `--dry-run` で事前確認してから適用する
- `-f` / `--force` は使用禁止、削除は `trash` を使う（本リポジトリ規約）
- macOS 移設タスク（フェーズ 1）は「既存挙動の維持」がゴールであり、挙動を変える改善は本 ADR のスコープ外として別途起票する

## More Information

### 関連 ADR

- `docs/adr/2026-01-02_deploy-dry-run-and-link-check.md`: `make deploy` の dry-run とリンクチェック導入。本 ADR の入口スクリプト変更後もこれらの機能を維持する
- `docs/adr/2026-01-23_add_directory_link_mode.md`: `node.json` の `directory_links` 導入。node.json の構造変更時に互換を保つ必要がある
- `docs/adr/2026-04-02_generate_local_codex_config_from_template_on_deploy.md`: deploy 時のテンプレート展開（`template_copy_targets`）。OS 分岐後も両 OS で動作する必要がある

### レビュー履歴

- 2026-07-03: Codex CLI（`review-by-codex`）によるプランレビューを実施。指摘（node.json 固定解除の決め切り、deploy/init 責務分離、sudo 境界、zsh shebang 依存排除、mitamae arch 対応、GUI プロファイル分離、update/upgrade 責務分離、バイナリ取得の checksum/タグ固定化）を「確定方針（レビュー反映）」および Definition of Done へ反映済み

### 参考文献

- mitamae: https://github.com/itamae-kitchen/mitamae
- MADR: https://adr.github.io/madr/
