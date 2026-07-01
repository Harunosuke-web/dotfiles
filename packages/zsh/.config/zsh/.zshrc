#########################################################################
# ZSH CONFIGURATION - MAIN STARTUP FILE
#########################################################################
#
# This is the primary zsh configuration file, optimized for fast startup.
# Functions and complex settings are modularized in rc.d/ directory.
#
# LOADING ORDER:
# 1. Core Settings (paths, environment, options)
# 2. Plugin Manager Setup (zinit)
# 3. Essential Tools (mise, starship)
# 4. Key Bindings (immediate response required)
# 5. Lazy Loading (plugins via .zshrc.lazy)
# 6. Local Configuration (user customizations)
#
# KEYBINDING REFERENCE:
# Basic Navigation & Editing:
# - Ctrl+R : History search (custom widget)
# - Ctrl+A : Beginning of line
# - Ctrl+E : End of line
# - Ctrl+K : Kill line
# - Ctrl+Q : Push line or edit
# - Ctrl+W : Backward kill word
# - Alt+G : ghq directory selection
#
# fzf Integration (fzf-key-bindings.zsh):
# - Ctrl+T : File selection widget
# - Alt+C : Directory selection widget
#
# Custom Directory Navigation (02-functions.zsh):
# - Ctrl+Z : fz() - Smart directory jump
# - Ctrl+B : find_cd() - Local directory search
# - Alt+S : fzf-ghq() - Repository navigation
# - Ctrl+G : ghq session management
#
# tmux Integration (02-functions.zsh):
# - Ctrl+F : tmux session create/switch
# - Ctrl+S : tmux session switch
# - Ctrl+X : tmux session kill
# - Ctrl+E : lf file manager popup
#
# Other Tools (04-plugins.zsh):
# - Ctrl+N : navi command search
# - Arrow Keys : zsh-history-substring-search
#
#########################################################################

# ==========================================
#  Core Environment Setup
# ==========================================

### zinit plugin manager ###
typeset -gAH ZINIT
ZINIT[HOME_DIR]="$XDG_DATA_HOME/zinit"
ZINIT[ZCOMPDUMP_PATH]="$XDG_STATE_HOME/zsh/zcompdump"

# Check if zinit is installed, show warning if not
if [[ ! -d "${ZINIT[HOME_DIR]}/bin" ]]; then
    echo "⚠️  Warning: zinit not found. Run 'setup-zinit' to install."
    return 1
fi

source "${ZINIT[HOME_DIR]}/bin/zinit.zsh"

### PATH Configuration ###
typeset -U path
typeset -U fpath

path=(
  "$HOME/.local/bin"(N-/)       # User binaries (highest priority)
  "$HOME/.local/share/npm/bin"(N-/)
  "$path[@]"                    # Existing PATH (includes mise-managed paths)
  "/opt/homebrew/bin"(N-/)      # Homebrew binaries
  "/opt/homebrew/sbin"(N-/)     # Homebrew system binaries
  "/Library/Apple/usr/bin"(N-/) # Apple developer tools
)

fpath=(
  "$XDG_CONFIG_HOME/zsh/completions"(N-/)
  "$XDG_DATA_HOME/zsh/completions"(N-/)
  "$fpath[@]"
  # Homebrew補完（_brew,_gh 等）。zsh組込みの高機能な補完(_git 等)を優先させるため“末尾”に置く。
  # ここより前に組込み($fpath[@])があるので、重複する _git は組込みが勝ち、brew独自(_brew等)だけ拾われる。
  /opt/homebrew/share/zsh/site-functions(N-/)
)

### Environment Variables ###
# Man pages
export MANPATH="$HOME/.local/share/man/dotfiles:$MANPATH"

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=12000
export SAVEHIST=1000000

# Editor preferences
export EDITOR="vi"
command -v vim >/dev/null && EDITOR="vim"
command -v nvim >/dev/null && EDITOR="nvim"
export GIT_EDITOR="$EDITOR"
export TERMINAL="alacritty"
# export BROWSER="brave"

### Shell Options ###
setopt NO_BEEP
setopt IGNOREEOF
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt GLOBDOTS
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE # NOTE: 行頭にspaceを入れたコマンドをhistoryに履歴を残さないようにできる
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INTERACTIVE_COMMENTS
setopt SHARE_HISTORY
# setopt NO_SHARE_HISTORY
setopt MAGIC_EQUAL_SUBST
setopt PRINT_EIGHT_BIT
setopt NO_FLOW_CONTROL

# ==========================================
#  Runtime Tools
# ==========================================

### Runtime tool manager ###
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

### Prompt (Starship) ###
# Load starship early for immediate prompt display
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
else
    echo "⚠️  Warning: starship not found. Install with 'brew install starship'"
fi

# ==========================================
#  Key Bindings
# ==========================================

# Set vi mode as default
bindkey -v

# Essential key bindings (functions defined in 02-functions.zsh)
bindkey "^R" widget::history            # C-r
bindkey "^G" widget::ghq::session       # C-g
bindkey "^[g" widget::ghq::dir          # Alt-g

bindkey "^A" beginning-of-line          # C-a
bindkey "^E" end-of-line                # C-e
bindkey "^K" kill-line                  # C-k
bindkey "^Q" push-line-or-edit          # C-q
bindkey "^W" vi-backward-kill-word      # C-w
bindkey "^?" backward-delete-char       # backspace
bindkey "^[[3~" delete-char             # delete
bindkey "^[[1;3D" backward-word         # Alt + arrow-left
bindkey "^[[1;3C" forward-word          # Alt + arrow-right
bindkey "^[^?" vi-backward-kill-word    # Alt + backspace
bindkey "^[[1;33~" kill-word            # Alt + delete
bindkey -M vicmd "^A" beginning-of-line # vi: C-a
bindkey -M vicmd "^E" end-of-line       # vi: C-e

# ==========================================
#  Plugin System
# ==========================================
# Enable completion system
autoload -U compinit
# Use XDG-compliant zcompdump location
compinit -d "$XDG_STATE_HOME/zsh/zcompdump"

### Module Loading ###
# Load modular configurations synchronously to ensure proper plugin order
for config in "$ZDOTDIR"/rc.d/*.zsh; do
    [[ -r "$config" ]] && source "$config"
done

# ==========================================
#  Local Configuration
# ==========================================

### User-specific Settings ###
# Load local configuration if exists (not tracked by git)
[ -f "$ZDOTDIR/.zshrc.local" ] && source "$ZDOTDIR/.zshrc.local"

#########################################################################
# END OF CONFIGURATION
#########################################################################
