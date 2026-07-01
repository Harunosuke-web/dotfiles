#########################################################################
# FUNCTIONS - Custom shell functions and widgets
#########################################################################
#
# This file contains custom functions and zsh widgets with keybindings.
# Functions are organized by category for better maintainability.
#
# KEYBINDINGS SUMMARY:
# - Ctrl+Z : fz() - Smart directory jump (z history)
# - Ctrl+B : find_cd() - Local directory search
# - Alt+S : fzf-ghq() - Repository navigation
# - Ctrl+F : tmux session create/switch (popup)
# - Alt+F : tmux sessionizer widget (inline)
# - Ctrl+S : tmux session switch
# - Ctrl+X : tmux session kill
# - Ctrl+E : lf file manager
#
#########################################################################

### Basic utility functions ###

# History filtering + skip failed commands
# 名前で常に除外する汎用/破壊系コマンド（追加したい語はここに足す）
_hist_ignore_re='^(cd|z|which|history|jj?|lazygit|la|ll|ls|rm|rmdir|trash|pwd|clear|exit)($| )'

# zshaddhistory はコマンド実行“前”に走り $? が分からないため、ここでは保存を保留し、
# precmd で終了ステータスを見て「成功したコマンドだけ」履歴に確定する。
zshaddhistory() {
  local line="${1%%$'\n'}"
  [[ "$line" =~ $_hist_ignore_re ]] && return 1   # 名前で除外
  _hist_pending="$line"
  return 1                                         # いったん保存を保留（成功時のみ確定）
}

# 直前コマンドが成功(=0)した時だけ履歴へ確定。$? を最初に確保し、後段(starship等)へ素通しする。
_hist_commit_on_success() {
  local st=$?
  [[ -n "$_hist_pending" && $st -eq 0 ]] && print -sr -- "$_hist_pending"
  _hist_pending=""
  return $st
}

# starship の precmd より先に走らせて真の $? を取るため precmd_functions の先頭へ挿入（多重登録は防止）
(( ${precmd_functions[(Ie)_hist_commit_on_success]} )) || precmd_functions=(_hist_commit_on_success $precmd_functions)

### zsh Widget Functions ###

# Clear screen with prompt update
clear-screen-and-update-prompt() {
    # ALMEL_STATUS=0
    # almel::precmd
    zle .clear-screen
}
zle -N clear-screen clear-screen-and-update-prompt

# History search widget using fzf
widget::history() {
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
    local selected=( "$(history -inr 1 | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --scheme=history ${FZF_CTRL_R_OPTS-} \
        --prompt 'History> ' --exit-0 --query '$LBUFFER'" $(__fzfcmd) | cut -d' ' -f4- | sed 's/\\n/\n/g')" )
    if [ -n "$selected" ]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
    fi
    zle -R -c # refresh screen
}

### ghq Integration Widgets ###

# ghq repository listing with tmux session status
widget::ghq::source() {
    local session color icon green="\e[32m" blue="\e[34m" reset="\e[m" checked="󰄲" unchecked="󰄱"
    local sessions=($(tmux list-sessions -F "#S" 2>/dev/null))

    ghq list | sort | while read -r repo; do
        # Generate session name from last 2 directories (e.g., user/dotfiles)
        session=$(echo "$repo" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}' | sed 's/[:. ]/_/g')
        color="$blue"
        icon="$unchecked"
        if (( ${+sessions[(r)$session]} )); then
            color="$green"
            icon="$checked"
        fi
        printf "$color$icon %s$reset\n" "$repo"
    done
}

# ghq repository selection with fzf
widget::ghq::select() {
    local root="$(ghq root)"
    widget::ghq::source | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --exit-0 --prompt 'Repository> ' \
      --preview='fzf-preview-git ${(q)root}/{+2}' --preview-window='right:50%' " \
      $(__fzfcmd) | cut -d' ' -f2-
}

# Change directory to selected ghq repository
widget::ghq::dir() {
    local selected="$(widget::ghq::select)"
    if [ -z "$selected" ]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    BUFFER="cd ${(q)repo_dir}"
    zle accept-line
    zle -R -c # refresh screen
}

