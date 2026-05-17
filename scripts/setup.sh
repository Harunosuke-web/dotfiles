#!/usr/bin/env bash

# shellcheck source=./scripts/common.sh
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/utils.sh"

# Setup error handling
setup_error_handling

# Execute setup scripts in order
/bin/bash "$CUR_DIR/setup-local-config.sh" # ローカル設定（環境変数等）
/bin/bash "$CUR_DIR/setup-homebrew.sh"
/bin/bash "$CUR_DIR/setup-apt.sh"
/bin/bash "$CUR_DIR/../bin/setup-links.sh"
/bin/bash "$CUR_DIR/macos-defaults.sh"
/bin/bash "$CUR_DIR/setup-mise.sh"
/bin/bash "$CUR_DIR/setup-zinit.sh"
# /bin/bash "$CUR_DIR/setup-nvim.sh"
/bin/bash "$CUR_DIR/setup-login.sh"

echo ✨ All Done!
