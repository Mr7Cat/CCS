const KeyManager = require('../src/keyManager');

describe('KeyManager', () => {
  let keyManager;
  let mockConfigManager;

  beforeEach(() => {
    mockConfigManager = {
      loadKeyStatus: jest.fn(),
      saveKeyStatus: jest.fn(),
      loadUsageStats: jest.fn(),
      saveUsageStats: jest.fn(),
      getRotationIndex: jest.fn(),
      setRotationIndex: jest.fn()
    };

    keyManager = new KeyManager(mockConfigManager);
  });

  describe('isValidKey', () => {
    it('should return false for invalid keys', () => {
      expect(keyManager.isValidKey('')).toBe(false);
      expect(keyManager.isValidKey(null)).toBe(false);
      expect(keyManager.isValidKey('your-key')).toBe(false);
      expect(keyManager.isValidKey('short')).toBe(false);
    });

    it('should return true for valid keys', () => {
      expect(keyManager.isValidKey('sk-valid-key-123456789')).toBe(true);
      expect(keyManager.isValidKey('api-key-abcdefghijk')).toBe(true);
    });
  });

  describe('getAvailableKeys', () => {
    it('should return filtered valid keys', () => {
      const config = {
        providers: {
          deepseek: {
            apiKeys: ['sk-valid-key', 'your-invalid-key', 'sk-another-valid-key']
          }
        }
      };

      const keys = keyManager.getAvailableKeys('deepseek', config);

      expect(keys).toEqual(['sk-valid-key', 'sk-another-valid-key']);
    });

    it('should return empty array for non-existent provider', () => {
      const config = { providers: {} };
      const keys = keyManager.getAvailableKeys('nonexistent', config);

      expect(keys).toEqual([]);
    });
  });

  describe('isKeyHealthy', () => {
    it('should return true for healthy keys', async () => {
      mockConfigManager.loadKeyStatus.mockResolvedValue({});

      const isHealthy = await keyManager.isKeyHealthy('deepseek', 'test-key');

      expect(isHealthy).toBe(true);
    });

    it('should return false for recently failed keys', async () => {
      const failedAt = Date.now() - 10 * 60 * 1000; // 10 minutes ago
      const keyId = keyManager.getKeyId('test-key');

      mockConfigManager.loadKeyStatus.mockResolvedValue({
        deepseek: {
          [keyId]: {
            status: 'failed',
            failedAt
          }
        }
      });

      const isHealthy = await keyManager.isKeyHealthy('deepseek', 'test-key', 30);

      expect(isHealthy).toBe(false);
    });

    it('should return true for keys that failed long ago', async () => {
      const failedAt = Date.now() - 60 * 60 * 1000; // 1 hour ago
      const keyId = keyManager.getKeyId('test-key');

      mockConfigManager.loadKeyStatus.mockResolvedValue({
        deepseek: {
          [keyId]: {
            status: 'failed',
            failedAt
          }
        }
      });

      const isHealthy = await keyManager.isKeyHealthy('deepseek', 'test-key', 30);

      expect(isHealthy).toBe(true);
    });
  });

  describe('selectKeyRoundRobin', () => {
    it('should return single key if only one available', async () => {
      const keys = ['single-key'];

      const selected = await keyManager.selectKeyRoundRobin('deepseek', keys);

      expect(selected).toBe('single-key');
    });

    it('should rotate through keys', async () => {
      const keys = ['key1', 'key2', 'key3'];
      mockConfigManager.getRotationIndex.mockResolvedValue(1);
      mockConfigManager.setRotationIndex.mockResolvedValue();

      const selected = await keyManager.selectKeyRoundRobin('deepseek', keys);

      expect(selected).toBe('key2');
      expect(mockConfigManager.setRotationIndex).toHaveBeenCalledWith('deepseek', 2);
    });

    it('should wrap around when reaching end of keys', async () => {
      const keys = ['key1', 'key2', 'key3'];
      mockConfigManager.getRotationIndex.mockResolvedValue(2);
      mockConfigManager.setRotationIndex.mockResolvedValue();

      const selected = await keyManager.selectKeyRoundRobin('deepseek', keys);

      expect(selected).toBe('key3');
      expect(mockConfigManager.setRotationIndex).toHaveBeenCalledWith('deepseek', 0);
    });
  });

  describe('recordKeyUsage', () => {
    it('should record key usage statistics', async () => {
      const stats = {};
      mockConfigManager.loadUsageStats.mockResolvedValue(stats);
      mockConfigManager.saveUsageStats.mockResolvedValue();

      await keyManager.recordKeyUsage('deepseek', 'test-key', true);

      expect(mockConfigManager.saveUsageStats).toHaveBeenCalled();
      const savedStats = mockConfigManager.saveUsageStats.mock.calls[0][0];
      const keyId = keyManager.getKeyId('test-key');

      expect(savedStats.deepseek[keyId].total).toBe(1);
      expect(savedStats.deepseek[keyId].success).toBe(1);
    });
  });

  describe('maskKey', () => {
    it('should mask short keys', () => {
      expect(keyManager.maskKey('short')).toBe('[已设置] ****');
    });

    it('should mask long keys showing first and last 4 characters', () => {
      const longKey = 'sk-abcdefghijklmnopqrstuvwxyz';
      const masked = keyManager.maskKey(longKey);

      expect(masked).toBe('[已设置] sk-a...wxyz');
    });

    it('should handle empty or null keys', () => {
      expect(keyManager.maskKey('')).toBe('[未设置]');
      expect(keyManager.maskKey(null)).toBe('[未设置]');
    });
  });
});