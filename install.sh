#!/usr/bin/env bash
# mukits-cli installer
# Usage: curl -sL https://raw.githubusercontent.com/CasperMoo/MUKits/main/install.sh | bash

set -euo pipefail

# Configuration
REPO_URL="${REPO_URL:-https://github.com/CasperMoo/MUKits.git}"
INSTALL_DIR="$HOME/.mukits"
TOOLS_TO_INSTALL="${MUKITS_TOOLS:-mmc}"
VERSION_URL="https://raw.githubusercontent.com/CasperMoo/MUKits/main/version.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${BLUE}==>${NC} $*"; }

# Check if claude code is installed
check_claude_code() {
    if command -v claude &>/dev/null; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_info "Claude Code already installed: $version"
        return 0
    fi
    return 1
}

# Install Claude Code
install_claude_code() {
    log_step "Installing Claude Code..."

    # Check npm
    if ! command -v npm &>/dev/null; then
        log_error "npm not found. Please install Node.js first:"
        echo "  macOS: brew install node"
        echo "  Linux: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install nodejs"
        exit 1
    fi

    # Try install with official registry first, then fallback to China mirrors
    local registries=(
        "https://registry.npmjs.org/"
        "https://registry.npmmirror.com/"
        "https://mirrors.cloud.tencent.com/npm/"
        "https://npm.aliyun.com/"
    )

    for registry in "${registries[@]}"; do
        log_info "Trying registry: $registry"
        if npm install -g @anthropic-ai/claude-code --registry="$registry" 2>/dev/null; then
            if command -v claude &>/dev/null; then
                log_info "Claude Code installed successfully!"
                return 0
            fi
        fi
        log_warn "Failed with $registry, trying next..."
    done

    log_error "Failed to install Claude Code from all registries"
    echo ""
    echo "Please try manually:"
    echo "  npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com/"
    exit 1
}

# Save version info
save_version_info() {
    local version_file="$INSTALL_DIR/.version"

    # Try to get version from version.json in the repo
    if [[ -f "$INSTALL_DIR/version.json" ]]; then
        local version
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$INSTALL_DIR/version.json" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
        if [[ -n "$version" ]]; then
            echo "$version" > "$version_file"
            log_info "Version: $version"
        fi
    fi
}

# Clone or update repository
clone_or_update() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "Updating existing installation..."
        cd "$INSTALL_DIR"
        git pull --ff-only || {
            log_warn "Update failed, continuing with existing version"
        }
    else
        log_info "Cloning repository to $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
}

# Source installer library
source_installer_lib() {
    local lib_path="$INSTALL_DIR/core/installer.lib.sh"
    if [[ ! -f "$lib_path" ]]; then
        log_error "Installer library not found: $lib_path"
        exit 1
    fi
    source "$lib_path"
}

# Install a tool
install_tool() {
    local tool="$1"
    local tool_dir="$INSTALL_DIR/tools/$tool"
    local tool_install="$tool_dir/install.sh"

    if [[ ! -d "$tool_dir" ]]; then
        log_error "Tool not found: $tool"
        return 1
    fi

    log_info "Installing tool: $tool"

    if [[ -f "$tool_install" ]]; then
        bash "$tool_install"
    else
        for cmd in "$tool_dir/bin"/*; do
            [[ -f "$cmd" ]] || continue
            local cmd_name
            cmd_name="$(basename "$cmd")"
            install_command "$tool" "$cmd_name"
        done
    fi
}

# Main installation
main() {
    # Check for update mode
    local is_update="${1:-}"
    if [[ "$is_update" == "--update" ]]; then
        log_info "Update mode: refreshing installation..."
    fi

    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     MUKits Installer                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Check/Install Claude Code (skip in update mode)
    if [[ "$is_update" != "--update" ]]; then
        log_step "Checking Claude Code..."
        if ! check_claude_code; then
            install_claude_code
        fi
        echo ""
    fi

    # Step 2: Clone/update repository
    log_step "Installing MUKits..."
    clone_or_update

    # Step 3: Save version info
    save_version_info

    # Step 4: Source shared library
    source_installer_lib

    # Step 5: Ensure ~/.local/bin
    ensure_local_bin

    # Step 6: Install tools
    for tool in $TOOLS_TO_INSTALL; do
        install_tool "$tool"
    done

    echo ""
    log_info "Installation complete!"
    echo ""

    # Skip setup prompt in update mode
    if [[ "$is_update" == "--update" ]]; then
        return 0
    fi

    echo "Quick start:"
    echo "  mm          # 启动 Claude Code"
    echo "  mm setup    # 配置向导"
    echo ""

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "~/.local/bin not in PATH. Add to your shell config:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

main "$@"
