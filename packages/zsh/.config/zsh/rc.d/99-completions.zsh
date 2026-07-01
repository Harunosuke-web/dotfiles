### Completion Settings ###
zstyle ':completion:*' menu select=1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

### completion styles ###
# zstyle ':completion:*:default' menu select
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
# zstyle ':completion:*' cache-path $XDG_STATE_HOME/zsh/zcompdump

# Enable tab completion for commands
# setopt AUTO_MENU           # Show completion menu on successive tab presses
# setopt COMPLETE_IN_WORD     # Complete from both ends of a word
# setopt ALWAYS_TO_END        # Move cursor to the end of a completed word
# setopt AUTO_LIST           # Automatically list choices on ambiguous completion

### fzf-tab configuration ###
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# tmux内では補完を別ウィンドウ（ポップアップ）で表示する。tmux外では通常のfzf(インライン)に自動フォールバック。
if [[ -n "$TMUX" ]]; then
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  # popup-min-size を画面より大きくして実質“全画面”に（prefix+C-f 等のポップアップと統一）。
  # 小さめの内容サイズにしたい場合は例えば `80 12` などに下げる。
  zstyle ':fzf-tab:*' popup-min-size 500 500
fi

### Utility functions ###
autoload -Uz zmv                    # Multi-move utility
autoload -Uz zargs                  # Extended xargs

### Completion functions ###
# Load completion functions safely
autoload -Uz _git 2>/dev/null           # Enable git completion
autoload -Uz _npm 2>/dev/null           # Enable npm completion
autoload -Uz _curl 2>/dev/null          # Enable curl completion
autoload -Uz _ssh 2>/dev/null           # Enable ssh completion
autoload -Uz _make 2>/dev/null          # Enable make completion (Makefile targets)
autoload -Uz _tar 2>/dev/null           # Enable tar completion
autoload -Uz _rsync 2>/dev/null         # Enable rsync completion
autoload -Uz _grep 2>/dev/null          # Enable grep completion
autoload -Uz _find 2>/dev/null          # Enable find completion
command -v brew >/dev/null && autoload -Uz _brew 2>/dev/null  # Enable brew completion if available

# ### Handle aliased commands ###
# # For commands that are aliased to other tools, ensure proper completion
# # This section handles cases where aliases override original commands

# # bat (aliased to cat) - use cat completion for bat
# if command -v bat >/dev/null && alias cat >/dev/null 2>&1; then
#     compdef _cat bat
# fi

# # eza (aliased to ls) - use ls completion for eza
# if command -v eza >/dev/null && alias ls >/dev/null 2>&1; then
#     compdef _ls eza
#     # Also handle specific eza aliases
#     compdef _ls la
#     compdef _ls ll
# fi

# # GNU tools on macOS (ggrep, gfind, etc.)
# if [[ "$OSTYPE" == darwin* ]]; then
#     command -v ggrep >/dev/null && alias grep >/dev/null 2>&1 && compdef _grep grep
#     command -v gfind >/dev/null && alias find >/dev/null 2>&1 && compdef _find find
#     command -v gls >/dev/null && compdef _ls gls
#     command -v gcp >/dev/null && alias cp >/dev/null 2>&1 && compdef _cp cp
#     command -v gmv >/dev/null && alias mv >/dev/null 2>&1 && compdef _mv mv
#     command -v grm >/dev/null && alias rm >/dev/null 2>&1 && compdef _rm rm
#     command -v gmkdir >/dev/null && alias mkdir >/dev/null 2>&1 && compdef _mkdir mkdir
#     command -v gdu >/dev/null && alias du >/dev/null 2>&1 && compdef _du du
#     command -v ghead >/dev/null && alias head >/dev/null 2>&1 && compdef _head head
#     command -v gtail >/dev/null && alias tail >/dev/null 2>&1 && compdef _tail tail
#     command -v gsed >/dev/null && alias sed >/dev/null 2>&1 && compdef _sed sed
#     command -v gdirname >/dev/null && alias dirname >/dev/null 2>&1 && compdef _dirname dirname
#     command -v gxargs >/dev/null && alias xargs >/dev/null 2>&1 && compdef _xargs xargs
# fi

# # trash (aliased to rm)
# if command -v trash >/dev/null && alias rm >/dev/null 2>&1; then
#     compdef _rm trash
# fi

# # mise (aliased to asdf)
# if command -v mise >/dev/null && alias asdf >/dev/null 2>&1; then
#     compdef _asdf asdf 2>/dev/null || true
# fi

### Initialize completion system ###
# NOTE: compinit is already initialized in .zshrc
# Load zinit completion safely
if [[ -f "${ZINIT[HOME_DIR]}/completions/_zinit" ]]; then
    autoload -Uz _zinit
    (( ${+_comps} )) && _comps[zinit]=_zinit
fi
