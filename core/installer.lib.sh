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

# Add PATH to shell config file if not already present
add_to_shell_config() {
    local config_file="$1"
    local path_entry='export PATH="$HOME/.local/bin:$PATH"'
    local config_dir
    config_dir=$(dirname "$config_file")

    # Check if already present in file
    if [[ -f "$config_file" ]] && grep -qF '.local/bin' "$config_file" 2>/dev/null; then
        return 0
    fi

    # Check if we can write
    if [[ -f "$config_file" ]]; then
        if [[ ! -w "$config_file" ]]; then
            log_warn "Cannot write to $config_file (permission denied)"
            echo "  Please manually add: $path_entry"
            return 1
        fi
    else
        if [[ ! -w "$config_dir" ]]; then
            log_warn "Cannot create $config_file (permission denied)"
            echo "  Please manually add: $path_entry"
            return 1
        fi
    fi

    # Write to file
    {
        echo ""
        echo "# Added by MUKits installer"
        echo "$path_entry"
    } >> "$config_file" 2>/dev/null && log_info "Added ~/.local/bin to $config_file"
}

# Ensure ~/.local/bin exists and is in PATH
ensure_local_bin() {
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        log_warn "~/.local/bin not in PATH, adding to shell configs..."

        # Add to bash config (use .bash_profile on macOS, .bashrc on Linux)
        if [[ "$(uname -s)" == "Darwin" ]]; then
            add_to_shell_config "$HOME/.bash_profile"
        else
            add_to_shell_config "$HOME/.bashrc"
        fi

        # Add to zsh config
        add_to_shell_config "$HOME/.zshrc"

        log_info "Please restart your terminal or run: source ~/.zshrc (or ~/.bash_profile)"
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
