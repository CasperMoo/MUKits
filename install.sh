#!/usr/bin/env bash
# mukits-cli installer
# Usage: curl -sL https://xxx/install.sh | bash

set -euo pipefail

# Configuration
REPO_URL="${REPO_URL:-https://github.com/xxx/mukits.git}"
INSTALL_DIR="$HOME/.mukits"

# Detect installed tools or install all
TOOLS_TO_INSTALL="${MUKITS_TOOLS:-mmc}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

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

    # Run tool-specific install hook
    if [[ -f "$tool_install" ]]; then
        bash "$tool_install"
    else
        # Default: install all commands in bin/
        for cmd in "$tool_dir/bin"/*; do
            [[ -f "$cmd" ]] || continue
            local cmd_name="$(basename "$cmd")"
            install_command "$tool" "$cmd_name"
        done
    fi
}

# Main installation
main() {
    log_info "mukits-cli installer"
    echo ""

    # Clone/update repository
    clone_or_update

    # Source shared library
    source_installer_lib

    # Ensure ~/.local/bin
    ensure_local_bin

    # Install tools
    for tool in $TOOLS_TO_INSTALL; do
        install_tool "$tool"
    done

    echo ""
    log_info "Installation complete!"
    echo ""
    echo "Installed commands:"
    for tool in $TOOLS_TO_INSTALL; do
        echo "  - $tool"
    done
    echo ""
    log_warn "Make sure ~/.local/bin is in your PATH"
}

main "$@"
