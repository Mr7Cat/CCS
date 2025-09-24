# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release of Claude Code Switch npm package
- Multi-provider support (Deepseek, KIMI2, GLM4.5, Qwen, LongCat, Claude, Opus)
- Intelligent key management with rotation strategies
- API key health monitoring and automatic failover
- Usage statistics tracking
- Built-in API testing functionality
- Shell integration support
- Comprehensive CLI interface with commander.js
- Configuration management with JSON files
- Environment variable override support

### Features
- **Key Rotation Strategies**:
  - Round-robin rotation
  - Load balancing based on usage
  - Smart selection based on success rate and usage frequency
- **Health Monitoring**:
  - Automatic detection of failed keys
  - Temporary key disabling with retry mechanism
  - Real-time API testing
- **Configuration**:
  - JSON-based configuration files
  - Environment variable override
  - Multiple API keys per provider
- **CLI Commands**:
  - Provider switching with `ccs <provider>`
  - Status monitoring with `ccs status`
  - Usage statistics with `ccs stats`
  - Key rotation with `ccs rotate`
  - API testing with `ccs test-keys`
  - Configuration editing with `ccs config`

### Supported Providers
- Deepseek (official + PPINFRA fallback)
- KIMI2/Moonshot (official + PPINFRA fallback)
- GLM4.5/Zhipu AI (official only)
- Qwen (official Anthropic-compatible + PPINFRA fallback)
- LongCat/Meituan (official)
- Claude Sonnet (API mode + Pro subscription mode)
- Claude Opus (API mode + Pro subscription mode)

### Technical Details
- Built with Node.js 16+
- Uses commander.js for CLI interface
- Axios for HTTP requests
- fs-extra for file operations
- Jest for testing
- ESLint for code quality