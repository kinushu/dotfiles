dotfiles
========

## 初期設定

```bash
git clone git@github.com:kinushu/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
make init

brew bundle --file ./Brewfile
```

## 環境ごとの独自設定

~/.bashrc.local
に記述。