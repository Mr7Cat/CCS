class ProviderManager {
  constructor(configManager, keyManager) {
    this.configManager = configManager;
    this.keyManager = keyManager;
  }

  async switchToProvider(providerName, config) {
    const provider = config.providers[providerName];
    if (!provider) {
      throw new Error(`Unknown provider: ${providerName}`);
    }

    // Try to get a key from the provider
    let selectedKey = await this.keyManager.selectBestKey(providerName, config);
    let baseUrl = provider.baseUrl;
    let authHeader = 'x-api-key';

    // Handle special cases and fallbacks
    if (!selectedKey || !this.keyManager.isValidKey(selectedKey)) {
      const fallbackResult = this.handleFallback(providerName, config);
      if (fallbackResult) {
        selectedKey = fallbackResult.key;
        baseUrl = fallbackResult.baseUrl;
        authHeader = fallbackResult.authHeader;
      } else {
        throw new Error(`No valid API key found for ${providerName}`);
      }
    }

    // Handle provider-specific configurations
    const envVars = this.buildEnvironmentVariables(
      providerName,
      provider,
      selectedKey,
      baseUrl,
      authHeader
    );

    // Record usage
    if (selectedKey && this.keyManager.isValidKey(selectedKey)) {
      await this.keyManager.recordKeyUsage(providerName, selectedKey, true);
    }

    return {
      provider: providerName,
      key: this.keyManager.maskKey(selectedKey),
      envVars,
      baseUrl,
      model: provider.model,
      smallFastModel: provider.smallFastModel
    };
  }

  handleFallback(providerName, config) {
    // Check if provider supports fallback
    const provider = config.providers[providerName];
    const fallbackProvider = provider.fallbackProvider;

    if (fallbackProvider === 'ppinfra' && config.fallback.ppinfra) {
      const ppinfraKey = config.fallback.ppinfra.apiKey;
      if (this.keyManager.isValidKey(ppinfraKey)) {
        return {
          key: ppinfraKey,
          baseUrl: config.fallback.ppinfra.baseUrl,
          authHeader: 'Authorization'
        };
      }
    }

    return null;
  }

  buildEnvironmentVariables(providerName, provider, selectedKey, baseUrl, authHeader) {
    const envVars = {
      // Clear existing variables
      ANTHROPIC_BASE_URL: undefined,
      ANTHROPIC_API_URL: undefined,
      ANTHROPIC_AUTH_TOKEN: undefined,
      ANTHROPIC_API_KEY: undefined,
      ANTHROPIC_MODEL: undefined,
      ANTHROPIC_SMALL_FAST_MODEL: undefined,
      API_TIMEOUT_MS: undefined,
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: undefined
    };

    // Set provider-specific variables
    if (providerName === 'claude' || providerName === 'opus') {
      // For Claude/Opus, check if using API mode or Pro mode
      if (provider.baseUrl && provider.baseUrl !== 'https://api.anthropic.com') {
        // API mode with custom base URL
        envVars.ANTHROPIC_BASE_URL = baseUrl;
        envVars.ANTHROPIC_API_URL = baseUrl;
        envVars.ANTHROPIC_API_KEY = selectedKey;
        envVars.API_TIMEOUT_MS = '600000';
        envVars.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1';
      } else {
        // Pro mode - use Claude Pro subscription
        envVars.ANTHROPIC_MODEL = provider.model;
        envVars.ANTHROPIC_SMALL_FAST_MODEL = provider.smallFastModel;
        return envVars;
      }
    } else {
      // For other providers
      envVars.ANTHROPIC_BASE_URL = baseUrl;
      envVars.ANTHROPIC_API_URL = baseUrl;
      envVars.API_TIMEOUT_MS = '600000';
      envVars.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1';

      if (authHeader === 'Authorization') {
        envVars.ANTHROPIC_AUTH_TOKEN = selectedKey;
      } else {
        envVars.ANTHROPIC_AUTH_TOKEN = selectedKey;
        envVars.ANTHROPIC_API_KEY = selectedKey;
      }
    }

    // Set model configurations
    envVars.ANTHROPIC_MODEL = provider.model;
    envVars.ANTHROPIC_SMALL_FAST_MODEL = provider.smallFastModel;

    return envVars;
  }

  getProviderList() {
    return [
      {
        name: 'deepseek',
        aliases: ['ds'],
        description: '🤖 Deepseek - 官方：deepseek-chat ｜ 备用：deepseek/deepseek-v3.1 (PPINFRA)'
      },
      {
        name: 'kimi',
        aliases: ['kimi2'],
        description: '🌙 KIMI2 - 官方：kimi-k2-0905-preview'
      },
      {
        name: 'glm',
        aliases: ['glm4', 'glm4.5'],
        description: '🇨🇳 GLM4.5 - 官方：glm-4.5 / glm-4.5-air'
      },
      {
        name: 'qwen',
        aliases: [],
        description: '🐪 Qwen - 备用：qwen3-next-80b-a3b-thinking (PPINFRA)'
      },
      {
        name: 'longcat',
        aliases: ['lc'],
        description: '🐱 LongCat - 官方：LongCat-Flash-Thinking / LongCat-Flash-Chat'
      },
      {
        name: 'claude',
        aliases: ['sonnet', 's'],
        description: '🧠 Claude Sonnet 4 - claude-sonnet-4-20250514'
      },
      {
        name: 'opus',
        aliases: ['o'],
        description: '🚀 Claude Opus 4.1 - claude-opus-4-1-20250805'
      }
    ];
  }

  resolveProviderName(input) {
    const providers = this.getProviderList();

    // Direct match
    for (const provider of providers) {
      if (provider.name === input || provider.aliases.includes(input)) {
        return provider.name;
      }
    }

    return null;
  }

  async generateExportCommands(providerName, config) {
    const result = await this.switchToProvider(providerName, config);
    const commands = [];

    // Generate unset commands first
    commands.push('unset ANTHROPIC_BASE_URL ANTHROPIC_API_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL API_TIMEOUT_MS CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC');

    // Generate export commands
    Object.entries(result.envVars).forEach(([key, value]) => {
      if (value !== undefined) {
        commands.push(`export ${key}='${value}'`);
      }
    });

    return commands.join('\n');
  }
}

module.exports = ProviderManager;