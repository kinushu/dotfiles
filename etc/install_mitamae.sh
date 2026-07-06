#!/bin/bash
#
# mitamae 取得スクリプト
#
# darwin / ubuntu (Linux) の OS と amd64 / arm64 の CPU アーキテクチャを判定し、
# 対応する mitamae バイナリを GitHub リリースから取得して ./bin/mitamae に配置する。
# 取得したバイナリは、リリースに公開されている SHA256SUMS で checksum 検証してから配置する。

set -eu

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd "$script_dir"

## プロジェクトのルートディレクトリに移動
cd ../

# OS / アーキテクチャ判定ライブラリを読み込む
source ./etc/lib/detect_os.sh

# OS を判定する（判定失敗時は detect_os.sh がエラーメッセージを標準エラーへ出す）
if ! platform=$(detect_platform); then
    echo "OS の判定に失敗したため処理を中断します" >&2
    exit 1
fi

# CPU アーキテクチャを判定する（判定失敗時は detect_os.sh がエラーメッセージを標準エラーへ出す）
if ! arch=$(detect_arch); then
    echo "CPU アーキテクチャの判定に失敗したため処理を中断します" >&2
    exit 1
fi

# detect_os.sh の語彙（darwin/ubuntu, amd64/arm64）を
# mitamae のリリース資産名の語彙（darwin/linux, x86_64/aarch64）へ変換する
case "$platform" in
    darwin) asset_os=darwin ;;
    ubuntu) asset_os=linux ;;
    *)
        echo "未対応の platform です: ${platform}" >&2
        exit 1
        ;;
esac

case "$arch" in
    amd64) asset_arch=x86_64 ;;
    arm64) asset_arch=aarch64 ;;
    *)
        echo "未対応の arch です: ${arch}" >&2
        exit 1
        ;;
esac

asset_name="mitamae-${asset_arch}-${asset_os}"
release_base_url="https://github.com/itamae-kitchen/mitamae/releases/latest/download"
download_path="./bin/mitamae.download"

echo "mitamae バイナリを取得します: ${asset_name}"

# checksum 検証用に SHA256SUMS を取得する（リリースに公開されている）
sha256sums=$(curl -fsSL "${release_base_url}/SHA256SUMS")

expected_sha256=$(printf '%s\n' "$sha256sums" | awk -v name="$asset_name" '$2 == name { print $1 }')
if [ -z "$expected_sha256" ]; then
    echo "SHA256SUMS に ${asset_name} の checksum が見つかりません" >&2
    exit 1
fi

# 対象バイナリを一時ファイルへ取得する（checksum 検証前に既存の ./bin/mitamae を上書きしないため）
curl -fsSLo "$download_path" "${release_base_url}/${asset_name}"

# 利用可能な sha256 計算コマンドを判定する（Linux は sha256sum、macOS は shasum が標準）
if command -v sha256sum >/dev/null 2>&1; then
    actual_sha256=$(sha256sum "$download_path" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    actual_sha256=$(shasum -a 256 "$download_path" | awk '{print $1}')
else
    echo "sha256 を計算できるコマンド（sha256sum / shasum）が見つかりません" >&2
    trash "$download_path"
    exit 1
fi

if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "checksum が一致しません（期待値: ${expected_sha256}, 実際: ${actual_sha256}）取得したバイナリはゴミ箱へ移動します" >&2
    trash "$download_path"
    exit 1
fi

mv "$download_path" ./bin/mitamae
chmod +x ./bin/mitamae

echo "mitamae の取得と checksum 検証が完了しました: ./bin/mitamae"
