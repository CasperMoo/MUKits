# MMC Design Document

**项目**: mukits-cli - 个人工具集
**工具**: mmc (Mukits Claude Code 管理器)
**日期**: 2025-02-10

## 概述

MMC 是一个 Claude Code CLI 提供商切换工具，通过环境变量管理不同 AI 提供商的配置，实现快速切换和启动。

## 核心机制

Claude Code CLI 读取以下 7 个环境变量来决定使用哪个 API：

1. `ANTHROPIC_BASE_URL` - API 基础 URL
2. `ANTHROPIC_AUTH_TOKEN` - 认证令牌
3. `ANTHROPIC_MODEL` - 主模型
4. `ANTHROPIC_DEFAULT_SONNET_MODEL` - Sonnet 模型
5. `ANTHROPIC_DEFAULT_OPUS_MODEL` - Opus 模型
6. `ANTHROPIC_DEFAULT_HAIKU_MODEL` - Haiku 模型
7. `CLAUDE_CODE_SUBAGENT_MODEL` - 子代理模型

## 项目结构

```
mukits/
├── install.sh              # 主安装脚本
├── core/
│   └── installer.lib.sh    # 共享安装逻辑
├── tools/
│   └── mmc/                # Claude Code 提供商管理器
│       ├── install.sh      # mmc 安装钩子
│       ├── bin/
│       │   └── mmc         # 主入口（单一命令）
│       ├── lib/
│       │   ├── core.sh     # 核心函数（emit_env_exports）
│       │   ├── config.sh   # 配置读写（TOML 解析）
│       │   └── provider.sh # 提供商定义
│       ├── config/
│       │   └── providers.toml.example
│       └── README.md
└── README.md
```

**安装后结构**：
```
~/.mukits/
├── mmc/                    # 软链接到源码
└── config.toml             # 全局配置

~/.local/bin/
└── mmc -> ~/.mukits/mmc/bin/mmc
```

## 配置系统

### 配置优先级

环境变量 > 配置文件 > 默认值

### 配置文件

**位置**: `~/.mukits/config.toml`

```toml
[providers.deepseek]
name = "deepseek"
base_url = "https://api.deepseek.com/anthropic"
auth_token = ""  # 留空则从 $DEEPSEEK_API_KEY 读取
model = "deepseek-chat"
sonnet = "deepseek/deepseek-v3.2"
opus = "deepseek/deepseek-v3.2"
haiku = "deepseek/deepseek-v3.2"
subagent = "deepseek-chat"

[providers.glm]
name = "glm"
base_url = "https://open.bigmodel.cn/api/paas/v4/"
auth_token = ""  # 从 $GLM_API_KEY 读取
model = "glm-4"
sonnet = "glm-4"
opus = "glm-4"
haiku = "glm-4"
subagent = "glm-4"

[mmc]
default_provider = "deepseek"
interactive_fallback = true
```

### 内置提供商

- `deepseek` (ds)
- `glm`

用户可在配置文件中添加自定义提供商。

## 命令行接口

```bash
# 1. 直接切换并启动（最常用）
mmc deepseek                    # 切换到 deepseek，启动 claude
mmc ds                          # 简写
mmc ds -y "帮我写个函数"         # 透传参数给 claude

# 2. 查看类命令
mmc ls                          # 列出所有可用提供商
mmc status                      # 显示当前生效配置

# 3. 交互式选择
mmc                             # fzf 或简单菜单选择

# 4. 配置管理
mmc config edit                 # 编辑配置文件
mmc config add <name> <url>     # 添加自定义提供商
```

## 环境变量输出机制

```bash
emit_env_exports() {
    local provider_name="$1"
    local config=$(load_provider_config "$provider_name")

    # 1. 先 unset 旧变量
    printf "unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN "
    printf "ANTHROPIC_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL "
    printf "ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL "
    printf "CLAUDE_CODE_SUBAGENT_MODEL\n"

    # 2. 读取配置（环境变量优先）
    local base_url=$(get_config_value "$config" "base_url")
    local auth_token=$(get_auth_token "$provider_name")
    local model=$(get_config_value "$config" "model")
    # ...

    # 3. 输出 export 语句
    echo "export ANTHROPIC_BASE_URL='$base_url'"
    echo "export ANTHROPIC_AUTH_TOKEN='$auth_token'"
    echo "export ANTHROPIC_MODEL='$model'"
    # ...
}
```

## 错误处理与交互

### API Key 缺失流程

1. 检查环境变量（如 `$DEEPSEEK_API_KEY`）
2. 检查配置文件
3. 若都缺失 → 交互式输入
4. 询问是否保存到配置文件（仅本次 vs 永久）

### 交互式选择器

```bash
interactive_select() {
    if command -v fzf &>/dev/null; then
        printf '%s\n' "${providers[@]}" | fzf --prompt="选择提供商: "
    else
        simple_menu "${providers[@]}"
    fi
}
```

## 安装方式

```bash
curl -sL https://raw.githubusercontent.com/xxx/mukits/main/install.sh | bash
```

安装脚本会：
1. 克隆/更新仓库到 `~/.mukits/`
2. 确保 `~/.local/bin/` 在 PATH 中
3. 创建软链接 `~/.local/bin/mmc`
4. 初始化配置文件（如果不存在）
