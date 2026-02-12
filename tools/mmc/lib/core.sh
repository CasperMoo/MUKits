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

    # Get provider config
    declare -A provider
    get_provider_config "$provider_name" provider

    # First unset old variables
    printf "unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN "
    printf "ANTHROPIC_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL "
    printf "ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL "
    printf "CLAUDE_CODE_SUBAGENT_MODEL\n"

    # Get values (env vars take priority over config)
    local base_url="${provider[base_url]}"
    local auth_token="${provider[auth_token]}"
    local model="${provider[model]}"
    local sonnet="${provider[sonnet]}"
    local opus="${provider[opus]}"
    local haiku="${provider[haiku]}"
    local subagent="${provider[subagent]}"

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
