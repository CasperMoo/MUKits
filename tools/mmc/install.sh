#!/usr/bin/env bash
# mmc installation hook

set -euo pipefail

# Source core installer library
source "$(dirname "${BASH_SOURCE[0]}")/../../core/installer.lib.sh"

# Install mmc command
install_command "mmc" "mmc"

echo "  mmc installed!"
echo "  Run 'mmc help' to get started"
echo "  Config file: ~/.mukits/config.json"
