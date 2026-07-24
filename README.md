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

### セットアップモード / Setup Modes

`BOOTSTRAP_MODE`環境変数を付けると、対話プロンプトなしでモードを指定できる:

```bash
# [1] フルセットアップ（新しいMacの初回構築はこれ）
BOOTSTRAP_MODE=1 curl -fsSL https://raw.githubusercontent.com/Harunosuke-web/dotfiles/main/install.sh | sh

# [2] 更新のみ（Homebrew・mise・シンボリックリンクの再実行）
BOOTSTRAP_MODE=2 curl -fsSL https://raw.githubusercontent.com/Harunosuke-web/dotfiles/main/install.sh | sh

# [3] リポジトリの更新のみ（セットアップはスキップ）
BOOTSTRAP_MODE=3 curl -fsSL https://raw.githubusercontent.com/Harunosuke-web/dotfiles/main/install.sh | sh
```

> **新しいMacでの注意**
>
> - 実行前に **App Store にサインイン**しておくと`mas`製アプリのインストールまで一括で成功する
>   （未サインインでも他のセットアップは継続され、あとから `brew bundle install` で再試行できる）
> - Homebrew本体のインストール時に**管理者パスワード**の入力を求められる
> - 完了後、環境の健全性は `doctor.sh` で確認できる

## Details

詳細なセットアップ手順、カスタマイズ方法、利用可能なスクリプトについては [docs/SETUP.md](docs/SETUP.md) をご覧ください。

For detailed setup instructions, customization options, and available scripts, see [docs/SETUP.md](docs/SETUP.md).

## 手動セットアップ / Manual Setup

スクリプト実行後に**GUI操作が必要**な項目。スクリプトでは自動化できない（アクティベーション・
ライセンス認証・システム権限の許可など、OSがユーザーの明示的な操作を要求するもの）。

### 1. システム権限の許可

初回起動時にダイアログが出るので許可する。**許可しないとアプリが黙って動かない。**

| アプリ | 必要な権限 | 場所 |
| --- | --- | --- |
| yabai / skhd | アクセシビリティ | システム設定 > プライバシーとセキュリティ > アクセシビリティ |
| CleanShot X | 画面収録 | 同上 > 画面収録 |
| BetterTouchTool | アクセシビリティ・入力監視 | 同上 |
| Hammerspoon | アクセシビリティ | 同上 |

yabaiはスクリプトでインストールされるが、**サービスの起動は手動**:

```bash
yabai --start-service
skhd --start-service
```

### 2. ライセンス認証 / アクティベート

- **CleanShot X** — ライセンスキーを入力
- **BetterTouchTool** — ライセンスキーを入力
- **1Password** — アカウントにサインイン

### 3. CleanShot X の設定（重要）

CleanShotは`Cmd+Shift+3/4/5`を**macOS純正から奪う**（symbolichotkeysを無効化する）。
そのため**CleanShotが起動していないとスクリーンショットが一切撮れない**状態になる。
Preferences で以下2つを必ず設定すること:

- **General > Launch CleanShot X at login** を有効化（未設定だと上記の状態に陥る）
- **General > Save to** で保存先を指定（例: Google Drive の `マイドライブ/Screenshot`）
  - `macos-defaults.sh`が設定するのは**macOS純正の**保存先で、CleanShot使用中は効かない

### 4. 1Password CLI

SSH鍵の署名・認証を1Passwordエージェントに任せているため、CLI連携が必要:

- 1Passwordアプリ > 設定 > 開発者 > **「1Password CLIと連携」**を有効化
- 同 > **「SSHエージェントを使用」**を有効化
- 連携後、`op whoami` で確認できる

### 5. その他

- **App Store にサインイン** — `mas`によるアプリインストールに必要（セットアップ前が理想）
- **再ログイン** — トラックパッド・キーボード・Caps Lockの設定は再ログイン後に反映される

## 主な機能 / Key Features

- ✅ **自動バックアップ**: 既存設定の安全な保護
- ✅ **エラーハンドリング**: 詳細なエラー報告と復旧支援
- ✅ **冪等性**: 何度実行しても安全
- ✅ **グローバルスクリプト**: セットアップスクリプトをどこからでも実行可能
- ✅ **XDG準拠**: 標準的なディレクトリ構成に対応
- ✅ **統合更新システム**: `update`コマンドで選択的・一括パッケージ更新
- ✅ **zsh補完機能**: タブキーでコマンドオプション・引数の自動補完
- ✅ **manページ対応**: `man update`等でコマンドマニュアル表示
