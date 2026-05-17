# dotfiles

個人用macOS環境のdotfiles設定（Linuxでも限定的に対応）/ Personal dotfiles setup (Primary: macOS, Limited: Linux)

Managed by:

- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle) - Package management and dependency installation
- [GNU stow](https://www.gnu.org/software/stow/) - Symlink management for dotfiles
- [zinit](https://github.com/zdharma-continuum/zinit) - Fast zsh plugin manager
- [mise](https://github.com/jdx/mise) - Runtime version management (Node.js, Python, etc.)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Harunosuke-web/dotfiles/main/install.sh | sh
```

## Details

詳細なセットアップ手順、カスタマイズ方法、利用可能なスクリプトについては [SETUP.md](SETUP.md) をご覧ください。

For detailed setup instructions, customization options, and available scripts, see [SETUP.md](SETUP.md).

## 主な機能 / Key Features

- ✅ **自動バックアップ**: 既存設定の安全な保護
- ✅ **エラーハンドリング**: 詳細なエラー報告と復旧支援
- ✅ **冪等性**: 何度実行しても安全
- ✅ **グローバルスクリプト**: セットアップスクリプトをどこからでも実行可能
- ✅ **XDG準拠**: 標準的なディレクトリ構成に対応
- ✅ **統合更新システム**: `update`コマンドで選択的・一括パッケージ更新
- ✅ **zsh補完機能**: タブキーでコマンドオプション・引数の自動補完
- ✅ **manページ対応**: `man update`等でコマンドマニュアル表示
