dotfiles
========

## 初期設定

```bash
git clone git@github.com:kinushu/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
make init

# Desktopソフトなど導入
brew bundle --file ./Brewfile
```

## 環境ごとの独自設定

~/.bashrc.local
に記述。

## 日々の更新

```bash
make upgrade
```

## 設定吸い上げ

```bash
brew bundle dump
```