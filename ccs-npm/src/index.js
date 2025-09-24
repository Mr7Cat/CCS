const ConfigManager = require('./config');
const KeyManager = require('./keyManager');
const ProviderManager = require('./providers');
const ApiTester = require('./apiTester');

class CCS {
  constructor() {
    this.configManager = new ConfigManager();
    this.keyManager = new KeyManager(this.configManager);
    this.providerManager = new ProviderManager(this.configManager, this.keyManager);
    this.apiTester = new ApiTester(this.keyManager);
  }

  async init() {
    this.config = await this.configManager.loadConfig();
    return this;
  }

  async switchProvider(providerName) {
    const resolvedProvider = this.providerManager.resolveProviderName(providerName);
    if (!resolvedProvider) {
      throw new Error(`Unknown provider: ${providerName}`);
    }

    return await this.providerManager.switchToProvider(resolvedProvider, this.config);
  }

  async generateExportCommands(providerName) {
    const resolvedProvider = this.providerManager.resolveProviderName(providerName);
    if (!resolvedProvider) {
      throw new Error(`Unknown provider: ${providerName}`);
    }

    return await this.providerManager.generateExportCommands(resolvedProvider, this.config);
  }

  async getStatus() {
    const status = {
      providers: {},
      currentConfig: {}
    };

    // Get current environment status
    status.currentConfig = {
      baseUrl: process.env.ANTHROPIC_BASE_URL || '默认 (Anthropic)',
      authToken: this.keyManager.maskKey(process.env.ANTHROPIC_AUTH_TOKEN),
      model: process.env.ANTHROPIC_MODEL || '未设置',
      smallModel: process.env.ANTHROPIC_SMALL_FAST_MODEL || '未设置'
    };

    // Get provider status
    for (const [providerName, providerConfig] of Object.entries(this.config.providers)) {
      const availableKeys = this.keyManager.getAvailableKeys(providerName, this.config);
      status.providers[providerName] = {
        keyCount: availableKeys.length,
        strategy: providerConfig.rotationStrategy,
        hasValidKeys: availableKeys.length > 0
      };
    }

    return status;
  }

  async getDetailedStatus() {
    const status = await this.getStatus();

    // Add detailed key information
    for (const [providerName] of Object.entries(this.config.providers)) {
      const availableKeys = this.keyManager.getAvailableKeys(providerName, this.config);
      const keyDetails = [];

      for (let i = 0; i < availableKeys.length; i++) {
        const key = availableKeys[i];
        const isHealthy = await this.keyManager.isKeyHealthy(providerName, key);
        keyDetails.push({
          index: i + 1,
          masked: this.keyManager.maskKey(key),
          healthy: isHealthy
        });
      }

      status.providers[providerName].keys = keyDetails;
    }

    return status;
  }

  async getUsageStats() {
    const stats = await this.configManager.loadUsageStats();
    const formattedStats = {};

    for (const [provider, providerStats] of Object.entries(stats)) {
      formattedStats[provider] = {};

      for (const [keyId, keyStats] of Object.entries(providerStats)) {
        const successRate = keyStats.total > 0 ? (keyStats.success / keyStats.total * 100).toFixed(1) : '0';
        const lastUsed = keyStats.lastUsed ? new Date(keyStats.lastUsed).toLocaleString() : '从未使用';

        // Check if key is still active
        const availableKeys = this.keyManager.getAvailableKeys(provider, this.config);
        const isActive = availableKeys.some(key => this.keyManager.getKeyId(key) === keyId);

        formattedStats[provider][keyId] = {
          total: keyStats.total,
          success: keyStats.success,
          successRate: `${successRate}%`,
          lastUsed,
          isActive
        };
      }
    }

    return formattedStats;
  }

  async rotateKey(providerName) {
    const resolvedProvider = this.providerManager.resolveProviderName(providerName);
    if (!resolvedProvider) {
      throw new Error(`Unknown provider: ${providerName}`);
    }

    const nextKey = await this.keyManager.rotateKey(resolvedProvider, this.config);
    return {
      provider: resolvedProvider,
      nextKey: this.keyManager.maskKey(nextKey)
    };
  }

  async testKeys(providerName = null) {
    if (providerName) {
      const resolvedProvider = this.providerManager.resolveProviderName(providerName);
      if (!resolvedProvider) {
        throw new Error(`Unknown provider: ${providerName}`);
      }
      return await this.apiTester.testProviderKeys(resolvedProvider, this.config);
    } else {
      return await this.apiTester.testAllProviders(this.config);
    }
  }

  getProviderList() {
    return this.providerManager.getProviderList();
  }

  async editConfig() {
    const configPath = this.configManager.configFile;
    return configPath;
  }
}

module.exports = CCS;