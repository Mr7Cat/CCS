# CCS NPM 包安装和使用指南

## 概述

我已经成功创建了一个基于 Node.js 的 Claude Code Switch (CCS) npm 包，该包复现了原始 bash 脚本的所有核心功能，并提供了更好的跨平台兼容性和扩展性。

## 项目结构

```
ccs-npm/
├── package.json          # npm 包配置
├── bin/
│   └── ccs.js            # CLI 入口点
├── src/
│   ├── index.js          # 主要 CCS 类
│   ├── config.js         # 配置管理器
│   ├── keyManager.js     # Key 池管理器
│   ├── providers.js      # 提供商管理器
│   └── apiTester.js      # API 测试器
├── test/
│   ├── config.test.js    # 配置管理测试
│   └── keyManager.test.js # Key 管理测试
├── README.md             # 使用文档
├── CHANGELOG.md          # 变更日志
├── demo.js               # 功能演示脚本
└── install-guide.md      # 本安装指南
```

## 核心功能

### ✅ 已实现的功能

1. **多提供商支持**
   - Deepseek（官方 + PPINFRA 备用）
   - KIMI2（官方 + PPINFRA 备用）
   - GLM4.5（官方）
   - Qwen（官方 + PPINFRA 备用）
   - LongCat（官方）
   - Claude Sonnet（API + Pro 模式）
   - Claude Opus（API + Pro 模式）

2. **智能 Key 管理**
   - 多 Key 配置支持
   - 三种轮换策略：round_robin、load_balance、smart
   - Key 健康状态监控
   - 失败 Key 自动禁用和重试机制

3. **配置管理**
   - JSON 格式配置文件（`~/.ccs/config.json`）
   - 环境变量优先级覆盖
   - 自动创建默认配置

4. **使用统计**
   - Key 使用次数跟踪
   - 成功率统计
   - 最后使用时间记录

5. **API 测试**
   - 内置 API Key 可用性测试
   - 实际 API 调用验证
   - 不同错误类型识别

6. **CLI 接口**
   - 完整的命令行界面
   - 彩色输出支持
   - 与原始 bash 脚本兼容的命令格式

## 安装

### 全局安装（推荐）

```bash
npm install -g claude-code-switch
```

### 本地开发安装

  开发模式安装

  cd ccs-npm/
  npm install
  npm link  # 创建全局链接，这样可以在任何地方使用 ccs 命令

  开发模式卸载

  cd ccs-npm/
  npm unlink -g  # 移除全局链接
  # 或者
  npm unlink cc-switcher -g  # 使用包名移除

  验证安装/卸载

  # 检查是否已安装
  which ccs
  ccs --help

  # 如果卸载成功，这些命令应该找不到 ccs

  重新开发测试

  cd ccs-npm/
  npm install      # 安装依赖
  npm test         # 运行测试
  npm run lint     # 代码检查
  npm link         # 重新创建链接

## 使用方法

### 基本命令

```bash
# 查看帮助
ccs help

# 查看状态
ccs status
ccs status --detailed

# 编辑配置
ccs config

# 切换模型（推荐用法）
eval "$(ccs deepseek)"
eval "$(ccs kimi)"
eval "$(ccs claude)"

# 查看使用统计
ccs stats

# 测试 API Keys
ccs test-keys
ccs test-keys deepseek

# 手动轮换 Key
ccs rotate deepseek
```

### Shell 集成

在 `~/.bashrc` 或 `~/.zshrc` 中添加别名：

```bash
alias ds='eval "$(ccs deepseek)"'
alias kimi='eval "$(ccs kimi)"'
alias claude='eval "$(ccs claude)"'
alias opus='eval "$(ccs opus)"'
```

## 配置文件示例

配置文件位于 `~/.ccs/config.json`：

```json
{
  "providers": {
    "deepseek": {
      "apiKeys": ["sk-your-deepseek-key1", "sk-your-deepseek-key2"],
      "rotationStrategy": "round_robin",
      "baseUrl": "https://api.deepseek.com/anthropic",
      "model": "deepseek-chat",
      "smallFastModel": "deepseek-chat"
    },
    "kimi": {
      "apiKeys": ["your-kimi-key"],
      "rotationStrategy": "smart",
      "baseUrl": "https://api.moonshot.cn/anthropic",
      "model": "kimi-k2-0905-preview",
      "smallFastModel": "kimi-k2-0905-preview"
    }
  },
  "fallback": {
    "ppinfra": {
      "apiKey": "your-ppinfra-key",
      "baseUrl": "https://api.ppinfra.com/openai/v1/anthropic"
    }
  }
}
```

## 功能演示

运行演示脚本查看所有功能：

```bash
node demo.js
```

## 测试

```bash
npm test          # 运行测试
npm run test:watch # 监听模式运行测试
npm run lint      # 代码质量检查
```

## 与原始 Bash 脚本的对比

| 功能 | Bash 版本 | NPM 版本 | 优势 |
|------|-----------|----------|------|
| 跨平台兼容性 | ❌ 仅 Unix/Linux/macOS | ✅ Windows/macOS/Linux | 更好的兼容性 |
| 依赖管理 | ❌ 手动安装依赖 | ✅ npm 自动管理 | 更简单的安装 |
| 测试覆盖 | ❌ 无自动化测试 | ✅ Jest 单元测试 | 更可靠的代码 |
| 错误处理 | ⚠️ 基础错误处理 | ✅ 完善的错误处理 | 更好的用户体验 |
| 代码维护 | ⚠️ 单一大文件 | ✅ 模块化架构 | 更容易维护和扩展 |
| 安装分发 | ❌ 手动复制脚本 | ✅ npm 包管理 | 标准化分发 |
| JSON 处理 | ❌ 依赖 jq 或回退 | ✅ 原生 JSON 支持 | 更可靠的数据处理 |

## 开发和贡献

### 开发环境设置

```bash
git clone <repository>
cd ccs-npm
npm install
npm run dev
```

### 代码结构

- **config.js**: 处理配置文件加载、保存和环境变量合并
- **keyManager.js**: 管理 API key 池、轮换策略和健康状态
- **providers.js**: 处理不同提供商的特定逻辑和环境变量设置
- **apiTester.js**: 提供 API key 测试功能
- **index.js**: 主要的 CCS 类，协调所有组件

### 添加新提供商

1. 在 `config.js` 的默认配置中添加新提供商
2. 在 `providers.js` 中添加提供商特定逻辑
3. 在 `bin/ccs.js` 中添加命令别名
4. 更新文档和测试

## 部署

### 发布到 npm

```bash
npm version patch|minor|major
npm publish
```

### 本地测试

```bash
npm pack  # 创建 .tgz 包
npm install -g claude-code-switch-1.0.0.tgz  # 测试安装
```

## 故障排除

### 常见问题

1. **配置文件权限问题**
   ```bash
   chmod 600 ~/.ccs/config.json
   ```

2. **Node.js 版本兼容性**
   - 要求 Node.js >= 16.0.0

3. **依赖安装失败**
   ```bash
   npm cache clean --force
   npm install
   ```

### 调试模式

设置环境变量启用详细日志：

```bash
DEBUG=ccs:* ccs status
```

## 总结

这个 npm 版本的 CCS 提供了：

- 🚀 **更好的跨平台支持**
- 📦 **标准化的包管理**
- 🧪 **完善的测试覆盖**
- 🔧 **模块化的代码架构**
- 📊 **更丰富的功能**
- 🎯 **更好的错误处理**

同时保持了与原始 bash 脚本完全相同的用户体验和命令接口。