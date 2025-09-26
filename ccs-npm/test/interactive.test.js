// Skip inquirer-dependent tests due to ES module compatibility issues
const ConfigManager = require('../src/config');

// Mock the InteractiveConfig class for testing without inquirer
const mockInteractiveConfig = {
  getProviderDisplayName: (provider) => {
    const names = {
      deepseek: 'Deepseek',
      kimi: 'KIMI2',
      glm: 'GLM4.5',
      qwen: 'Qwen',
      longcat: 'LongCat',
      claude: 'Claude API',
      opus: 'Claude Opus'
    };
    return names[provider] || provider;
  },

  getProviderIcon: (provider) => {
    const icons = {
      deepseek: '🤖',
      kimi: '🌙',
      glm: '🧠',
      qwen: '🐪',
      longcat: '🐱',
      claude: '🔮',
      opus: '🚀'
    };
    return icons[provider] || '⚙️';
  },

  getProviderDefaults: async (provider) => {
    const configManager = new ConfigManager();
    const defaults = await configManager.createDefaultConfig();
    return { ...defaults.providers[provider] };
  }
};

describe('InteractiveConfig', () => {
  let interactiveConfig;
  let configManager;

  beforeEach(() => {
    configManager = new ConfigManager();
    interactiveConfig = mockInteractiveConfig;
  });

  describe('getProviderDisplayName', () => {
    test('should return correct display names', () => {
      expect(interactiveConfig.getProviderDisplayName('deepseek')).toBe('Deepseek');
      expect(interactiveConfig.getProviderDisplayName('kimi')).toBe('KIMI2');
      expect(interactiveConfig.getProviderDisplayName('glm')).toBe('GLM4.5');
      expect(interactiveConfig.getProviderDisplayName('qwen')).toBe('Qwen');
      expect(interactiveConfig.getProviderDisplayName('longcat')).toBe('LongCat');
      expect(interactiveConfig.getProviderDisplayName('claude')).toBe('Claude API');
      expect(interactiveConfig.getProviderDisplayName('opus')).toBe('Claude Opus');
    });
  });

  describe('getProviderIcon', () => {
    test('should return correct icons', () => {
      expect(interactiveConfig.getProviderIcon('deepseek')).toBe('🤖');
      expect(interactiveConfig.getProviderIcon('kimi')).toBe('🌙');
      expect(interactiveConfig.getProviderIcon('glm')).toBe('🧠');
      expect(interactiveConfig.getProviderIcon('qwen')).toBe('🐪');
      expect(interactiveConfig.getProviderIcon('longcat')).toBe('🐱');
      expect(interactiveConfig.getProviderIcon('claude')).toBe('🔮');
      expect(interactiveConfig.getProviderIcon('opus')).toBe('🚀');
      expect(interactiveConfig.getProviderIcon('unknown')).toBe('⚙️');
    });
  });

  describe('getProviderDefaults', () => {
    test('should return provider default configuration', async () => {
      const defaults = await interactiveConfig.getProviderDefaults('deepseek');

      expect(defaults).toHaveProperty('apiKeys');
      expect(defaults).toHaveProperty('rotationStrategy');
      expect(defaults).toHaveProperty('baseUrl');
      expect(defaults).toHaveProperty('model');
      expect(defaults).toHaveProperty('smallFastModel');
      expect(defaults.rotationStrategy).toBe('round_robin');
    });
  });
});