# Create/switch tmux session for selected ghq repository
widget::ghq::session() {
    local selected="$(widget::ghq::select)"
    if [ -z "$selected" ]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    local session_name=$(echo "$selected" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}' | sed 's/[:. ]/_/g')

    if [ -z "$TMUX" ]; then
        BUFFER="tmux new-session -A -s ${(q)session_name} -c ${(q)repo_dir}"
        zle accept-line
    elif [ "$(tmux display-message -p "#S")" = "$session_name" ] && [ "$PWD" != "$repo_dir" ]; then
        BUFFER="cd ${(q)repo_dir}"
        zle accept-line
    else
        tmux new-session -d -s "$session_name" -c "$repo_dir" 2>/dev/null
        tmux switch-client -t "$session_name"
    fi
    zle -R -c # refresh screen
}


### tmux-sessionizer Integration Widgets ###

# tmux-sessionizer directory listing with session status
widget::tmux::sessionizer::source() {
    local sessions=($(tmux list-sessions -F "#S" 2>/dev/null))
    local session color icon green="\e[32m" blue="\e[34m" reset="\e[m" checked="󰄲" unchecked="󰄱"

    # Get search directories from tmux-sessionizer config
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer"
    local config_file="$config_dir/tmux-sessionizer.conf"
    local search_dirs=("$HOME/Repos/github.com/Harunosuke-web" "$HOME/Projects" "$HOME/Dev")

    # Load config if exists
    if [ -f "$config_file" ]; then
        source "$config_file"
        if [ ${#TS_SEARCH_PATHS[@]} -gt 0 ]; then
            search_dirs=("${TS_SEARCH_PATHS[@]}")
        fi
    fi

    # Filter existing directories
    local existing_dirs=()
    for dir in "${search_dirs[@]}"; do
        local expanded_dir="${dir/#\~/$HOME}"
        [ -d "$expanded_dir" ] && existing_dirs+=("$expanded_dir")
    done

    # List directories with session status
    find "${existing_dirs[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | while read -r dir; do
        session="${$(basename "$dir")//[:. ]/-}"
        color="$blue"
        icon="$unchecked"
        if (( ${+sessions[(r)$session]} )); then
            color="$green"
            icon="$checked"
        fi
        printf "$color$icon %s$reset\n" "$dir"
    done
}

# tmux-sessionizer directory selection with fzf
widget::tmux::sessionizer::select() {
    widget::tmux::sessionizer::source | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --exit-0 --prompt 'Directory> ' \
      --preview='
        dir=$(echo {} | cut -d\" \" -f2-)
        echo \"Directory: \$(basename \"\$dir\")\"
        echo \"Path: \$(echo \"\$dir\" | sed \"s|^\$HOME|~|\")\"
        session_name=\$(basename \"\$dir\" | tr \".\" \"_\")
        if tmux has-session -t \"\$session_name\" 2>/dev/null; then
            echo \"Status: 󰄲 Session exists\"
        else
            echo \"Status: 󰄱 New session\"
        fi
        echo \"\"
        if command -v eza >/dev/null 2>&1; then
            echo \"Tree:\"
            eza --tree --level=2 --icons --color=always --group-directories-first --ignore-glob=\".git|node_modules|.DS_Store|*.log\" \"\$dir\" 2>/dev/null || echo \"  (empty or access denied)\"
        else
            echo \"Contents:\"
            ls -la --color=always \"\$dir\" 2>/dev/null | head -10 || echo \"  (empty or access denied)\"
        fi
      ' --preview-window='right:55%' " \
      $(__fzfcmd) | cut -d' ' -f2-
}

# Create/switch tmux session for selected directory
widget::tmux::sessionizer::session() {
    local selected="$(widget::tmux::sessionizer::select)"
    if [ -z "$selected" ]; then
        return
    fi

    local session_name=$(echo "$selected" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}' | sed 's/[:. ]/_/g')

    if [ -z "$TMUX" ]; then
        # Outside tmux: create session and attach (or attach if exists)
        BUFFER="tmux new-session -A -s ${(q)session_name} -c ${(q)selected}"
        zle accept-line
    else
        # Inside tmux: switch or create session
        if tmux has-session -t "$session_name" 2>/dev/null; then
            tmux switch-client -t "$session_name"
        else
            tmux new-session -d -s "$session_name" -c "$selected" 2>/dev/null
            tmux switch-client -t "$session_name"
        fi
    fi
    zle -R -c # refresh screen
}

### Widget Registration ###
zle -N widget::history
zle -N widget::ghq::dir
zle -N widget::ghq::session
zle -N widget::tmux::sessionizer::session

### Cursor shape functions for vi mode ###
# Change the cursor between 'Line' and 'Block' shape
zle-keymap-select() {
    case "${KEYMAP}" in
        main|viins)
            printf '\033[6 q' # line cursor
            ;;
        vicmd)
            printf '\033[2 q' # block cursor
            ;;
    esac
}

zle-line-init() {
    zle-keymap-select
}

zle-line-finish() {
    printf '\033[6 q' # line cursor
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

mkcd() {
    # Create directory and change into it
    command mkdir -p -- "$@" && builtin cd "${@[-1]:a}"
}

#########################################################################
# DIRECTORY NAVIGATION
#########################################################################

### fzf-enhanced navigation ###

fz() {
    # Smart directory jump using zoxide (Ctrl+Z)
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "zoxide not available"
        return 1
    fi

    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null
    local res=$(zoxide query --list --score | sort -nr | awk '{$1=""; print substr($0,2)}' | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-}" \
        $(__fzfcmd) --preview "echo {} | xargs eza \
        --color=always -h --long --icons --classify --git --no-permissions --no-user --no-filesize --git-ignore --sort modified --reverse --tree --level 4")
    if [ -n "$res" ]; then
        BUFFER+="cd $res"
        zle accept-line
    else
        return 1
    fi
}
zle -N fz
bindkey '^Z' fz

find_cd() {
    # Local directory search with fzf (Ctrl+B)
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null
    local selected_dir=("$(fd . --type d | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-} \
        --bind=ctrl-r:toggle-sort,ctrl-z:ignore \
        --exit-0 --query '$LBUFFER'" $(__fzfcmd))")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle -R -c # refresh screen
}
zle -N find_cd
bindkey '^B' find_cd

fzf-ghq() {
    # Repository navigation with ghq (Alt+S)
    local repo=("$(ghq list | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-}" \
        $(__fzfcmd) --prompt 'Repository> ' --preview "ghq list --full-path --exact {} | xargs eza \
        --color=always -h --long --icons --classify --git --no-permissions --no-user --no-filesize --git-ignore --sort modified --reverse --tree --level 4")")
    if [ -n "$repo" ]; then
        repo=$(ghq list --full-path --exact $repo)
        BUFFER="cd ${repo}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N fzf-ghq
bindkey '^[s' fzf-ghq

### Git repository navigation ###

j() {
    # Fuzzy directory jump within git repository
    local root dir
    root="$($(git rev-parse --show-cdup 2>/dev/null):-.)"
    dir="$(fd --color=always --hidden --type=d . "$root" | fzf --select-1 --query="$*" --preview='fzf-preview-directory {}')"
    if [ -n "$dir" ]; then
        builtin cd "$dir"
        echo "$PWD"
    fi
}

jj() {
    # Jump to git repository root
    local root
    root="$(git rev-parse --show-toplevel)" || return 1
    builtin cd "$root"
}

#########################################################################
# BUILD TOOLS - CMake utilities
#########################################################################
cmakeb() {
    # Build project using cmake
    build_dir=${1:-$(git rev-parse --show-toplevel)/build}
    shift || true
    cmake --build "$build_dir" -j"$(($(nproc) + 1))" "$@"
}

cmaket() {
    # Run ctest in specified directory
    test_dir=${1:-$(git rev-parse --show-toplevel)/build}
    shift || true
    ctest --verbose --test-dir "$test_dir" "$@"
}

#########################################################################
# TMUX INTEGRATION - Session management
#########################################################################

tmux-sessionizer-source() {
    # List directories with session status (like widget::ghq::source)
    local session color icon green="\e[32m" blue="\e[34m" reset="\e[m" checked="󰄲" unchecked="󰄱"
    local sessions=($(tmux list-sessions -F "#S" 2>/dev/null))

    # Get search directories
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer"
    local config_file="$config_dir/tmux-sessionizer.conf"
    local search_dirs=("$HOME/Repos/github.com/Harunosuke-web" "$HOME/Projects" "$HOME/Dev")

    # Load config if exists
    if [ -f "$config_file" ]; then
        source "$config_file"
        if [ ${#TS_SEARCH_PATHS[@]} -gt 0 ]; then
            search_dirs=("${TS_SEARCH_PATHS[@]}")
        fi
    fi

    # Filter existing directories
    local existing_dirs=()
    for dir in "${search_dirs[@]}"; do
        local expanded_dir="${dir/#\~/$HOME}"
        [ -d "$expanded_dir" ] && existing_dirs+=("$expanded_dir")
    done

    find "${existing_dirs[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | while read -r dir; do
        # Generate session name from last 2 directories (e.g., user/dotfiles)
        session=$(echo "$dir" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}' | sed 's/[:. ]/_/g')
        color="$blue"
        icon="$unchecked"
        if (( ${+sessions[(r)$session]} )); then
            color="$green"
            icon="$checked"
        fi
        printf "$color$icon %s$reset\n" "$dir"
    done
}

tmux-sessionizer-popup() {
    # tmux-sessionizer as zsh function (similar to fzf-ghq)
    local selected=("$(tmux-sessionizer-source | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --ansi" \
        $(__fzfcmd) --prompt 'Create/switch to session: ' \
        --preview='
            dir=$(echo {} | cut -d" " -f2-)
            echo "Directory: $(basename "$dir")"
            echo "Path: $(echo "$dir" | sed "s|^$HOME|~|")"
            session_name=$(echo "$dir" | awk -F/ '"'"'{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}'"'"' | sed '"'"'s/[:. ]/_/g'"'"')
            if tmux has-session -t "$session_name" 2>/dev/null; then
                echo "Status: 󰄲 Session exists"
            else
                echo "Status: 󰄱 New session"
            fi
            echo ""

            # Check for README files (case-insensitive)
            readme_file=""
            for readme in "$dir"/README.md "$dir"/readme.md "$dir"/README.txt "$dir"/readme.txt "$dir"/README "$dir"/readme; do
                if [ -f "$readme" ]; then
                    readme_file="$readme"
                    break
                fi
            done

            if [ -n "$readme_file" ]; then
                echo "README Preview:"
                echo "──────────────"
                if command -v glow >/dev/null 2>&1; then
                    # Use glow for markdown rendering with GitHub dark theme
                    env TERM=xterm-256color FORCE_COLOR=1 glow "$readme_file" -s auto -w 80 --pager=false | head -30 || cat "$readme_file" | head -30
                elif command -v bat >/dev/null 2>&1; then
                    # Use bat for syntax highlighting
                    bat "$readme_file" --color=always --style=plain --paging=never 2>/dev/null | head -30
                else
                    # Fallback to plain cat
                    cat "$readme_file" 2>/dev/null | head -30
                fi
            else
                if command -v eza >/dev/null 2>&1; then
                    echo "Tree:"
                    eza --tree --level=2 --icons --color=always --group-directories-first --ignore-glob=".git|node_modules|.DS_Store|*.log" "$dir" 2>/dev/null || echo "  (empty or access denied)"
                else
                    echo "Contents:"
                    ls -la --color=always "$dir" 2>/dev/null | head -10 || echo "  (empty or access denied)"
                fi
            fi
        ' --preview-window="right:55%" | cut -d' ' -f2-)")

    if [ -z "$selected" ]; then
        return
    fi

    local session_name=$(echo "$selected" | awk -F'/' '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}' | sed 's/[:. ]/_/g')

    if [ -z "$TMUX" ]; then
        # Outside tmux: create session and attach
        BUFFER="tmux new-session -A -s ${(q)session_name} -c ${(q)selected}"
        zle accept-line
    else
        # Inside tmux: switch or create session
        if tmux has-session -t "$session_name" 2>/dev/null; then
            tmux switch-client -t "$session_name"
        else
            tmux new-session -d -s "$session_name" -c "$selected" 2>/dev/null
            tmux switch-client -t "$session_name"
        fi
    fi
    zle -R -c # refresh screen
}

tmux_sessionizer_popup() {
    # Create or switch tmux session with popup (Ctrl+F)
    tmux-sessionizer-popup
    zle reset-prompt
}
zle -N tmux_sessionizer_popup
bindkey '^F' tmux_sessionizer_popup

tmux-switch-session() {
    # Switch between tmux sessions widget
    local sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort)

    if [ -z "$sessions" ]; then
        echo "No tmux sessions available"
        return 1
    fi

    local current_session=""
    local prompt_text="Attach to session: "
    local header_text="Available sessions"

    if [ -n "$TMUX" ]; then
        current_session=$(tmux display-message -p '#S')
        sessions=$(echo "$sessions" | grep -v "^$current_session$")
        if [ -z "$sessions" ]; then
            echo "No other sessions available to switch to"
            return 1
        fi
        prompt_text="Switch to session: "
        header_text="Current session: $current_session"
    fi

    local selected_session=$(echo "$sessions" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-}" \
        $(__fzfcmd) --prompt="$prompt_text" \
        --header="$header_text" \
        --preview="echo 'Session: {}'; echo 'Windows:'; tmux list-windows -t {} -F '  #{window_index}: #{window_name} (#{pane_current_command})'" \
        --preview-window="right:50%")

    if [ -n "$selected_session" ]; then
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$selected_session"
        else
            BUFFER="tmux attach-session -t ${(q)selected_session}"
            zle accept-line
        fi
    fi
    zle -R -c # refresh screen
}

tmux_switch_session() {
    # Switch between tmux sessions (Ctrl+S)
    tmux-switch-session
    zle reset-prompt
}
zle -N tmux_switch_session
bindkey '^S' tmux_switch_session

tmux-kill-session() {
    # Kill tmux session widget
    local sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort)

    if [ -z "$sessions" ]; then
        echo "No tmux sessions available"
        return 1
    fi

    local current_session=""
    local header_text="Available sessions"

    if [ -n "$TMUX" ]; then
        current_session=$(tmux display-message -p '#S')
        sessions=$(echo "$sessions" | grep -v "^$current_session$")
        if [ -z "$sessions" ]; then
            echo "No other sessions available to delete"
            return 1
        fi
        header_text="Current session: $current_session (protected)"
    fi

    local selected_session=$(echo "$sessions" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-}" \
        $(__fzfcmd) --prompt="Delete session: " \
        --header="$header_text" \
        --preview="echo 'Target: {}'; echo 'Windows:'; tmux list-windows -t {} -F '  #{window_index}: #{window_name} (#{pane_current_command})'" \
        --preview-window="right:50%")

    if [ -n "$selected_session" ]; then
        tmux kill-session -t "$selected_session"
        echo "Session '$selected_session' deleted"
    fi
    zle -R -c # refresh screen
}

tmux_kill_session() {
    # Kill tmux session (Ctrl+X)
    tmux-kill-session
    zle reset-prompt
}
zle -N tmux_kill_session
bindkey '^X' tmux_kill_session

# Alternative tmux sessionizer widget (Alt+F)
zle -N tmux-sessionizer-popup
bindkey '^[f' tmux-sessionizer-popup

#########################################################################
# FILE MANAGEMENT
#########################################################################

### lf file manager integration ###

lf_popup() {
    # Launch lf file manager in tmux popup (Ctrl+E)
    if [ -n "$TMUX" ]; then
        tmux display-popup -w 90% -h 90% -E "~/.local/bin/lf-tmux"
    else
        lf
    fi
    zle reset-prompt
}
zle -N lf_popup
bindkey '^E' lf_popup

lf() {
    # lf wrapper that changes shell directory on exit
    tmp="$(mktemp)"
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ]; then
            if [ "$dir" != "$(pwd)" ]; then
                cd "$dir"
            fi
        fi
    fi
}

### Editor integration ###

e() {
    # Enhanced editor function with fzf file selection
    if [ $# -eq 0 ]; then
        local selected="$(fd --hidden --color=always --type=f  | fzf --exit-0 --multi --preview="fzf-preview-file {}" --preview-window="right:60%")"
        if [ -n "$selected" ]; then
            if [[ "$EDITOR" == "nvim" ]]; then
                VIMINIT= "$EDITOR" -- ${(f)selected}
            else
                "$EDITOR" -- ${(f)selected}
            fi
        fi
    else
        if [[ "$EDITOR" == "nvim" ]]; then
            VIMINIT= "$EDITOR" "$@"
        else
            "$EDITOR" "$@"
        fi
    fi
}

#########################################################################
# DOCKER UTILITIES (commented out)
#########################################################################
# These Docker helper functions are commented out but available if needed.
# Uncomment and modify as required for your Docker workflow.
# docker() {
#     if [ "$#" -eq 0 ] || [ "$1" = "compose" ] || ! command -v "docker-$1" >/dev/null; then
#         command docker "${@:1}"
#     else
#         "docker-$1" "${@:2}"
#     fi
# }

# docker-clean() {
#     command docker ps -aqf status=exited | xargs -r docker rm --
# }
# docker-cleani() {
#     command docker images -qf dangling=true | xargs -r docker rmi --
# }
# docker-rm() {
#     if [ "$#" -eq 0 ]; then
#         command docker ps -a | fzf --exit-0 --multi --header-lines=1 | awk '{ print $1 }' | xargs -r docker rm --
#     else
#         command docker rm "$@"
#     fi
# }
# docker-rmi() {
#     if [ "$#" -eq 0 ]; then
#         command docker images | fzf --exit-0 --multi --header-lines=1 | awk '{ print $3 }' | xargs -r docker rmi --
#     else
#         command docker rmi "$@"
#     fi
# }
