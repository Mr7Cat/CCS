const crypto = require('crypto');

class KeyManager {
  constructor(configManager) {
    this.configManager = configManager;
  }

  isValidKey(key) {
    if (!key || typeof key !== 'string') return false;
    const lower = key.toLowerCase();
    return !lower.includes('your-') && key.length > 8;
  }

  getAvailableKeys(provider, config) {
    const providerConfig = config.providers[provider];
    if (!providerConfig || !providerConfig.apiKeys) return [];

    return providerConfig.apiKeys.filter(key => this.isValidKey(key));
  }

  async isKeyHealthy(provider, key, retryAfterMinutes = 30) {
    const keyStatus = await this.configManager.loadKeyStatus();
    const keyId = this.getKeyId(key);
    const currentTime = Date.now();

    const status = keyStatus[provider]?.[keyId];
    if (!status || status.status !== 'failed') return true;

    const timeDiff = currentTime - status.failedAt;
    const retryTime = retryAfterMinutes * 60 * 1000;

    return timeDiff >= retryTime;
  }

  async markKeyFailed(provider, key, reason) {
    const keyStatus = await this.configManager.loadKeyStatus();
    const keyId = this.getKeyId(key);

    if (!keyStatus[provider]) keyStatus[provider] = {};

    keyStatus[provider][keyId] = {
      status: 'failed',
      reason,
      failedAt: Date.now()
    };

    await this.configManager.saveKeyStatus(keyStatus);
  }

  async recordKeyUsage(provider, key, success) {
    const stats = await this.configManager.loadUsageStats();
    const keyId = this.getKeyId(key);

    if (!stats[provider]) stats[provider] = {};
    if (!stats[provider][keyId]) {
      stats[provider][keyId] = { total: 0, success: 0, lastUsed: 0 };
    }

    stats[provider][keyId].total += 1;
    stats[provider][keyId].lastUsed = Date.now();
    if (success) {
      stats[provider][keyId].success += 1;
    }

    await this.configManager.saveUsageStats(stats);
  }

  async selectBestKey(provider, config) {
    const availableKeys = this.getAvailableKeys(provider, config);
    if (availableKeys.length === 0) return null;

    // Filter healthy keys
    const healthyKeys = [];
    for (const key of availableKeys) {
      if (await this.isKeyHealthy(provider, key)) {
        healthyKeys.push(key);
      }
    }

    if (healthyKeys.length === 0) {
      // Return first available key if all are unhealthy (for retry)
      return availableKeys[0];
    }

    const strategy = config.providers[provider].rotationStrategy || 'round_robin';

    switch (strategy) {
    case 'round_robin':
      return await this.selectKeyRoundRobin(provider, healthyKeys);
    case 'load_balance':
      return await this.selectKeyLoadBalance(provider, healthyKeys);
    case 'smart':
      return await this.selectKeySmart(provider, healthyKeys);
    default:
      return healthyKeys[0];
    }
  }

  async selectKeyRoundRobin(provider, keys) {
    if (keys.length === 1) return keys[0];

    const currentIndex = await this.configManager.getRotationIndex(provider);
    const validIndex = currentIndex % keys.length;
    const nextIndex = (validIndex + 1) % keys.length;

    await this.configManager.setRotationIndex(provider, nextIndex);
    return keys[validIndex];
  }

  async selectKeyLoadBalance(provider, keys) {
    const stats = await this.configManager.loadUsageStats();

    let minUsage = Infinity;
    let bestKey = keys[0];

    for (const key of keys) {
      const keyId = this.getKeyId(key);
      const usage = stats[provider]?.[keyId]?.total || 0;

      if (usage < minUsage) {
        minUsage = usage;
        bestKey = key;
      }
    }

    return bestKey;
  }

  async selectKeySmart(provider, keys) {
    const stats = await this.configManager.loadUsageStats();

    let bestScore = -1;
    let bestKey = keys[0];

    for (const key of keys) {
      const keyId = this.getKeyId(key);
      const keyStats = stats[provider]?.[keyId] || { total: 1, success: 1 };

      const total = keyStats.total || 1;
      const success = keyStats.success || 1;

      // Calculate success rate
      const successRate = success / total;

      // Calculate usage factor (lower usage is better)
      const usageFactor = 1 / (total + 1);

      // Smart score: 70% success rate + 30% usage factor
      const score = successRate * 0.7 + usageFactor * 0.3;

      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }

    return bestKey;
  }

  getKeyId(key) {
    return crypto.createHash('sha256').update(key).digest('hex').substring(0, 8);
  }

  maskKey(key) {
    if (!key || typeof key !== 'string') return '[未设置]';
    if (key.length <= 8) return '[已设置] ****';
    return `[已设置] ${key.substring(0, 4)}...${key.substring(key.length - 4)}`;
  }

  async rotateKey(provider, config) {
    const availableKeys = this.getAvailableKeys(provider, config);
    if (availableKeys.length <= 1) {
      throw new Error(`${provider} 只有一个或没有可用 key，无需轮换`);
    }

    const nextKey = await this.selectKeyRoundRobin(provider, availableKeys);
    return nextKey;
  }
}

module.exports = KeyManager;