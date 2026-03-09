#!/usr/bin/env bash
# mmc installation hook

set -euo pipefail

# Source core installer library
source "$(dirname "${BASH_SOURCE[0]}")/../../core/installer.lib.sh"

# Install mm command
install_command "mmc" "mm"

echo ""
echo -e "${GREEN}✓ MM 安装完成！${NC}"
echo ""

# Ask if user wants to setup now
read -p "现在要进行配置吗？[Y/n]: " setup_now
if [[ ! "$setup_now" =~ ^[Nn]$ ]]; then
    exec ~/.local/bin/mm setup
fi
