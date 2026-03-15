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
# Returns: 0 on success, 1 on failure
add_to_shell_config() {
    local config_file="$1"
    local path_entry='export PATH="$HOME/.local/bin:$PATH"'
    local config_dir
    config_dir=$(dirname "$config_file")

    # Check if already present in file
    if [[ -f "$config_file" ]] && grep -qF '.local/bin' "$config_file" 2>/dev/null; then
        log_info "~/.local/bin already in $config_file"
        return 0
    fi

    # Check if we can write
    if [[ -f "$config_file" ]]; then
        if [[ ! -w "$config_file" ]]; then
            return 1
        fi
    else
        if [[ ! -w "$config_dir" ]]; then
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

        local bash_config="$HOME/.bashrc"
        [[ "$(uname -s)" == "Darwin" ]] && bash_config="$HOME/.bash_profile"
        local zsh_config="$HOME/.zshrc"
        local failed=0

        # Add to bash config
        if ! add_to_shell_config "$bash_config"; then
            failed=1
        fi

        # Add to zsh config
        if ! add_to_shell_config "$zsh_config"; then
            failed=1
        fi

        if [[ $failed -eq 1 ]]; then
            echo ""
            log_warn "Failed to write some config files. Please run this command:"
            echo ""
            # Use variable expansion for bash_config path
            echo -e "${GREEN}  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' | tee -a $bash_config ~/.zshrc > /dev/null && source ~/.zshrc${NC}"
            echo ""
        else
            log_info "Please restart your terminal or run: source ~/.zshrc (or ~/.bash_profile)"
        fi
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
