# dotfiles

## installation

```
bash -c "$(curl -L https://raw.githubusercontent.com/kaionn/dotfiles/master/rc/installer.sh)"
```

## task

```
$ make help
[Sub command]                  [Description]                                      [Example]
install                        zsh and vim init and make symlink
vim-init                       install vim-plug
zsh-init                       install prompt theme and fzf
zsh-file-include               zsh plugin dir
prompt-init                    install prompt pure
ghq-init                       install ghq
docker-init                    install docker completion
kubectx-init                   install kubectx completion
nvim-init                      install nvim
krew-init                      install krew
tmux-init                      install tmux plugin manager
clean                          unlink symlink and delete dotfiles
help                           print all available commands
```
