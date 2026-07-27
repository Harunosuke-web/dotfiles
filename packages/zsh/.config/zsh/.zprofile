#########################################################################
# ZSH CONFIGURATION - LOGIN SHELL (PATH / ログイン時セットアップ)
#########################################################################
#
# ログインシェルで一度だけ実行される（macOS では新規タブ/ウィンドウも毎回ログイン扱い）。
# PATH の確定はここに集約する。/etc/zprofile の path_helper の "後" に走るため、
# ここで前方に置いたユーザーディレクトリが確実に優先される。
#
# 対話専用の設定（キーバインド・補完・プロンプト・setopt 等）は .zshrc へ。
# スクリプトからも要る env（XDG / ZDOTDIR / 各ツールの位置）は .zshenv へ。
#########################################################################

### PATH Configuration ###
typeset -U path

path=(
  "$HOME/.local/bin"(N-/)       # User binaries (highest priority)
  "$NPM_DATA_DIR/bin"(N-/)      # npm install -g の実行ファイル置き場
  "$path[@]"                    # Existing PATH (path_helper 由来のシステムパス等)
  "/opt/homebrew/bin"(N-/)      # Homebrew binaries
  "/opt/homebrew/sbin"(N-/)     # Homebrew system binaries
  "/Library/Apple/usr/bin"(N-/) # Apple developer tools
)
