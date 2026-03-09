# MUKits

个人常用工具集，支持一键安装。

**GitHub:** https://github.com/CasperMoo/MUKits

## 安装

```bash
curl -sL https://raw.githubusercontent.com/CasperMoo/MUKits/main/install.sh | bash
```

安装脚本会自动：
1. 检查并安装 Claude Code（如果未安装）
2. 安装/更新 mukits 工具集
3. 引导进行首次配置

**依赖：** Node.js（用于安装 Claude Code）

确保 `~/.local/bin` 在你的 PATH 中：

```bash
# 添加到 ~/.zshrc 或 ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## MM - Claude Code 简易启动器

让任何人都能轻松使用 Claude Code，无需编程基础。

### 快速开始

```bash
mm              # 选择配置并启动
mm setup        # 配置向导
```

### 支持的服务商

| 服务商 | 特点 |
|--------|------|
| **智谱 GLM** | 国产领先，性价比高 |
| **DeepSeek** | 能力强，价格低 |
| **火山引擎** | 字节豆包，稳定可靠 |
| **阿里云百炼** | 通义千问，生态完整 |
| **硅基流动** | 聚合平台，模型丰富 |
| **Anthropic** | Claude 官方 API |
| **OpenRouter** | 全球模型聚合平台 |

### 配置向导

首次运行 `mm` 会自动进入配置向导，引导你：

1. **选择服务商** - 从 7 个服务商中选择
2. **设置 API Key** - 提供申请链接，支持一键打开网页
3. **选择性能模式** - 快速/均衡/强大 三档可选

### 性能模式

| 模式 | 说明 |
|------|------|
| **快速** | 响应快，价格低，适合日常对话 |
| **均衡** | 性价比最优，推荐大多数场景 |
| **强大** | 最强能力，适合复杂任务 |

### 启动选项

运行 `mm setup` → 选择「启动选项」，可以：

- **跳过权限确认** - Claude Code 自动执行命令，无需每次确认

### 命令说明

```bash
mm              # 交互式选择配置并启动
mm <profile>    # 直接使用指定配置启动（如 mm glm-balanced）
mm setup        # 配置向导
mm help         # 显示帮助
```

### 配置文件

位置：`~/.mukits/config.json`

```json
{
  "providers": { ... },
  "profiles": {
    "glm-balanced": {
      "provider": "glm",
      "preset": "balanced",
      "haiku": "glm-4-air",
      "sonnet": "glm-4",
      "opus": "glm-4"
    }
  },
  "active_profile": "glm-balanced",
  "options": {
    "skip_permissions": false
  }
}
```

## 项目结构

```
mukits/
├── install.sh          # 主安装脚本
├── core/               # 共享核心
└── tools/mmc/          # MM 启动器
    ├── bin/mm          # 主脚本
    └── install.sh      # 安装钩子
```

## License

MIT
