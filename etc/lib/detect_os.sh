#!/bin/bash
#
# OS / CPU アーキテクチャ判定ライブラリ
#
# 用途:
#   他スクリプトから `source etc/lib/detect_os.sh` して読み込み、
#   detect_platform / detect_arch 関数を利用する。
#
# 注意:
#   このファイルは source されて使われることを前提としている。
#   source 時に呼び出し元のシェル状態（set -eu 等）を壊さないよう、
#   ファイル冒頭で set -eu をグローバルには効かせない。
#   直接実行された場合のみ `--self-test` オプションでセルフテストを行う。

# /etc/os-release から指定キーの値を取り出す内部ヘルパー
# 例: _detect_os_release_value ID -> "ubuntu"
_detect_os_release_value() {
    local key="$1"

    if [ -r /etc/os-release ]; then
        grep -E "^${key}=" /etc/os-release | head -n 1 | cut -d= -f2- | tr -d '"'
    fi
}

# OS プラットフォームを判定して darwin / ubuntu を標準出力へ返す
# 判定できない場合は標準エラーへメッセージを出し、非 0 を返す
detect_platform() {
    local kernel
    kernel="$(uname -s)"

    if [ "$kernel" = "Darwin" ]; then
        echo "darwin"
        return 0
    fi

    if [ "$kernel" = "Linux" ]; then
        local os_id os_id_like
        os_id="$(_detect_os_release_value ID)"
        os_id_like="$(_detect_os_release_value ID_LIKE)"

        if [ "$os_id" = "ubuntu" ]; then
            echo "ubuntu"
            return 0
        fi

        # Debian 系 ID_LIKE を含む Ubuntu 派生ディストリビューションも ubuntu 扱いとする
        case " ${os_id_like} " in
            *" ubuntu "* | *" debian "*)
                echo "ubuntu"
                return 0
                ;;
        esac

        echo "判定できない Linux ディストリビューションです（/etc/os-release の ID/ID_LIKE が ubuntu 系ではありません）" >&2
        return 1
    fi

    echo "未対応の OS です: ${kernel}" >&2
    return 1
}

# CPU アーキテクチャを判定して amd64 / arm64 を標準出力へ返す
# 未知のアーキテクチャは標準エラーへメッセージを出し、非 0 を返す
detect_arch() {
    local machine
    machine="$(uname -m)"

    case "$machine" in
        x86_64)
            echo "amd64"
            return 0
            ;;
        aarch64 | arm64)
            echo "arm64"
            return 0
            ;;
        *)
            echo "未対応の CPU アーキテクチャです: ${machine}" >&2
            return 1
            ;;
    esac
}

# detect_platform / detect_arch の結果を人間可読に表示するセルフテスト
# 両方成功なら 0、どちらか失敗なら非 0 を返す
_detect_os_self_test() {
    local platform_status=0
    local arch_status=0
    local platform arch

    if platform="$(detect_platform)"; then
        echo "platform: ${platform}"
    else
        platform_status=1
        echo "platform: 判定失敗" >&2
    fi

    if arch="$(detect_arch)"; then
        echo "arch: ${arch}"
    else
        arch_status=1
        echo "arch: 判定失敗" >&2
    fi

    if [ "$platform_status" -eq 0 ] && [ "$arch_status" -eq 0 ]; then
        echo "セルフテスト: 成功"
        return 0
    fi

    echo "セルフテスト: 失敗" >&2
    return 1
}

# 直接実行された場合のみセルフテストを行う（source 時は何もしない）
# 注: BASH_SOURCE は bash 専用配列。zsh から source されると未定義になるため、
# nounset（set -u）下でもエラーにならないよう :- でデフォルト空を与える。
# zsh から source した場合は両辺が食い違い、セルフテストは実行されない（意図通り）。
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    set -eu

    if [ "${1:-}" = "--self-test" ]; then
        _detect_os_self_test
        exit $?
    fi

    echo "使用法: $0 --self-test" >&2
    exit 1
fi
