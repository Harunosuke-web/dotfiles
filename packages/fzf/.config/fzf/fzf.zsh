# Setup fzf
# ---------
if [[ ! "$PATH" == *"$FZF_HOME"/bin* ]]; then
    PATH="${PATH:+${PATH}:}"$FZF_HOME"/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$FZF_HOME/shell/completion.zsh" 2>/dev/null

# Key bindings
# ------------
source "${XDG_CONFIG_HOME}/fzf/fzf-key-bindings.zsh"

#########################################################################
# settings
#########################################################################
export FZF_COMPLETION_TRIGGER='**' # default: '**'
export FZF_TMUX=1
# export FZF_DEFAULT_COMMAND='fd --hidden --color=always'
export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git/*' -g '!node_modules/*'"

### --- 配色 --- ###
# 指定しないと fzf は端末の 16 色を使う。ghostty の palette は Alacritty から
# 移植したもので純緑 #00ff00 などが入っており、プレビュー（bat の GitHub Dark）
# と系統が合わない。テーマ側の値を拾って揃える。
#
# bg は指定しない（-1 = 端末の背景のまま）。tmux のポップアップは端末の
# 背景色がそのまま出るので、ペインとの区別がここで生まれる。
__FZF_COLORS="--color=fg:#959da5,bg:-1,hl:#79b8ff"
__FZF_COLORS+=",fg+:#f6f8fa,bg+:#2f363d,hl+:#79b8ff"
__FZF_COLORS+=",info:#959da5,prompt:#79b8ff,pointer:#ea4a5a"
__FZF_COLORS+=",marker:#7bcc72,spinner:#b392f0,header:#959da5"
__FZF_COLORS+=",border:#444d56,preview-bg:-1"

### --- キー割り当ての方針 --- ###
# ctrl-n/p は候補の選択移動（fzf の既定）のまま触らない。Vim で
# <C-n>/<C-p> が補完候補の next/previous であること、nvim 側の fzf-lua も
# 既定のままであることと揃う。以前はここでプレビューのページ送りに
# 潰しており、FZF_DEFAULT_OPTS が nvim にも漏れて fzf-lua で候補を
# 動かせなくなる事故が起きた。
#
# プレビューのページ送りは ctrl-u/d。Vim の半ページスクロールと同じで、
# nvim の fzf-lua（lua/plugins/finder.lua）でも同じキーにしてある。

### --- FZF_TMUX_OPTS, FZF_DEFAULT_OPTS --- ###
if [[ -n ${TMUX-} ]]; then
    __FZF_CMD="fzf-tmux"
    __FZF_CMD_OPTS=(
        -p
        90%
    )

    export FZF_DEFAULT_OPTS="$(
        cat <<"EOF"
--preview '
  ( (type bat > /dev/null) &&
    bat --color=always --line-range :200 {} \
    || (cat {} | head -200) ) 2> /dev/null
'
EOF
    ) \
        --layout=reverse --border --ansi \
        $__FZF_COLORS \
        --preview-window 'right,50%,nowrap' \
        --header 'Ctrl-\: Toggle Preview | Ctrl-U/D: Page Up/Down' \
        --bind 'Ctrl-\:toggle-preview' \
        --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"

    # export FZF_TMUX_OPTS="-p 90% -y45"
    # 幅・高さの両方を指定して中央90%で表示（幅だけ指定だと高さが半端で上寄りになる）。
    # fzfピッカー（fz/find_cd/ghq/セッション切替・削除/履歴/^Fセッション選択）に効く。
    export FZF_TMUX_OPTS="-p 90%,90%"

else

    __FZF_CMD="fzf"
    __FZF_CMD_OPTS=()

    export FZF_DEFAULT_OPTS="$(
        cat <<"EOF"
    --preview '
          ( (type bat > /dev/null) &&
            bat --color=always --line-range :200 {} \
            || (cat {} | head -200) ) 2> /dev/null
        '
EOF
    ) \
                --height 100% --layout=reverse --border --ansi \
                $__FZF_COLORS \
                --preview-window 'right,50%,nowrap' \
                --header 'Ctrl-\: Toggle Preview | Ctrl-U/D: Page Up/Down' \
                --bind 'ctrl-\:change-preview-window(hidden|)' \
                --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"
fi

### --- alias --- ###
alias fzf="$(__fzfcmd) ${FZF_DEFAULT_OPTS-} --preview-window 'hidden'"

### --- options --- ###
export FZF_CTRL_R_OPTS=$(
    cat <<"EOF"
--preview '
  echo {} \
  | awk "{ sub(/^[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+/, \"\"); gsub(/\\\\n/, \"\\n\"); print }" \
  | bat --color=always --language=sh --style=plain
'
--preview-window 'down,30%,hidden,wrap'
EOF
)

local find_ignore="find ./ -type d \( -name '.git' -o -name 'node_modules' \) -prune -o -type"

export FZF_CTRL_T_COMMAND=$(
    cat <<"EOF"
( (type fd > /dev/null) &&
  fd --type f \
    --strip-cwd-prefix \
    --hidden \
    --exclude '{.git,node_modules}/**' ) \
  || ( (type rg > /dev/null) &&
    rg --files --hidden -g '!.git/*' -g '!node_modules/*' ) \
  || $find_ignore f -print 2> /dev/null
EOF
)
export FZF_CTRL_T_OPTS=$(
    cat <<"EOF"
--preview '
  ( (type bat > /dev/null) &&
    bat --color=always \
      --line-range :200 {} \
    || (cat {} | head -200) ) 2> /dev/null
'
--preview-window 'right,50%,nowrap'
EOF
)

export FZF_ALT_C_COMMAND=$(
    cat <<"EOF"
( (type fd > /dev/null) &&
  fd --type d \
    --strip-cwd-prefix \
    --hidden \
    --exclude '{.git,node_modules}/**' ) \
  || $find_ignore d -print 2> /dev/null
EOF
)
export FZF_ALT_C_OPTS="--preview 'eza --tree -L 3 {} | head -200'"

# Note: fzf functions have been moved to ~/.config/zsh/rc.d/02-functions.zsh
# This file now contains only fzf configuration and settings
