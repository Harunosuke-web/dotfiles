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

    # 幅・高さの両方を指定して中央90%で表示（幅だけ指定だと高さが半端で上寄りになる）。
    # fzfピッカー（fz/find_cd/ghq/セッション切替・削除/履歴/^Fセッション選択）に効く。
    #
    # -y はステータスラインを除いた領域の中央に置く。既定では上1行・下4行
    # と上に寄っていた（53行の画面の場合）。
    #
    # 注意が2つある。
    #
    #   1. tmux の -y は popup の「下端」の行を指す（-x は左端）。上端を
    #      渡すと popup が画面に収まらず、上端へ押し戻されて無視される。
    #   2. popup_height は -y の評価時点ではまだ空。-h と同じ 90% から
    #      自分で出す。
    #
    #   上端 = 1 + (client_height - 1 - popup_height) / 2
    #   下端 = 上端 + popup_height
    #
    # 画面の大きさが変わっても tmux が計算し直す。先頭の 1 は
    # ステータスラインの行数で、status-position top が前提
    __FZF_POPUP_H='#{e|/:#{e|*:#{client_height},90},100}'
    __FZF_POPUP_TOP="#{e|+:1,#{e|/:#{e|-:#{e|-:#{client_height},1},${__FZF_POPUP_H}},2}}"
    export FZF_TMUX_OPTS="-p 90%,90% -y#{e|+:${__FZF_POPUP_TOP},${__FZF_POPUP_H}}"

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

### --- fzf 本体 --- ###
# 素の fzf も tmux の popup で開き、プレビューは畳んでおく。
#
# エイリアスにはしない。zsh はエイリアスを解析時に展開するため、本体に
# 改行やブレースが入っていると、`| fzf ...` を書いたファイルを読み直した
# 時にその位置へ差し込まれて構文が壊れる。
#
#   02-functions.zsh:4: parse error near `}'
#   02-functions.zsh:5: unmatched "
#
# 実際に2つ入っていた。FZF_DEFAULT_OPTS（ヒアドキュメント由来で改行入り）と、
# FZF_TMUX_OPTS の -y#{e|...}（{a,b} はブレース展開の対象）。起動時は
# 02-functions.zsh の方が先に読まれてエイリアスがまだ無いため、source し
# 直した時だけ表面化していた。
#
# 関数なら本体は解析対象にならないので、どちらも安全に扱える。
# FZF_DEFAULT_OPTS は export してあり fzf 自身が読むので渡さない。
# __fzfcmd は "fzf-tmux <オプション> -- " のように複数語を返すため分割する。
# command を通すのは、TMUX の外で __fzfcmd が "fzf" を返した時に
# この関数自身を呼んで無限に回るのを避けるため
fzf() {
  local -a cmd
  cmd=( ${=$(__fzfcmd)} )
  command "${cmd[@]}" --preview-window 'hidden' "$@"
}

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
