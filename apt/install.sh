#!/bin/sh -e
ubuntu_version="$(lsb_release -r | awk '{print $2 * 100}')"

add-apt-repository -y ppa:git-core/ppa
apt-get update
apt-get upgrade -y

# Core development and system packages
apt-get install -y \
    autoconf \                # Automatic configure script builder
    bat \                     # Cat clone with syntax highlighting
    build-essential \         # Essential build tools (gcc, make, etc.)
    ca-certificates \         # Common CA certificates for SSL/TLS verification
    clang \                   # C, C++ and Objective-C compiler
    clangd \                  # C/C++ language server for LSP
    clang-format \            # Code formatter for C/C++/Java/JavaScript/etc.
    cmake \                   # Cross-platform build system
    curl \                    # Command line tool for transferring data with URLs
    direnv \                  # Environment switcher for the shell
    fd-find \                 # Simple, fast and user-friendly alternative to find
    fzf \                     # Command-line fuzzy finder
    gdb \                     # GNU debugger for C/C++ programs
    git \                     # Distributed version control system
    git-lfs \                 # Git extension for versioning large files
    gpg \                     # GNU Privacy Guard - encryption and signing
    htop \                    # Interactive process viewer (better than top)
    jq \                      # Lightweight and flexible command-line JSON processor
    libsqlite3-dev \          # SQLite 3 development files
    libssl-dev \              # Secure Sockets Layer toolkit - development files
    moreutils \               # Additional Unix utilities (sponge, parallel, etc.)
    neovim \                  # Hyperextensible Vim-based text editor
    openssh-client \          # Secure shell (SSH) client, for secure access to remote machines
    parallel \                # Build and execute shell command lines in parallel
    python3 \                 # Interactive high-level object-oriented language (version 3.x)
    python3-dev \             # Header files and static library for Python (version 3.x)
    python3-pip \             # Python package installer
    python3-pynvim \          # Python3 library for scripting Neovim
    python3-venv \            # Python virtual environment creator
    ripgrep \                 # Recursively searches directories for regex patterns
    rsync \                   # Fast, versatile, remote (and local) file-copying tool
    shellcheck \              # Shell script analysis tool
    sqlite3 \                 # Command line interface for SQLite 3
    stow \                    # Organizer for /usr/local software packages (dotfiles manager)
    tmux \                    # Terminal multiplexer
    tree \                    # Displays directories as trees (with optional color/HTML output)
    unzip \                   # De-archiver for .zip files
    valgrind \                # Instrumentation framework for building dynamic analysis tools
    wget \                    # Retrieves files from the web
    zip \                     # Archiver for .zip files
    zsh                       # Shell with lots of features

# Docker installation
curl -fsSL 'https://download.docker.com/linux/ubuntu/gpg' | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli

# Note about additional tools not available in default repositories
echo ""
echo "📌 Note: Some tools from your Mac environment require manual installation:"
echo ""
echo "• 'eza' (modern ls replacement):"
echo "   1. Visit: https://github.com/eza-community/eza/releases"
echo "   2. Download the appropriate .deb file for your architecture"
echo "   3. Install with: sudo dpkg -i eza_*.deb"
echo "   Alternative: Use 'exa' if available: sudo apt install exa"
echo ""
echo "• 'lf' (terminal file manager):"
echo "   1. Visit: https://github.com/gokcehan/lf/releases"
echo "   2. Download the Linux tar.gz file"
echo "   3. Extract and copy binary to /usr/local/bin/:"
echo "      tar -xzf lf-*.tar.gz && sudo mv lf /usr/local/bin/"
echo "   Alternative: Install via snap: sudo snap install lf"
echo ""