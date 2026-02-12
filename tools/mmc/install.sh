#!/usr/bin/env bash
# mmc installation hook

set -euo pipefail

# Source core installer library
source "$(dirname "${BASH_SOURCE[0]}")/../../core/installer.lib.sh"

# Install mmc command
install_command "mmc" "mmc"

# Initialize config
bash -c 'source "$HOME/.mukits/mmc/lib/config.sh" && init_config'

echo "  mmc installed!"
echo "  Run 'mmc' to get started"
