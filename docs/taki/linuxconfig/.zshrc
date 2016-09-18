# compinitの初期化
autoload -U compinit
compinit

# ディレクトリを記録
setopt auto_pushd
# 補完候補を詰めて表示
setopt list_packed
# コマンド自動修正
setopt correct

# 履歴検索機能
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# 補完候補カーソル選択
zstyle ':completion:*:default' menu select=1 

## ヒストリ関連

# 履歴ファイル
HISTFILE="$HOME/.zsh_history"      
HISTSIZE=100000                  
SAVEHIST=100000

# 時刻を記録
setopt extended_history

# 履歴をインクリメンタルに追加
setopt inc_append_history

# 履歴の共有
setopt share_history

# 直前と同じコマンドラインはヒストリに追加しない
setopt hist_ignore_dups                  


##　プロンプト関連
setopt prompt_subst

local BLUE=$'%{\e[34m%}'
local DEFAULT=$'%{\e[m%}'
PROMPT=$BLUE'${USER}@${HOST}%(!.#.$)'$DEFAULT
RPROMPT='[%~]'
