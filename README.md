# mukits-cli

个人常用工具集，支持一键安装。

## 安装

```bash
curl -sL https://raw.githubusercontent.com/xxx/mukits/main/install.sh | bash
```

确保 `~/.local/bin` 在你的 PATH 中：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 工具

### mmc - Claude Code Profile 管理器

快速切换 Claude Code 使用的 AI 提供商和模型配置。

```bash
# 使用 profile 启动
mmc glm                    # 使用 glm profile 启动 claude
mmc ds -- -y "hello"       # 透传参数给 claude

# 查看和管理
mmc ls                     # 列出所有 profiles
mmc status                 # 查看当前环境变量
mmc config                 # 编辑配置文件
mmc                        # 交互式选择
```

**配置文件：** `~/.mukits/config.json`

```json
{
  "providers": {
    "deepseek": {
      "base_url": "https://api.deepseek.com/anthropic",
      "api_key_env": "DEEPSEEK_API_KEY",
      "models": ["deepseek-chat", "deepseek-v3"]
    },
    "glm": {
      "base_url": "https://open.bigmodel.cn/api/paas/v4/",
      "api_key_env": "GLM_API_KEY",
      "models": ["glm-4", "glm-4.5-air", "glm-4.7"]
    }
  },
  "profiles": {
    "glm": {
      "provider": "glm",
      "haiku": "glm-4.5-air",
      "sonnet": "glm-4.7",
      "opus": "glm-4.7"
    },
    "work": {
      "provider": "deepseek",
      "haiku": "deepseek-chat",
      "sonnet": "deepseek-v3",
      "opus": "deepseek-v3"
    }
  }
}
```

**配置说明：**
- `providers`: 定义服务商（base_url, api_key_env, models）
- `profiles`: 定义启动配置（必须包含 provider, haiku, sonnet, opus）

**支持的环境变量：**
- `DEEPSEEK_API_KEY` - DeepSeek API Key
- `GLM_API_KEY` - 智谱 API Key
- `ANTHROPIC_API_KEY` - Anthropic API Key

## 项目结构

```
mukits/
├── install.sh          # 主安装脚本
├── core/               # 共享核心
└── tools/mmc/          # Claude Code 管理器
    ├── bin/mmc         # 主脚本（单文件）
    └── install.sh      # 安装钩子
```

## License

MIT
