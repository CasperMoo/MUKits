#!/usr/bin/env bash
# mmc provider definitions

set -euo pipefail

# Provider environment variable mappings
declare -grA PROVIDER_ENV_MAP=(
    ["deepseek"]="DEEPSEEK_API_KEY"
    ["ds"]="DEEPSEEK_API_KEY"
    ["glm"]="GLM_API_KEY"
    ["anthropic"]="ANTHROPIC_API_KEY"
)

# Built-in provider configurations
# Usage: get_provider_config <provider_name> <output_assoc_array>
get_provider_config() {
    local provider_name="$1"
    local -n output_array="$2"

    case "$provider_name" in
        "deepseek"|"ds")
            output_array[base_url]="https://api.deepseek.com/anthropic"
            output_array[model]="deepseek-chat"
            output_array[sonnet]="deepseek/deepseek-v3.2"
            output_array[opus]="deepseek/deepseek-v3.2"
            output_array[haiku]="deepseek/deepseek-v3.2"
            output_array[subagent]="deepseek-chat"
            ;;
        "glm")
            output_array[base_url]="https://open.bigmodel.cn/api/paas/v4/"
            output_array[model]="glm-4"
            output_array[sonnet]="glm-4"
            output_array[opus]="glm-4"
            output_array[haiku]="glm-4"
            output_array[subagent]="glm-4"
            ;;
        "anthropic")
            output_array[base_url]="https://api.anthropic.com"
            output_array[model]="claude-sonnet-4-20250514"
            output_array[sonnet]="claude-sonnet-4-20250514"
            output_array[opus]="claude-opus-4-20250514"
            output_array[haiku]="claude-haiku-4-20250514"
            output_array[subagent]="claude-sonnet-4-20250514"
            ;;
        *)
            echo "Unknown provider: $provider_name" >&2
            return 1
            ;;
    esac

    # Get auth token from environment or config
    local env_var="${PROVIDER_ENV_MAP[$provider_name]:-}"
    if [[ -n "${!env_var:-}" ]]; then
        output_array[auth_token]="${!env_var}"
    else
        output_array[auth_token]=""
    fi
}

# List all available providers
list_providers() {
    echo "Available providers:"
    echo "  deepseek (ds) - DeepSeek API"
    echo "  glm           - GLM (智谱清言) API"
    echo "  anthropic     - Anthropic official API"
}

# Get all provider names
get_all_provider_names() {
    echo "deepseek glm anthropic"
}
