# ==========================================
#  Zinit Plugins Configuration
# ==========================================

# ==========================================
#  Shell Enhancement Plugins
# ==========================================

# zsh-autosuggestions - Command autosuggestions based on history
zinit light-mode for \
    @'zsh-users/zsh-autosuggestions'

# Core zsh enhancement plugins - Load first to establish base functionality
zinit light-mode blockf for \
    atload'async_init' @'mafredri/zsh-async' \
    @'zsh-users/zsh-completions' \
    @'zdharma-continuum/fast-syntax-highlighting'

# zsh-autocomplete - Real-time completion suggestions as you type
zinit load @'marlonrichert/zsh-autocomplete'

# fzf-tab - Enhanced tab completion with fzf interface
zinit light-mode for \
    @'Aloxaf/fzf-tab'

# zsh-history-substring-search - Advanced history search with arrow keys
__zsh_history_substring_search_atload() {
    bindkey "${terminfo[kcuu1]}" history-substring-search-up   # arrow-up
    bindkey "${terminfo[kcud1]}" history-substring-search-down # arrow-down
    bindkey "^[[A" history-substring-search-up   # arrow-up
    bindkey "^[[B" history-substring-search-down # arrow-down
}
zinit light-mode for \
    atload'__zsh_history_substring_search_atload' \
    @'zsh-users/zsh-history-substring-search'

# zsh-autopair - Automatically pair brackets and quotes
zinit light-mode for \
    @'hlissner/zsh-autopair'

# compinit の後に読み込まれた補完プラグイン（zsh-completions 等）が queue した
# compdef を反映する。これが無いと後発の補完定義が有効にならない（zinit標準手順）。
zinit cdreplay -q

# ==========================================
#  Package Management Strategy
# ==========================================
#
# Homebrew: System tools, heavy dependencies, frequent updates
# - starship, ripgrep, gh, eza, bat, fd, delta, navi
# - Completions: /opt/homebrew/share/zsh/site-functions/
#
# zinit: Lightweight utilities, shell-specific plugins
# - mmv, zoxide
# - zsh-autosuggestions, fast-syntax-highlighting, etc.
#
# ==========================================
#  Lightweight Utilities (zinit-managed)
# ==========================================

# mmv - File mover utility
zinit light-mode as'program' from'gh-r' for \
    pick'mmv*/mmv' @'itchyny/mmv'

# GitHub CLI completion is available via Homebrew at /opt/homebrew/share/zsh/site-functions/_gh

# eza - Modern ls replacement (installed via Homebrew)
# Aliases are defined in 01-aliases.zsh
# Completion available at /opt/homebrew/share/zsh/site-functions/_eza

# ==========================================
#  Productivity & Navigation Tools
# ==========================================

# navi - Interactive cheat sheet for terminal commands (Ctrl+N to search)
# navi installed via Homebrew, configuration and keybindings below
__navi_search() {
    LBUFFER="$(navi --print --path '$XDG_CONFIG_HOME/navi/cheats' --query="$LBUFFER")"
    zle reset-prompt
}
__setup_navi() {
    if command -v navi >/dev/null; then
        export NAVI_CONFIG="$XDG_CONFIG_HOME/navi/config.yaml"
        alias mynavi="navi --path '$XDG_CONFIG_HOME/navi/cheats'"

        zle -N __navi_search
        bindkey '^N' __navi_search
    fi
}
__setup_navi

# forgit - Interactive git interface with fzf
__forgit_atload() {
    export FORGIT_INSTALL_DIR="$PWD"
    export FORGIT_NO_ALIASES=1
}
zinit light-mode as'program' for \
    atload'__forgit_atload' \
    pick'bin/git-forgit' \
    ver'main' \
    @'wfxr/forgit'

# zoxide - Smart directory jumping based on frequency (XDG compliant)
__zoxide_atload() {
    # XDG Base Directory compliance
    export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"   # Database location (persistent data)
    export _ZO_EXCLUDE_DIRS="$HOME"               # Exclude home directory from tracking
    export _ZO_RESOLVE_SYMLINKS=1                 # Resolve symlinks for consistency
    eval "$(zoxide init zsh)"
}
zinit light-mode as'program' from'gh-r' for \
    pick'zoxide*/zoxide' \
    atclone'./zoxide*/zoxide init zsh >init.zsh' atpull'%atclone' \
    atload'__zoxide_atload' \
    @'ajeetdsouza/zoxide'

# ==========================================
#  Modern CLI Replacements
# ==========================================

# fd completion is available via Homebrew at /opt/homebrew/share/zsh/site-functions/_fd

# bat completion is available via Homebrew at /opt/homebrew/share/zsh/site-functions/_bat

# ripgrep - Fast text search tool (installed via Homebrew)
# Completion available at /opt/homebrew/share/zsh/site-functions/_rg

# git-delta - Syntax-highlighting pager for git (installed via Homebrew)
