const inquirer = require('inquirer');
const chalk = require('chalk');

class InteractiveConfig {
  constructor(configManager) {
    this.configManager = configManager;
  }

  /**
   * Start interactive configuration wizard
   */
  async startWizard() {
    console.log(chalk.blue('🚀 CCS 交互式配置向导'));
    console.log(chalk.gray('═'.repeat(50)));
    console.log();

    const { action } = await inquirer.prompt([
      {
        type: 'list',
        name: 'action',
        message: '请选择操作:',
        choices: [
          {
            name: '➕ 添加新的API配置',
            value: 'add',
            short: '添加配置'
          },
          {
            name: '✏️  编辑现有配置',
            value: 'edit',
            short: '编辑配置'
          },
          {
            name: '🗑️  删除配置',
            value: 'delete',
            short: '删除配置'
          },
          {
            name: '📋 查看当前配置',
            value: 'view',
            short: '查看配置'
          },
          {
            name: '🔄 重置为默认配置',
            value: 'reset',
            short: '重置配置'
          },
          new inquirer.Separator(),
          {
            name: '⬅️  退出',
            value: 'exit',
            short: '退出'
          }
        ]
      }
    ]);

    switch (action) {
      case 'add':
        await this.addProviderConfig();
        break;
      case 'edit':
        await this.editProviderConfig();
        break;
      case 'delete':
        await this.deleteProviderConfig();
        break;
      case 'view':
        await this.viewCurrentConfig();
        break;
      case 'reset':
        await this.resetConfig();
        break;
      case 'exit':
        console.log(chalk.yellow('👋 再见!'));
        break;
    }
  }

