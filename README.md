# MUKits

让任何人都能轻松使用 Claude Code。

## 一键安装

```bash
curl -sL https://raw.githubusercontent.com/CasperMoo/MUKits/main/install.sh | bash
```

安装脚本会自动：
- 检查并安装 Claude Code
- 安装 MUKits 工具集
- 引导进行首次配置

## MM - Claude Code 简易启动器

**设计理念：** 无需编程基础，任何人都能 3 分钟上手。

### 快速开始

```bash
mm          # 启动 Claude Code
mm setup    # 配置向导
```

### 支持的服务商

| 服务商 | 特点 |
|--------|------|
| 智谱 GLM | 国产领先，性价比高 |
| DeepSeek | 能力强，价格低 |
| 火山引擎 | 字节豆包，稳定可靠 |
| 阿里云百炼 | 通义千问，生态完整 |
| 硅基流动 | 聚合平台，模型丰富 |
| Anthropic | Claude 官方 API |
| OpenRouter | 全球模型聚合平台 |

### 配置向导

首次运行 `mm` 会自动进入配置向导：

1. **选择服务商** - 从 7 个服务商中选择
2. **设置 API Key** - 提供申请链接，支持一键打开网页
3. **选择性能模式** - 快速 / 均衡 / 强大

### 性能模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| 快速 | 响应快，价格低 | 日常对话、简单问题 |
| 均衡 | 性价比最优 | 大多数场景（推荐） |
| 强大 | 最强能力 | 复杂任务、代码重构 |

### 启动选项

运行 `mm setup` → 选择「启动选项」：

- **跳过权限确认** - Claude Code 自动执行命令，无需每次确认

### 命令说明

```bash
mm              # 交互式选择配置并启动
mm <profile>    # 直接使用指定配置启动（如 mm glm-balanced）
mm setup        # 配置向导
mm update       # 检查并更新
mm version      # 显示版本
mm help         # 显示帮助
```

### 自动更新

- 启动时自动检查更新（24 小时间隔）
- 发现新版本时提示是否更新
- 更新后重新运行 `mm` 即可使用新版本

## 依赖

- **Node.js** - 用于安装 Claude Code
- **jq** - JSON 解析（安装脚本会检查）

## 配置文件

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

## 常见问题

**Q: 如何获取 API Key？**

运行 `mm setup` → 选择「管理 API Key」→ 选择「打开申请页面」，会自动打开服务商的申请页面。

**Q: 如何切换服务商？**

运行 `mm setup` → 选择「切换配置」，或直接运行 `mm` 在启动时选择。

**Q: 如何更新？**

运行 `mm update`，或在启动时按提示更新。

## 项目地址

https://github.com/CasperMoo/MUKits

## License

MIT
