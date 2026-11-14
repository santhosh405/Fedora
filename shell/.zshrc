# ~/.zshrc - ZSH Configuration

# Environment & PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export EDITOR="nano"
export VISUAL="nano"

# User-level ZSH functions and module paths
fpath=(
    /home/fuckwindows/.local/share/zsh/5.9/functions
    /home/fuckwindows/.local/share/zsh/site-functions
    $fpath
)
module_path=(
    /home/fuckwindows/.local/lib64/zsh/5.9
    $module_path
)

# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_ignore_space

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colors & Prompt
autoload -Uz colors && colors
setopt prompt_subst

# Git branch in prompt if inside repository
git_prompt_info() {
    local ref
    ref=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$ref" ]; then
        echo " %F{yellow}(%f%F{cyan}$ref%f%F{yellow})%f"
    fi
}

PROMPT='%F{blue} %f%F{magenta}%n%f %F{blue}❯%f %F{cyan}%~%f$(git_prompt_info) %F{green}λ%f '

# Quality of Life Options
setopt auto_cd
setopt multios

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
fast() {
    if [[ "$1" == "fetch" ]]; then
        shift
    fi
    command fastfetch "$@"
}
alias fastfetch='fastfetch'
alias pokemon='pokemon-colorscripts'
alias spotify='flatpak run com.spotify.Client'
alias obsidian='flatpak run md.obsidian.Obsidian'
alias c='clear'

# Display Pokémon colorscript on interactive shell launch
if [[ -o interactive ]] && command -v pokemon-colorscripts >/dev/null 2>&1; then
    pokemon-colorscripts -r
fi

# Pywal terminal color palette
[ -f ~/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)


alias run_spotify='flatpak run com.spotify.Client > /dev/null 2>&1 &'
alias run_obsidian='flatpak run md.obsidian.Obsidian > /dev/null 2>&1 &'
