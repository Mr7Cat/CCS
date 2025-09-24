const fs = require('fs-extra');
const path = require('path');
const os = require('os');

class ConfigManager {
  constructor() {
    this.configDir = path.join(os.homedir(), '.ccs');
    this.configFile = path.join(this.configDir, 'config.json');
    this.usageStatsFile = path.join(this.configDir, 'usage_stats.json');
    this.keyStatusFile = path.join(this.configDir, 'key_status.json');
    this.rotationIndexDir = path.join(this.configDir, 'rotation');
  }

  async ensureConfigDir() {
    await fs.ensureDir(this.configDir);
    await fs.ensureDir(this.rotationIndexDir);
  }

  async loadConfig() {
    await this.ensureConfigDir();

    if (!await fs.pathExists(this.configFile)) {
      await this.createDefaultConfig();
    }

    try {
      const config = await fs.readJson(this.configFile);
      // Merge with environment variables (env takes priority)
      return this.mergeWithEnv(config);
    } catch (error) {
      throw new Error(`Failed to load config: ${error.message}`);
    }
  }

  async createDefaultConfig() {
    const defaultConfig = {
      providers: {
        deepseek: {
          apiKeys: ['sk-your-deepseek-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.deepseek.com/anthropic',
          model: 'deepseek-chat',
          smallFastModel: 'deepseek-chat',
          fallbackProvider: 'ppinfra'
        },
        kimi: {
          apiKeys: ['your-kimi-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.moonshot.cn/anthropic',
          model: 'kimi-k2-0905-preview',
          smallFastModel: 'kimi-k2-0905-preview',
          fallbackProvider: 'ppinfra'
        },
        glm: {
          apiKeys: ['your-glm-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://open.bigmodel.cn/api/anthropic',
          model: 'glm-4.5',
          smallFastModel: 'glm-4.5-air'
        },
        qwen: {
          apiKeys: ['your-qwen-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.ppinfra.com/openai/v1/anthropic',
          model: 'qwen3-next-80b-a3b-thinking',
          smallFastModel: 'qwen3-next-80b-a3b-thinking',
          anthropicBaseUrl: ''
        },
        longcat: {
          apiKeys: ['your-longcat-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.longcat.chat/anthropic',
          model: 'LongCat-Flash-Thinking',
          smallFastModel: 'LongCat-Flash-Chat'
        },
        claude: {
          apiKeys: ['your-claude-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.aicodemirror.com/api/claudecode',
          model: 'claude-sonnet-4-20250514',
          smallFastModel: 'claude-sonnet-4-20250514'
        },
        opus: {
          apiKeys: ['your-opus-api-key'],
          rotationStrategy: 'round_robin',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-opus-4-1-20250805',
          smallFastModel: 'claude-sonnet-4-20250514'
        }
      },
      fallback: {
        ppinfra: {
          apiKey: 'your-ppinfra-api-key',
          baseUrl: 'https://api.ppinfra.com/openai/v1/anthropic'
        }
      }
    };

    await fs.writeJson(this.configFile, defaultConfig, { spaces: 2 });
    return defaultConfig;
  }

  mergeWithEnv(config) {
    // Environment variables take priority over config file
    const envProviders = ['DEEPSEEK', 'KIMI', 'GLM', 'QWEN', 'LONGCAT', 'CLAUDE', 'OPUS'];

    envProviders.forEach(provider => {
      const providerLower = provider.toLowerCase();
      const apiKey = process.env[`${provider}_API_KEY`];
      const apiKeys = process.env[`${provider}_API_KEYS`];
      const rotationStrategy = process.env[`${provider}_ROTATION_STRATEGY`];
      const model = process.env[`${provider}_MODEL`];
      const smallModel = process.env[`${provider}_SMALL_FAST_MODEL`];

      if (config.providers[providerLower]) {
        if (apiKey) {
          config.providers[providerLower].apiKeys = [apiKey];
        }
        if (apiKeys) {
          try {
            config.providers[providerLower].apiKeys = JSON.parse(apiKeys);
          } catch (e) {
            // If parsing fails, treat as single key
            config.providers[providerLower].apiKeys = [apiKeys];
          }
        }
        if (rotationStrategy) {
          config.providers[providerLower].rotationStrategy = rotationStrategy;
        }
        if (model) {
          config.providers[providerLower].model = model;
        }
        if (smallModel) {
          config.providers[providerLower].smallFastModel = smallModel;
        }
      }
    });

    // Handle fallback provider
    const ppinfraKey = process.env.PPINFRA_API_KEY;
    if (ppinfraKey) {
      config.fallback.ppinfra.apiKey = ppinfraKey;
    }

    return config;
  }

  async saveConfig(config) {
    await this.ensureConfigDir();
    await fs.writeJson(this.configFile, config, { spaces: 2 });
  }

  async loadUsageStats() {
    if (!await fs.pathExists(this.usageStatsFile)) {
      return {};
    }
    try {
      return await fs.readJson(this.usageStatsFile);
    } catch (error) {
      return {};
    }
  }

  async saveUsageStats(stats) {
    await this.ensureConfigDir();
    await fs.writeJson(this.usageStatsFile, stats, { spaces: 2 });
  }

  async loadKeyStatus() {
    if (!await fs.pathExists(this.keyStatusFile)) {
      return {};
    }
    try {
      return await fs.readJson(this.keyStatusFile);
    } catch (error) {
      return {};
    }
  }

  async saveKeyStatus(status) {
    await this.ensureConfigDir();
    await fs.writeJson(this.keyStatusFile, status, { spaces: 2 });
  }

  async getRotationIndex(provider) {
    const indexFile = path.join(this.rotationIndexDir, `${provider}_index.json`);
    if (!await fs.pathExists(indexFile)) {
      return 0;
    }
    try {
      const data = await fs.readJson(indexFile);
      return data.index || 0;
    } catch (error) {
      return 0;
    }
  }

  async setRotationIndex(provider, index) {
    await this.ensureConfigDir();
    const indexFile = path.join(this.rotationIndexDir, `${provider}_index.json`);
    await fs.writeJson(indexFile, { index }, { spaces: 2 });
  }
}

module.exports = ConfigManager;