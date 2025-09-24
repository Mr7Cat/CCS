const axios = require('axios');

class ApiTester {
  constructor(keyManager) {
    this.keyManager = keyManager;
  }

  async testApiKey(provider, apiKey, config) {
    const providerConfig = config.providers[provider];
    if (!providerConfig) {
      throw new Error(`Unknown provider: ${provider}`);
    }

    let baseUrl = providerConfig.baseUrl;
    let authHeader = { 'x-api-key': apiKey };

    // Handle special cases
    if (provider === 'qwen' || baseUrl.includes('ppinfra.com')) {
      authHeader = { 'Authorization': `Bearer ${apiKey}` };
    }

    const testPayload = {
      model: 'claude-3-haiku-20240307',
      max_tokens: 10,
      messages: [
        {
          role: 'user',
          content: 'Hi'
        }
      ]
    };

    try {
      const response = await axios.post(`${baseUrl}/v1/messages`, testPayload, {
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          ...authHeader
        },
        timeout: 30000
      });

      return {
        success: true,
        status: response.status,
        message: 'API key is working'
      };
    } catch (error) {
      let testResult = {
        success: false,
        status: error.response?.status || 0,
        message: error.message
      };

      if (error.response) {
        const status = error.response.status;
        switch (status) {
        case 401:
        case 403:
          testResult.message = '认证失败';
          testResult.type = 'auth_failed';
          break;
        case 429:
          testResult.message = '速率限制';
          testResult.type = 'rate_limit';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          testResult.message = '服务器错误';
          testResult.type = 'server_error';
          break;
        default:
          testResult.message = `HTTP ${status}`;
          testResult.type = 'http_error';
        }
      } else {
        testResult.message = '连接错误';
        testResult.type = 'connection_error';
      }

      // Mark key as failed if it's an auth error
      if (testResult.type === 'auth_failed') {
        await this.keyManager.markKeyFailed(provider, apiKey, testResult.message);
      }

      return testResult;
    }
  }

  async testProviderKeys(provider, config) {
    const availableKeys = this.keyManager.getAvailableKeys(provider, config);
    if (availableKeys.length === 0) {
      return {
        provider,
        message: '无可用 key',
        results: []
      };
    }

    const results = [];
    for (let i = 0; i < availableKeys.length; i++) {
      const key = availableKeys[i];
      const keyDisplay = this.keyManager.maskKey(key);

      try {
        const testResult = await this.testApiKey(provider, key, config);
        results.push({
          index: i + 1,
          keyDisplay,
          ...testResult
        });
      } catch (error) {
        results.push({
          index: i + 1,
          keyDisplay,
          success: false,
          message: error.message,
          type: 'test_error'
        });
      }
    }

    return {
      provider,
      results
    };
  }

  async testAllProviders(config) {
    const providers = Object.keys(config.providers);
    const results = {};

    for (const provider of providers) {
      results[provider] = await this.testProviderKeys(provider, config);
    }

    return results;
  }

  getStatusIcon(result) {
    if (result.success) {
      return '✅ API可用';
    }

    switch (result.type) {
    case 'auth_failed':
      return '❌ 认证失败';
    case 'rate_limit':
      return '⚠️  速率限制';
    case 'server_error':
      return '🔧 服务器错误';
    case 'connection_error':
      return '❓ 连接错误';
    default:
      return '❓ 未知错误';
    }
  }
}

module.exports = ApiTester;