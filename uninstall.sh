#!/usr/bin/env bash
# MUKits Uninstaller

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.mukits"
LOCAL_BIN="$HOME/.local/bin"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

uninstall() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     MUKits 卸载程序                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    # Confirm uninstallation
    read -p "确定要卸载 MUKits 吗？[y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "已取消卸载"
        exit 0
    fi

    echo ""

    # Remove symlink
    if [[ -L "$LOCAL_BIN/mm" || -f "$LOCAL_BIN/mm" ]]; then
        rm -f "$LOCAL_BIN/mm"
        log_info "已删除: $LOCAL_BIN/mm"
    fi

    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        # Ask about config
        local config_file="$INSTALL_DIR/config.json"
        local save_config=""

        if [[ -f "$config_file" ]]; then
            read -p "是否保留配置文件？[Y/n]: " save_config
            if [[ ! "$save_config" =~ ^[Nn]$ ]]; then
                # Backup config
                local backup_file="$HOME/.mukits-config-backup.json"
                cp "$config_file" "$backup_file"
                log_info "配置已备份到: $backup_file"
            fi
        fi

        rm -rf "$INSTALL_DIR"
        log_info "已删除: $INSTALL_DIR"
    fi

    # Check for API keys in shell config
    local shell_config=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    fi

    if [[ -n "$shell_config" ]]; then
        if grep -q "GLM_API_KEY\|DEEPSEEK_API_KEY\|VOLCENGINE_API_KEY\|ALIYUN_API_KEY\|SILICONFLOW_API_KEY\|ANTHROPIC_API_KEY\|OPENROUTER_API_KEY" "$shell_config" 2>/dev/null; then
            echo ""
            read -p "是否从 $shell_config 中移除 API Key？[y/N]: " remove_keys
            if [[ "$remove_keys" =~ ^[Yy]$ ]]; then
                # Create backup
                cp "$shell_config" "${shell_config}.mukits-backup"

                # Remove API key lines
                sed -i.tmp '/export GLM_API_KEY=/d; export DEEPSEEK_API_KEY=/d; export VOLCENGINE_API_KEY=/d; export ALIYUN_API_KEY=/d; export SILICONFLOW_API_KEY=/d; export ANTHROPIC_API_KEY=/d; export OPENROUTER_API_KEY=/d' "$shell_config" 2>/dev/null || true
                rm -f "${shell_config}.tmp"

                log_info "已从 $shell_config 移除 API Keys"
                log_info "备份保存在: ${shell_config}.mukits-backup"
            fi
        fi
    fi

    echo ""
    log_info "卸载完成！"
    echo ""

    if [[ -f "$HOME/.mukits-config-backup.json" ]]; then
        echo "配置备份: $HOME/.mukits-config-backup.json"
        echo "如需恢复，运行: curl -sL https://raw.githubusercontent.com/CasperMoo/MUKits/main/install.sh | bash"
    fi
}

uninstall "$@"
