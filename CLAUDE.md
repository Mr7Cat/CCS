# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Claude Code Switch (CCS)**, a shell-based tool for switching between different AI model providers when using Claude Code. The tool manages API keys, handles provider switching, and provides advanced key rotation strategies.

## Architecture

### Core Components

1. **ccs.sh** - Main executable script that handles model switching and key management
2. **install.sh** - Installation script that adds a `ccs()` function to the user's shell
3. **uninstall.sh** - Removes the `ccs()` function from shell configurations

### Key Management System

The tool implements a sophisticated key pool management system:

- **Multi-key support**: Each provider can have multiple API keys configured as arrays
- **Rotation strategies**: `round_robin`, `load_balance`, `smart` (based on success rate and usage frequency)
- **Health tracking**: Keys are monitored for failures and temporarily disabled if they fail
- **Usage statistics**: Tracks key usage patterns and success rates for intelligent switching

### Configuration Files

- `~/.ccs_config` - Main configuration file with API keys and settings
- `~/.ccs_usage_stats` - JSON file tracking key usage statistics
- `~/.ccs_key_status` - JSON file tracking key health status
- `~/.ccs_${provider}_index` - Per-provider rotation index files

### Supported Providers

- **Deepseek**: Official API + PPINFRA fallback
- **KIMI2**: Moonshot official API + PPINFRA fallback
- **GLM4.5**: Zhipu AI official API only
- **Qwen**: Official Anthropic-compatible endpoint + PPINFRA fallback
- **LongCat**: Meituan official API
- **Claude**: API mode with custom BASE_URL or Pro subscription mode
- **Opus**: Same as Claude but for Opus model

## Common Commands

### Installation and Setup
```bash
./install.sh                    # Install ccs function to shell
./uninstall.sh                  # Remove ccs function from shell
./ccs.sh config                 # Edit configuration file
```

### Model Switching
```bash
eval "$(./ccs.sh deepseek)"     # Switch to Deepseek (recommended usage)
eval "$(./ccs.sh kimi)"         # Switch to KIMI2
eval "$(./ccs.sh claude)"       # Switch to Claude Sonnet
eval "$(./ccs.sh opus)"         # Switch to Claude Opus
eval "$(./ccs.sh glm)"          # Switch to GLM4.5
eval "$(./ccs.sh qwen)"         # Switch to Qwen
eval "$(./ccs.sh longcat)"      # Switch to LongCat
```

### Management and Monitoring
```bash
./ccs.sh status                 # Show current configuration (masked)
./ccs.sh status --detailed      # Show detailed key pool status
./ccs.sh stats                  # Show usage statistics
./ccs.sh rotate deepseek        # Manually rotate to next key
./ccs.sh test-keys              # Test all provider keys
./ccs.sh test-keys deepseek     # Test specific provider keys
```

## Development Guidelines

### Code Structure

The main script follows this structure:
1. **Configuration Management** (lines ~30-165): Loading and validating config
2. **Key Pool Manager** (lines ~185-497): Multi-key handling and rotation logic
3. **Provider Switch Functions** (lines ~880-1150): Individual provider implementations
4. **Environment Export Functions** (lines ~1267-1547): Shell environment setup
5. **Main Entry Point** (lines ~1549-1618): Command routing and execution

### Key Design Patterns

- **Strategy Pattern**: Key rotation strategies are pluggable (`round_robin`, `load_balance`, `smart`)
- **Health Check System**: Failed keys are temporarily disabled with exponential backoff
- **Configuration Hierarchy**: Environment variables override config file values
- **Shell Integration**: Uses `eval` pattern for environment variable export

### Testing Approach

The tool includes built-in API testing functionality:
- Real API calls to validate key functionality
- HTTP status code interpretation for different failure modes
- Automatic key health status updates based on test results

### Installation Pattern

The installation system uses shell function injection rather than PATH manipulation:
- Injects a `ccs()` function into shell RC files
- Function handles both interactive commands and environment variable exports
- Uses markers for idempotent installation/uninstallation