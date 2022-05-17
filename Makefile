DOTFILES_EXCLUDES := .DS_Store .git .gitmodules .zsh
DOTFILES_TARGET   := $(wildcard .??*)
CLEAN_TARGET      := $(wildcard .??*) .vim .zfunctions
DOTFILES_FILES    := $(filter-out $(DOTFILES_EXCLUDES), $(DOTFILES_TARGET))
UNAME 	          := $(shell uname)
CURRENTDIR        := $(shell pwd)
IS_CTAGS          := $(shell ctags --version 2> /dev/null)

.PHONY: install
install:
	@$(foreach val, $(DOTFILES_FILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	nvim +PlugInstall +qall
	zsh

.PHONY: vim-init
vim-init: ## install vim-plug
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: zsh-init
zsh-init: zsh-pkg-init ## install prompt theme and fzf
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
	git clone -b v0.4.0 https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions

.PHONY: zsh-emoji-completion
zsh-emoji-completion:
	git clone https://github.com/b4b4r07/emoji-cli.git ~/.zsh/emoji-cli

.PHONY: zsh-file-include
zsh-file-include: ## zsh plugin dir
	ln -snfv $(CURRENTDIR)/.zsh.d $(HOME)/.zsh.d

.PHONY: prompt-init
prompt-init: ## install prompt pure
	# pure
	git clone https://github.com/sindresorhus/pure.git "$(HOME)/.zsh/pure"

.PHONY: ghq-init
ghq-init: ## install ghq
ifeq ($(UNAME),Darwin)
	wget https://github.com/motemen/ghq/releases/download/v0.7.4/ghq_darwin_amd64.zip
	unzip ghq_darwin_amd64.zip && sudo mv ghq /usr/local/bin && rm -rf ghq_darwin_amd64* zsh README.txt
endif
ifeq ($(UNAME),Linux)
	wget https://github.com/motemen/ghq/releases/download/v0.7.4/ghq_linux_amd64.zip
	unzip ghq_linux_amd64.zip -d ghq_linux_amd64 && sudo mv ghq_linux_amd64/ghq /usr/local/bin && rm -rf ghq_linux_amd64*
endif

.PHONY: docker-init
docker-init: ## install docker completion
	curl -fLo ~/.zfunctions/_docker https://raw.github.com/felixr/docker-zsh-completion/master/_docker
	exec zsh

.PHONY: kubectx-init
kubectx-init: ## install kubectx completion
	curl -fLo ~/.zfunctions/_kubectx https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh
	curl -fLo ~/.zfunctions/_kubens https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh

.PHONY: nvim-init
nvim-init: ## install nvim
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	ln -snfv $(CURRENTDIR)/.config/nvim/init.vim $(HOME)/.config/nvim/init.vim

.PHONY: krew-init
krew-init: ## install krew
	set -x; cd "$(mktemp -d)" &&
	curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.3.3/krew.{tar.gz,yaml}" &&
	tar zxvf krew.tar.gz &&
	KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" &&
	"$KREW" install --manifest=krew.yaml --archive=krew.tar.gz &&
	"$KREW" update

tmux-init: ## install tmux plugin manager
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

.PHONY: clean
clean: ## unlink symlink and delete dotfiles
	@$(foreach val, $(CLEAN_TARGET), rm -rf $(HOME)/$(val);)

.PHONY: help
help: ## print all available commands
	@printf "\033[36m%-30s\033[0m %-50s %s\n" "[Sub command]" "[Description]" "[Example]"
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'

