#!/usr/bin/env bash
# mmc config file handling

set -euo pipefail

# Config file location
MMC_CONFIG_DIR="${MMC_CONFIG_DIR:-$HOME/.mukits}"
MMC_CONFIG_FILE="$MMC_CONFIG_DIR/config.toml"

# Initialize config file if not exists
init_config() {
    if [[ ! -f "$MMC_CONFIG_FILE" ]]; then
        mkdir -p "$MMC_CONFIG_DIR"
        cat > "$MMC_CONFIG_FILE" << 'TOML'
# mukits-cli configuration

[mmc]
default_provider = "deepseek"
interactive_fallback = true

# Provider configurations
# auth_token can be left empty to use environment variables
[providers.deepseek]
name = "deepseek"
base_url = "https://api.deepseek.com/anthropic"
auth_token = ""  # Uses $DEEPSEEK_API_KEY if empty
model = "deepseek-chat"
sonnet = "deepseek/deepseek-v3.2"
opus = "deepseek/deepseek-v3.2"
haiku = "deepseek/deepseek-v3.2"
subagent = "deepseek-chat"

[providers.glm]
name = "glm"
base_url = "https://open.bigmodel.cn/api/paas/v4/"
auth_token = ""  # Uses $GLM_API_KEY if empty
model = "glm-4"
sonnet = "glm-4"
opus = "glm-4"
haiku = "glm-4"
subagent = "glm-4"
TOML
        echo "Initialized config: $MMC_CONFIG_FILE"
    fi
}

# Simple TOML value reader (basic implementation)
# Usage: get_toml_value <key_path>
get_toml_value() {
    local key="$1"
    local section="${key%%.*}"
    local field="${key#*.}"

    # Parse with awk (basic TOML subset)
    awk -v section="[$section]" -v field="$field" '
    BEGIN { in_section = 0 }
    /^\[/ {
        if ($0 == section) { in_section = 1 }
        else { in_section = 0 }
    }
    /^$/ || /^#/ { next }
    in_section && $1 == field {
        # Extract value after =
        sub(/^[^=]*=\s*/, "")
        # Remove surrounding quotes (both single and double)
        gsub(/^["'"'"']/, "")
        gsub(/["'"'"']$/, "")
        print
        exit
    }
    ' "$MMC_CONFIG_FILE"
}

# Set TOML value
# Usage: set_toml_value <key_path> <value>
set_toml_value() {
    local key="$1"
    local value="$2"
    local section="${key%%.*}"
    local field="${key#*.}"

    # Create temp file
    local tmp_file="${MMC_CONFIG_FILE}.tmp"

    awk -v section="[$section]" -v field="$field" -v value="$value" '
    BEGIN { in_section = 0; updated = 0 }
    /^\[/ {
        if ($0 == section) { in_section = 1 }
        else { in_section = 0 }
        print
        next
    }
    in_section && !updated && $1 == field {
        print field " = \"" value "\""
        updated = 1
        next
    }
    { print }
    END {
        if (!updated && in_section == 0) {
            print "\n" section
            print field " = \"" value "\""
        }
    }
    ' "$MMC_CONFIG_FILE" > "$tmp_file"

    mv "$tmp_file" "$MMC_CONFIG_FILE"
}

# Ensure API key is available (prompt if needed)
# Usage: ensure_auth_token <provider_name>
ensure_auth_token() {
    local provider="$1"

    # Source provider definitions
    source "$(dirname "${BASH_SOURCE[0]}")/provider.sh"

    local env_var
    env_var="$(get_provider_env_var "$provider")"

    # Check environment variable
    if [[ -n "${!env_var:-}" ]]; then
        echo "${!env_var}"
        return 0
    fi

    # Check config file
    local from_config
    from_config="$(get_toml_value "providers.$provider.auth_token" 2>/dev/null || true)"
    if [[ -n "$from_config" ]]; then
        echo "$from_config"
        return 0
    fi

    # Prompt user
    echo ""
    echo "⚠️  API Key 未配置: $provider"
    echo "   环境变量: $env_var"
    echo ""
    read -p "请输入 API Key: " -r user_key
    [[ -z "$user_key" ]] && return 1

    # Ask to save
    read -p "保存到配置文件？[y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_toml_value "providers.$provider.auth_token" "$user_key"
        echo "✓ 已保存到 $MMC_CONFIG_FILE"
    fi

    echo "$user_key"
}
