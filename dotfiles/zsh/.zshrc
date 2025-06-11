# Zsh Configuration - Main Entry Point
# This file sources modular configuration files for better organization

# Basic zsh options
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT
setopt EXTENDED_GLOB

# Enable completion system
autoload -Uz compinit
compinit

# Source configuration modules
source ~/.zsh_env      # Environment variables and paths
source ~/.zsh_aliases  # Command aliases
source ~/.zsh_functions # Custom functions
source ~/.zsh_prompt   # Prompt configuration

# Tool-specific configurations
if command -v fzf > /dev/null; then
    # fzf key bindings and completion
    source <(fzf --zsh)
fi

# Path to your oh-my-zsh installation (if using)
# export ZSH="$HOME/.oh-my-zsh"
# Uncomment and configure if you want to use oh-my-zsh