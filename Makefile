DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CONFIG_FILES := $(shell find $(DOTPATH)/config -type f)
EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml .gitignore .idea

.DEFAULT_GOAL := help

all:

list: ## Show config files in this repo
	@echo 'Config Files:'
	@find $(DOTPATH)/config -type f | sort

deploy: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@echo ''
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/deploy.sh

init: deploy ## Setup environment settings
	@echo '==> Setup environment settings.'
	@echo ''
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/init/init.sh

test: ## Test dotfiles and init scripts
	@DOTPATH=$(DOTPATH) zsh $(DOTPATH)/etc/test/test.sh

update: ## Fetch changes for this repo
	git pull origin main
	git submodule init
	git submodule update
	git submodule foreach git pull origin main
	brew update

install: update deploy init ## Run make update, deploy, init
	@exec $$SHELL

upgrade: update ## Upgrade modules
	@DOTPATH=$(DOTPATH) zsh $(DOTPATH)/etc/upgrade/upgrade.sh

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


