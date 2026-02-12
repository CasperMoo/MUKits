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

### mmc - Claude Code 提供商管理器

快速切换 Claude Code 使用的 AI 提供商。

```bash
# 切换并启动
mmc deepseek
mmc ds          # 简写

# 查看可用提供商
mmc ls

# 查看当前配置
mmc status

# 编辑配置
mmc config edit
```

**支持的环境变量：**
- `DEEPSEEK_API_KEY` - DeepSeek API Key
- `GLM_API_KEY` - 智谱 API Key
- `ANTHROPIC_API_KEY` - Anthropic API Key

## 项目结构

```
mukits/
├── install.sh          # 主安装脚本
├── core/               # 共享核心
├── tools/              # 各工具
│   └── mmc/            # Claude Code 管理器
└── docs/plans/         # 设计文档
```

## License

MIT
