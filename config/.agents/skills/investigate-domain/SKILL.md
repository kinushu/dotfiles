---
name: investigate-domain
description: ドメイン・Webサイトの調査を行う。ドメイン調査、DNS確認、whois、MXレコード、と言われたときに使用。
---

# ドメイン調査スキル

指定されたURL/ドメインについて、以下の情報を調査して報告する。

## 実行手順

1. URLが指定された場合はドメインを抽出する
2. 以下のコマンドを並列実行して情報を収集する
3. 調査結果をファイルに出力する

### 調査項目

#### WHOIS情報（ドメイン管理状況）
```bash
whois <domain>
```
- 登録者情報
- 登録日・有効期限
- レジストラ情報
- ネームサーバー

#### MXレコード（メールサーバー）
```bash
dig @8.8.8.8 <domain> MX +short
```
- メールサーバーの設定
- 優先度

#### TXTレコード
```bash
dig @8.8.8.8 <domain> TXT +short
```
- SPFレコード
- DKIM設定
- ドメイン検証用レコード

#### Aレコード（参考）
```bash
dig @8.8.8.8 <domain> A +short
```
- IPアドレス

#### NSレコード（参考）
```bash
dig @8.8.8.8 <domain> NS +short
```
- ネームサーバー

## 出力ファイル

調査結果は以下のパスに出力する:
```
tmp/{YYYY-MM-DD}_{HHMM}_{domain}_調査.md
```

例: `tmp/2026-01-23_1430_google.com_調査.md`

※ tmpディレクトリが存在しない場合は作成する

## 出力形式

```markdown
# ドメイン調査結果: <domain>

調査日: YYYY-MM-DD

## WHOIS情報

| 項目 | 値 |
|------|-----|
| 登録者 | xxx |
| 登録日 | yyyy-mm-dd |
| 有効期限 | yyyy-mm-dd |
| レジストラ | xxx |
| 国 | xx |

### ドメインステータス
- status1
- status2

## DNSレコード

### MXレコード
| 優先度 | メールサーバー |
|--------|----------------|
| 10     | mail.example.com |

### TXTレコード
| 種別 | 内容 |
|------|------|
| SPF | v=spf1 ... |
| その他 | ... |

### Aレコード
- xxx.xxx.xxx.xxx

### NSレコード
- ns1.example.com
- ns2.example.com
```
