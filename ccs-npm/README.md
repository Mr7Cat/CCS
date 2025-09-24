# Claude Code Switch (NPM Version)

一个基于 Node.js 的 AI 模型提供商切换工具，用于在使用 Claude Code 时快速切换不同的 AI 模型提供商。

## 功能特性

- 🚀 **多提供商支持**: 支持 Deepseek、KIMI2、GLM4.5、Qwen、LongCat、Claude 等多个提供商
- 🔑 **智能 Key 管理**: 支持多 key 配置和智能轮换策略
- 📊 **使用统计**: 跟踪 key 使用情况和成功率
- 🔄 **健康检查**: 自动检测失效的 key 并临时禁用
- 🎯 **轮换策略**: 支持轮询、负载均衡和智能切换策略
- 🧪 **API 测试**: 内置 API key 可用性测试功能

## 安装

```bash
npm install -g claude-code-switch
```

## 快速开始

### 1. 初始化配置

```bash
ccs config
```

这将创建配置文件并用编辑器打开，请填入你的 API keys。

### 2. 切换模型

```bash
# 推荐用法：使用 eval 在当前 shell 中生效
eval "$(ccs deepseek)"
eval "$(ccs kimi)"
eval "$(ccs claude)"

# 也可以直接运行（仅输出 export 语句）
ccs deepseek
```

### 3. 查看状态

```bash
# 查看当前配置
ccs status

# 查看详细状态（包括所有 keys）
ccs status --detailed

# 查看使用统计
ccs stats
```

## 支持的提供商

| 提供商 | 别名 | 描述 |
|--------|------|------|
| deepseek | ds | 🤖 Deepseek - 官方：deepseek-chat |
| kimi | kimi2 | 🌙 KIMI2 - 官方：kimi-k2-0905-preview |
| glm | glm4, glm4.5 | 🇨🇳 GLM4.5 - 官方：glm-4.5 / glm-4.5-air |
| qwen | - | 🐪 Qwen - qwen3-next-80b-a3b-thinking |
| longcat | lc | 🐱 LongCat - LongCat-Flash-Thinking |
| claude | sonnet, s | 🧠 Claude Sonnet 4 - claude-sonnet-4-20250514 |
| opus | o | 🚀 Claude Opus 4.1 - claude-opus-4-1-20250805 |

## 命令参考

### 模型切换
```bash
ccs deepseek     # 切换到 Deepseek
ccs kimi         # 切换到 KIMI2
ccs claude       # 切换到 Claude Sonnet
ccs opus         # 切换到 Claude Opus
ccs glm          # 切换到 GLM4.5
ccs qwen         # 切换到 Qwen
ccs longcat      # 切换到 LongCat
```

### 状态和管理
```bash
ccs status                    # 显示当前配置
ccs status --detailed         # 显示详细状态
ccs stats                     # 显示使用统计
ccs config                    # 编辑配置文件
```

### Key 管理
```bash
ccs rotate deepseek           # 手动轮换到下一个 key
ccs test-keys                 # 测试所有 key
ccs test-keys deepseek        # 测试特定提供商的 key
```

## 配置文件

配置文件位于 `~/.ccs/config.json`，支持以下配置：

```json
{
  "providers": {
    "deepseek": {
      "apiKeys": ["sk-your-deepseek-key1", "sk-your-deepseek-key2"],
      "rotationStrategy": "round_robin",
      "baseUrl": "https://api.deepseek.com/anthropic",
      "model": "deepseek-chat",
      "smallFastModel": "deepseek-chat"
    }
  }
}
```

### 轮换策略

- **round_robin**: 轮询使用各个 key
- **load_balance**: 选择使用次数最少的 key
- **smart**: 综合考虑成功率和使用频率

## 环境变量

支持通过环境变量覆盖配置文件设置：

```bash
export DEEPSEEK_API_KEY="your-key"
export DEEPSEEK_API_KEYS='["key1", "key2"]'
export DEEPSEEK_ROTATION_STRATEGY="smart"
export DEEPSEEK_MODEL="custom-model"
```

## Shell 集成

推荐在 shell 配置文件中添加别名：

```bash
# ~/.bashrc 或 ~/.zshrc
alias ds='eval "$(ccs deepseek)"'
alias kimi='eval "$(ccs kimi)"'
alias claude='eval "$(ccs claude)"'
alias opus='eval "$(ccs opus)"'
```

## API 兼容性

本工具设置的环境变量与 Claude Code 完全兼容：

- `ANTHROPIC_BASE_URL` - API 基础 URL
- `ANTHROPIC_AUTH_TOKEN` - 认证令牌
- `ANTHROPIC_MODEL` - 模型 ID
- `ANTHROPIC_SMALL_FAST_MODEL` - 小模型 ID

## 故障排除

### 配置问题
```bash
# 检查配置文件
ccs config

# 查看当前状态
ccs status --detailed
```

### Key 问题
```bash
# 测试 key 可用性
ccs test-keys

# 手动轮换到下一个 key
ccs rotate deepseek
```

### 日志和调试
使用统计功能查看 key 使用情况：
```bash
ccs stats
```

## 开发

```bash
# 克隆项目
git clone https://github.com/mr7cat/ccs-npm.git
cd ccs-npm

# 安装依赖
npm install

# 运行测试
npm test

# 本地链接
npm link
```

## 许可证

MIT License