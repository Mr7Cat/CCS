const fs = require('fs-extra');
const path = require('path');
const os = require('os');
const ConfigManager = require('../src/config');

// Mock fs-extra
jest.mock('fs-extra');

describe('ConfigManager', () => {
  let configManager;
  let mockConfigDir;

  beforeEach(() => {
    configManager = new ConfigManager();
    mockConfigDir = '/mock/home/.ccs';

    // Reset mocks
    jest.clearAllMocks();

    // Mock homedir
    jest.spyOn(os, 'homedir').mockReturnValue('/mock/home');
  });

  describe('ensureConfigDir', () => {
    it('should create config and rotation directories', async () => {
      fs.ensureDir.mockResolvedValue();

      await configManager.ensureConfigDir();

      expect(fs.ensureDir).toHaveBeenCalledWith(mockConfigDir);
      expect(fs.ensureDir).toHaveBeenCalledWith(path.join(mockConfigDir, 'rotation'));
    });
  });

  describe('loadConfig', () => {
    it('should create default config if file does not exist', async () => {
      fs.ensureDir.mockResolvedValue();
      fs.pathExists.mockResolvedValue(false);
      fs.writeJson.mockResolvedValue();

      const result = await configManager.loadConfig();

      expect(fs.writeJson).toHaveBeenCalled();
      expect(result).toHaveProperty('providers');
      expect(result.providers).toHaveProperty('deepseek');
    });

    it('should load existing config file', async () => {
      const mockConfig = {
        providers: {
          deepseek: {
            apiKeys: ['test-key'],
            rotationStrategy: 'round_robin'
          }
        }
      };

      fs.ensureDir.mockResolvedValue();
      fs.pathExists.mockResolvedValue(true);
      fs.readJson.mockResolvedValue(mockConfig);

      const result = await configManager.loadConfig();

      expect(fs.readJson).toHaveBeenCalled();
      expect(result.providers.deepseek.apiKeys).toEqual(['test-key']);
    });

    it('should merge environment variables with config', async () => {
      const mockConfig = {
        providers: {
          deepseek: {
            apiKeys: ['config-key'],
            rotationStrategy: 'round_robin'
          }
        }
      };

      process.env.DEEPSEEK_API_KEY = 'env-key';

      fs.ensureDir.mockResolvedValue();
      fs.pathExists.mockResolvedValue(true);
      fs.readJson.mockResolvedValue(mockConfig);

      const result = await configManager.loadConfig();

      expect(result.providers.deepseek.apiKeys).toEqual(['env-key']);

      delete process.env.DEEPSEEK_API_KEY;
    });
  });

  describe('rotation index management', () => {
    it('should return 0 for non-existent index file', async () => {
      fs.pathExists.mockResolvedValue(false);

      const index = await configManager.getRotationIndex('deepseek');

      expect(index).toBe(0);
    });

    it('should load existing rotation index', async () => {
      fs.pathExists.mockResolvedValue(true);
      fs.readJson.mockResolvedValue({ index: 2 });

      const index = await configManager.getRotationIndex('deepseek');

      expect(index).toBe(2);
    });

    it('should save rotation index', async () => {
      fs.ensureDir.mockResolvedValue();
      fs.writeJson.mockResolvedValue();

      await configManager.setRotationIndex('deepseek', 3);

      expect(fs.writeJson).toHaveBeenCalledWith(
        expect.stringContaining('deepseek_index.json'),
        { index: 3 },
        { spaces: 2 }
      );
    });
  });
});