  /**
   * Add a new provider configuration
   */
  async addProviderConfig() {
    console.log(chalk.blue('\n➕ 添加新的API配置'));
    console.log(chalk.gray('─'.repeat(30)));

    // Select provider
    const { provider } = await inquirer.prompt([
      {
        type: 'list',
        name: 'provider',
        message: '选择API提供商:',
        choices: [
          { name: '🤖 Deepseek - 深度求索', value: 'deepseek' },
          { name: '🌙 KIMI2 - 月之暗面', value: 'kimi' },
          { name: '🧠 GLM4.5 - 智谱AI', value: 'glm' },
          { name: '🐪 Qwen - 通义千问', value: 'qwen' },
          { name: '🐱 LongCat - 美团', value: 'longcat' },
          { name: '🔮 Claude API - Anthropic', value: 'claude' },
          { name: '🚀 Claude Opus - Anthropic', value: 'opus' },
          new inquirer.Separator(),
          { name: '⬅️  返回主菜单', value: 'back' }
        ]
      }
    ]);

    if (provider === 'back') {
      return this.startWizard();
    }

    const config = await this.configManager.loadConfig();

    if (config.providers[provider] && config.providers[provider].apiKeys[0] !== `your-${provider}-api-key`) {
      const { overwrite } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'overwrite',
          message: chalk.yellow(`${this.getProviderDisplayName(provider)} 配置已存在，是否覆盖?`),
          default: false
        }
      ]);

      if (!overwrite) {
        console.log(chalk.yellow('❌ 操作已取消'));
        return this.startWizard();
      }
    }

    const providerConfig = await this.collectProviderInfo(provider);

    // Update configuration
    config.providers[provider] = providerConfig;
    await this.configManager.saveConfig(config);

    console.log(chalk.green(`\n🎉 ${this.getProviderDisplayName(provider)} 配置添加成功!`));
    this.showUsageInstructions(provider);

    // Ask if user wants to continue
    const { continue: shouldContinue } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'continue',
        message: '是否继续配置其他提供商?',
        default: false
      }
    ]);

    if (shouldContinue) {
      return this.startWizard();
    }
  }

  /**
   * Edit existing provider configuration
   */
  async editProviderConfig() {
    console.log(chalk.blue('\n✏️  编辑现有配置'));
    console.log(chalk.gray('─'.repeat(30)));

    const config = await this.configManager.loadConfig();
    const existingProviders = Object.keys(config.providers).filter(p =>
      config.providers[p].apiKeys[0] !== `your-${p}-api-key`
    );

    if (existingProviders.length === 0) {
      console.log(chalk.yellow('⚠️  暂无已配置的提供商'));
      return this.startWizard();
    }

    const choices = existingProviders.map(provider => ({
      name: `${this.getProviderIcon(provider)} ${this.getProviderDisplayName(provider)}`,
      value: provider
    }));
    choices.push(new inquirer.Separator(), { name: '⬅️  返回主菜单', value: 'back' });

    const { provider } = await inquirer.prompt([
      {
        type: 'list',
        name: 'provider',
        message: '选择要编辑的提供商:',
        choices
      }
    ]);

    if (provider === 'back') {
      return this.startWizard();
    }

    console.log(chalk.blue(`\n正在编辑 ${this.getProviderDisplayName(provider)} 配置...`));
    const providerConfig = await this.collectProviderInfo(provider, config.providers[provider]);

    config.providers[provider] = providerConfig;
    await this.configManager.saveConfig(config);

    console.log(chalk.green(`\n🎉 ${this.getProviderDisplayName(provider)} 配置更新成功!`));
    return this.startWizard();
  }

  /**
   * Delete provider configuration
   */
  async deleteProviderConfig() {
    console.log(chalk.blue('\n🗑️  删除配置'));
    console.log(chalk.gray('─'.repeat(30)));

    const config = await this.configManager.loadConfig();
    const existingProviders = Object.keys(config.providers).filter(p =>
      config.providers[p].apiKeys[0] !== `your-${p}-api-key`
    );

    if (existingProviders.length === 0) {
      console.log(chalk.yellow('⚠️  暂无已配置的提供商'));
      return this.startWizard();
    }

    const choices = existingProviders.map(provider => ({
      name: `${this.getProviderIcon(provider)} ${this.getProviderDisplayName(provider)}`,
      value: provider
    }));
    choices.push(new inquirer.Separator(), { name: '⬅️  返回主菜单', value: 'back' });

    const { provider } = await inquirer.prompt([
      {
        type: 'list',
        name: 'provider',
        message: '选择要删除的提供商:',
        choices
      }
    ]);

    if (provider === 'back') {
      return this.startWizard();
    }

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: chalk.red(`确认删除 ${this.getProviderDisplayName(provider)} 的配置?`),
        default: false
      }
    ]);

    if (confirm) {
      // Reset to default placeholder
      const defaultConfig = await this.configManager.createDefaultConfig();
      config.providers[provider] = defaultConfig.providers[provider];
      await this.configManager.saveConfig(config);

      console.log(chalk.green(`\n✅ ${this.getProviderDisplayName(provider)} 配置已删除`));
    } else {
      console.log(chalk.yellow('❌ 删除操作已取消'));
    }

    return this.startWizard();
  }

  /**
   * View current configuration
   */
  async viewCurrentConfig() {
    console.log(chalk.blue('\n📋 当前配置'));
    console.log(chalk.gray('─'.repeat(30)));

    const config = await this.configManager.loadConfig();

    for (const [provider, providerConfig] of Object.entries(config.providers)) {
      const isConfigured = providerConfig.apiKeys[0] !== `your-${provider}-api-key`;
      const status = isConfigured ? chalk.green('✅ 已配置') : chalk.yellow('⚠️  未配置');

      console.log(`\n${this.getProviderIcon(provider)} ${this.getProviderDisplayName(provider)}: ${status}`);

      if (isConfigured) {
        console.log(`   API Keys: ${providerConfig.apiKeys.length} 个`);
        console.log(`   轮换策略: ${providerConfig.rotationStrategy}`);
        console.log(`   Base URL: ${providerConfig.baseUrl}`);
        console.log(`   Model: ${providerConfig.model}`);
        console.log(`   Small Model: ${providerConfig.smallFastModel}`);
      }
    }

    console.log();
    await inquirer.prompt([
      {
        type: 'input',
        name: 'continue',
        message: '按回车键返回主菜单...',
      }
    ]);

    return this.startWizard();
  }

  /**
   * Reset configuration to defaults
   */
  async resetConfig() {
    console.log(chalk.blue('\n🔄 重置配置'));
    console.log(chalk.gray('─'.repeat(30)));

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: chalk.red('确认重置所有配置为默认值? 这将清除所有已配置的API密钥!'),
        default: false
      }
    ]);

    if (confirm) {
      await this.configManager.createDefaultConfig();
      console.log(chalk.green('\n✅ 配置已重置为默认值'));
    } else {
      console.log(chalk.yellow('❌ 重置操作已取消'));
    }

    return this.startWizard();
  }

  /**
   * Collect provider information from user
   */
  async collectProviderInfo(provider, existingConfig = null) {
    const questions = [];

    // API Keys
    questions.push({
      type: 'input',
      name: 'apiKey',
      message: '请输入API密钥:',
      default: existingConfig ? existingConfig.apiKeys[0] : undefined,
      validate: (input) => {
        if (!input || input.trim() === '') {
          return '请输入有效的API密钥';
        }
        return true;
      }
    });

    // Multiple keys support
    questions.push({
      type: 'confirm',
      name: 'hasMultipleKeys',
      message: '是否要添加多个API密钥以实现负载均衡?',
      default: existingConfig ? existingConfig.apiKeys.length > 1 : false
    });

    const answers = await inquirer.prompt(questions);

    let apiKeys = [answers.apiKey];

    if (answers.hasMultipleKeys) {
      const additionalKeys = await this.collectAdditionalKeys(existingConfig);
      if (additionalKeys.length > 0) {
        apiKeys = apiKeys.concat(additionalKeys);
      }
    }

    // Rotation strategy (only if multiple keys)
    let rotationStrategy = 'round_robin';
    if (apiKeys.length > 1) {
      const strategyAnswer = await inquirer.prompt([
        {
          type: 'list',
          name: 'strategy',
          message: '选择密钥轮换策略:',
          choices: [
            { name: '🔄 Round Robin - 循环轮换 (推荐)', value: 'round_robin' },
            { name: '⚖️  Load Balance - 负载均衡', value: 'load_balance' },
            { name: '🧠 Smart - 智能选择', value: 'smart' }
          ],
          default: existingConfig ? existingConfig.rotationStrategy : 'round_robin'
        }
      ]);
      rotationStrategy = strategyAnswer.strategy;
    }

    // Provider specific configuration
    const providerConfig = await this.getProviderDefaults(provider);

    // Custom Base URL (for some providers)
    if (provider === 'claude' || provider === 'qwen') {
      const baseUrlAnswer = await inquirer.prompt([
        {
          type: 'input',
          name: 'baseUrl',
          message: '请输入自定义Base URL (留空使用默认):',
          default: existingConfig ? existingConfig.baseUrl : providerConfig.baseUrl
        }
      ]);

      if (baseUrlAnswer.baseUrl.trim()) {
        providerConfig.baseUrl = baseUrlAnswer.baseUrl.trim();
      }
    }

    // Model configuration
    const modelAnswer = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'customizeModels',
        message: '是否要自定义模型配置?',
        default: false
      }
    ]);

    if (modelAnswer.customizeModels) {
      const modelConfig = await inquirer.prompt([
        {
          type: 'input',
          name: 'model',
          message: '主要模型ID:',
          default: existingConfig ? existingConfig.model : providerConfig.model
        },
        {
          type: 'input',
          name: 'smallFastModel',
          message: '小而快的模型ID:',
          default: existingConfig ? existingConfig.smallFastModel : providerConfig.smallFastModel
        }
      ]);

      providerConfig.model = modelConfig.model;
      providerConfig.smallFastModel = modelConfig.smallFastModel;
    }

    return {
      ...providerConfig,
      apiKeys,
      rotationStrategy
    };
  }

  /**
   * Collect additional API keys
   */
  async collectAdditionalKeys(existingConfig = null) {
    const additionalKeys = [];
    let keyIndex = 2;

    // Add existing keys (skip first one)
    if (existingConfig && existingConfig.apiKeys.length > 1) {
      for (let i = 1; i < existingConfig.apiKeys.length; i++) {
        additionalKeys.push(existingConfig.apiKeys[i]);
        keyIndex++;
      }
    }

    while (true) {
      const { additionalKey } = await inquirer.prompt([
        {
          type: 'input',
          name: 'additionalKey',
          message: `请输入第${keyIndex}个API密钥 (留空完成):`,
        }
      ]);

      if (!additionalKey || additionalKey.trim() === '') {
        break;
      }

      additionalKeys.push(additionalKey.trim());
      keyIndex++;

      if (keyIndex > 10) {
        const { continueAdding } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'continueAdding',
            message: '已添加很多密钥，是否继续添加?',
            default: false
          }
        ]);

        if (!continueAdding) {
          break;
        }
      }
    }

    return additionalKeys;
  }

  /**
   * Get provider default configuration
   */
  async getProviderDefaults(provider) {
    const defaults = await this.configManager.createDefaultConfig();
    return { ...defaults.providers[provider] };
  }

  /**
   * Get provider display name
   */
  getProviderDisplayName(provider) {
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
  }

  /**
   * Get provider icon
   */
  getProviderIcon(provider) {
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
  }

  /**
   * Show usage instructions
   */
  showUsageInstructions(provider) {
    console.log(chalk.yellow('\n💡 使用方法:'));
    console.log(chalk.blue(`   ccs ${provider}                    # 切换到 ${this.getProviderDisplayName(provider)}`));
    console.log(chalk.blue(`   eval "$(ccs ${provider})"          # 在当前shell中生效 (推荐)`));
    console.log(chalk.blue('   ccs status                      # 查看当前状态'));
    console.log(chalk.blue('   ccs test-keys                   # 测试API密钥'));
  }
}

module.exports = InteractiveConfig;