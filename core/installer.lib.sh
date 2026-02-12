#!/usr/bin/env bash
# mukits-cli installer library
# Shared functions for tool installation

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Ensure ~/.local/bin exists and is in PATH
ensure_local_bin() {
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        log_warn "~/.local/bin not in PATH"
        log_info "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"$local_bin:\$PATH\""
    fi
}

# Create symlink from ~/.mukits/tools/tool/bin/command to ~/.local/bin/command
install_command() {
    local tool_name="$1"
    local command_name="$2"
    local source_dir="$HOME/.mukits/tools/$tool_name/bin"

    local local_bin="$HOME/.local/bin"
    local target="$local_bin/$command_name"
    local source="$source_dir/$command_name"

    # Make source executable
    chmod +x "$source"

    # Remove existing symlink/file
    if [[ -e "$target" || -L "$target" ]]; then
        rm -f "$target"
    fi

    # Create symlink
    ln -s "$source" "$target"
    log_info "Installed: $target -> $source"
}

# Clone or update repository
clone_or_update() {
    local repo_url="${1:-https://github.com/xxx/mukits.git}"
    local install_dir="$HOME/.mukits"

    if [[ -d "$install_dir" ]]; then
        log_info "Updating existing installation..."
        cd "$install_dir"
        git pull --ff-only || {
            log_error "Update failed, please resolve manually"
            return 1
        }
    else
        log_info "Cloning repository..."
        git clone "$repo_url" "$install_dir"
    fi
}
