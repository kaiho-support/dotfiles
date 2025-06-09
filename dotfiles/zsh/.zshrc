# Path to your oh-my-zsh installation (if using)
# export ZSH="$HOME/.oh-my-zsh"

# Basic zsh configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# Enable completion
autoload -Uz compinit
compinit

# Homebrew setup
if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# Modern CLI tools aliases (if installed via brew)
if command -v lsd > /dev/null; then
    alias ls='lsd'
fi

if command -v bat > /dev/null; then
    alias cat='bat'
fi

if command -v fzf > /dev/null; then
    # fzf key bindings
    source <(fzf --zsh)
fi

# Prompt
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '