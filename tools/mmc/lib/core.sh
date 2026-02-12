#!/usr/bin/env bash
# mmc core functions - environment variable exports

set -euo pipefail

# Unset all Anthropic environment variables
unset_anthropic_vars() {
    unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN \
          ANTHROPIC_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
          ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL \
          CLAUDE_CODE_SUBAGENT_MODEL 2>/dev/null || true
}

# Emit environment variable exports for a provider
# Usage: emit_env_exports <provider_name>
emit_env_exports() {
    local provider_name="$1"

    # Source provider config to get values
    source "$(dirname "${BASH_SOURCE[0]}")/provider.sh"

    # Get provider config (using set -k to avoid unbound variable errors)
    set +u
    local base_url model auth_token sonnet opus haiku subagent
    case "$provider_name" in
        "deepseek"|"ds")
            base_url="https://api.deepseek.com/anthropic"
            model="deepseek-chat"
            sonnet="deepseek/deepseek-v3.2"
            opus="deepseek/deepseek-v3.2"
            haiku="deepseek/deepseek-v3.2"
            subagent="deepseek-chat"
            ;;
        "glm")
            base_url="https://open.bigmodel.cn/api/paas/v4/"
            model="glm-4"
            sonnet="glm-4"
            opus="glm-4"
            haiku="glm-4"
            subagent="glm-4"
            ;;
        "anthropic")
            base_url="https://api.anthropic.com"
            model="claude-sonnet-4-20250514"
            sonnet="claude-sonnet-4-20250514"
            opus="claude-opus-4-20250514"
            haiku="claude-haiku-4-20250514"
            subagent="claude-sonnet-4-20250514"
            ;;
        *)
            echo "Unknown provider: $provider_name" >&2
            return 1
            ;;
    esac
    set -u

    # Get auth token from environment or config
    set +u  # Temporarily disable for env var check
    local env_var
    env_var="$(get_provider_env_var "$provider_name")"
    if [[ -n "$env_var" && -n "${!env_var:-}" ]]; then
        auth_token="${!env_var}"
    else
        auth_token=""
    fi
    set -u

    # First unset old variables
    printf "unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN "
    printf "ANTHROPIC_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL "
    printf "ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL "
    printf "CLAUDE_CODE_SUBAGENT_MODEL\n"

    # Export each variable
    echo "export ANTHROPIC_BASE_URL='$base_url'"
    echo "export ANTHROPIC_AUTH_TOKEN='$auth_token'"
    echo "export ANTHROPIC_MODEL='$model'"
    echo "export ANTHROPIC_DEFAULT_SONNET_MODEL='$sonnet'"
    echo "export ANTHROPIC_DEFAULT_OPUS_MODEL='$opus'"
    echo "export ANTHROPIC_DEFAULT_HAIKU_MODEL='$haiku'"
    echo "export CLAUDE_CODE_SUBAGENT_MODEL='$subagent'"
}

# Set environment variables in current shell
# Usage: set_provider_env <provider_name>
set_provider_env() {
    local provider_name="$1"
    local exports
    exports="$(emit_env_exports "$provider_name")"
    eval "$exports"
}

# Show current provider status
show_status() {
    echo "Current Claude Code configuration:"
    echo ""

    local base_url="${ANTHROPIC_BASE_URL:-<not set>}"
    local model="${ANTHROPIC_MODEL:-<not set>}"

    echo "  Base URL: $base_url"
    echo "  Model:    $model"
    echo ""
}
