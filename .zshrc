# Created by newuser for 5.4.2
# 環境変数
export LANG=ja_JP.UTF-8

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# 直前のコマンドの重複を削除
setopt hist_ignore_dups

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# 同時に起動したzshの間でヒストリを共有
setopt share_history

# 補完機能を有効にする
autoload -Uz compinit
compinit -u
if [ -e /usr/local/share/zsh-completions ]; then
  fpath=(/usr/local/share/zsh-completions $fpath)
fi

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補を詰めて表示
setopt list_packed

# 補完候補一覧をカラー表示
autoload colors
zstyle ':completion:*' list-colors ''

# コマンドのスペルを訂正
setopt correct
# ビープ音を鳴らさない
setopt no_beep

# ディレクトリスタック
DIRSTACKSIZE=100
setopt AUTO_PUSHD

# git
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{yellow}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

# プロンプトカスタマイズ
PROMPT='
[%B%F{red}%n@%m%f%b:%F{green}%~%f]%F{cyan}$vcs_info_msg_0_%f
%F{yellow}$%f '

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

function git-branch-fzf() {
  local selected_branch=$(git for-each-ref --format='%(refname)' --sort=-committerdate refs/heads | perl -pne 's{^refs/heads/}{}' | fzf --query "$LBUFFER")

  if [ -n "$selected_branch" ]; then
    BUFFER="git checkout ${selected_branch}"
    zle accept-line
  fi

  zle reset-prompt
}

zle -N git-branch-fzf
bindkey "^b" git-branch-fzf

function select-history() {
  BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

# eval "$(direnv hook bash)"
export INTEGRATION_NAME=naoki-kanda
export ZUORA_USERNAME=project-z+sandbox_api@c-fo.com
export ZUORA_PASSWORD='8GRr!yMRsP%%dmW'
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# ENV
export ZUORA_CLIENT_ID=74313ad1-fd44-4d14-9987-c54e21cf4b08
export ZUORA_CLIENT_SECRET='8yCrJXYOnToFl/0GPBxl4Go8UBL5=jsxZPZWs4z27'
export DOCKER_HOST_NAME=172.17.0.1
export ACCOUNTING_ROOT_URL=http://localhost:3000/
export ACCOUNTING_INTERNAL_URL=http://$DOCKER_HOST_NAME:3000
export ACCOUNTING_API_PRIVATE_SERVER=$ACCOUNTING_INTERNAL_URL
export ACCOUNTS_INTERNAL_URL=http://localhost:3004
export DISABLE_HOST_CHECK=1
export ASSET_SERVER=http://localhost:8888
export DEV_ON_EC2=1
export ELASTICSEARCH_ENDPOINT_URL=http://localhost:9200
export CFO_TASK_OWNER_EMAIL=naoki-kanda@freee.co.jp
export CFO_TASK_OWNER_SLACK_ACCOUNT=naoki-kanda

# asdf
export ASDF_DATA_DIR=/opt/asdf-data
. /opt/asdf/asdf.sh
# . /opt/asdf/completions/asdf.bash
fpath=(${ASDF_DATA_DIR}/completions $fpath)
autoload -Uz compinit && compinit

# User Alias
# Git Alias
function gitdv() {
    git fetch -p upstream;
    git checkout upstream/develop;
    git branch --merged | egrep -v "\*|master|develop" | xargs git branch -D;
}
alias gitdv=gitdv
alias cdw='cd ~/work/src/github.com/kaionn/CFO-Alpha/'
alias gitch='(){git checkout -b feature/$1}'
