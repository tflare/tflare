# compinit$B$N=i4|2=(B
autoload -U compinit
compinit

# $B%G%#%l%/%H%j$r5-O?(B
setopt auto_pushd
# $BJd408uJd$r5M$a$FI=<((B
setopt list_packed
# $B%3%^%s%I<+F0=$@5(B
setopt correct

# $BMzNr8!:w5!G=(B
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# $BJd408uJd%+!<%=%kA*Br(B
zstyle ':completion:*:default' menu select=1 

## $B%R%9%H%j4XO"(B

# $BMzNr%U%!%$%k(B
HISTFILE="$HOME/.zsh_history"      
HISTSIZE=100000                  
SAVEHIST=100000

# $B;~9o$r5-O?(B
setopt extended_history

# $BMzNr$r%$%s%/%j%a%s%?%k$KDI2C(B
setopt inc_append_history

# $BMzNr$N6&M-(B
setopt share_history

# $BD>A0$HF1$8%3%^%s%I%i%$%s$O%R%9%H%j$KDI2C$7$J$$(B
setopt hist_ignore_dups                  


##$B!!%W%m%s%W%H4XO"(B
setopt prompt_subst

local BLUE=$'%{\e[34m%}'
local DEFAULT=$'%{\e[m%}'
PROMPT=$BLUE'${USER}@${HOST}%(!.#.$)'$DEFAULT
RPROMPT='[%~]'
