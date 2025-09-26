#!/usr/bin/env node

const { Command } = require('commander');
const chalk = require('chalk');
const { spawn } = require('child_process');
const CCS = require('../src/index');
const InteractiveConfig = require('../src/interactive');

const program = new Command();

program
  .name('ccs')
  .description('Claude Code Switch - AI模型提供商切换工具')
  .version('1.0.0');

// Provider switching commands
const providers = ['deepseek', 'ds', 'kimi', 'kimi2', 'glm', 'glm4', 'glm4.5', 'qwen', 'longcat', 'lc', 'claude', 'sonnet', 's', 'opus', 'o'];

providers.forEach(provider => {
  program
    .command(provider)
    .description(`切换到 ${provider} 模型`)
    .action(async () => {
      try {
        const ccs = await new CCS().init();
        const commands = await ccs.generateExportCommands(provider);
        console.log(commands);
      } catch (error) {
        console.error(chalk.red(`❌ ${error.message}`));
        process.exit(1);
      }
    });
});

// Status command
program
  .command('status')
  .alias('st')
  .description('显示当前配置状态')
  .option('--detailed', '显示详细状态')
  .action(async (options) => {
    try {
      const ccs = await new CCS().init();
      const status = options.detailed ? await ccs.getDetailedStatus() : await ccs.getStatus();

      console.log(chalk.blue('📊 当前模型配置:'));
      console.log(`   BASE_URL: ${status.currentConfig.baseUrl}`);
      console.log(`   AUTH_TOKEN: ${status.currentConfig.authToken}`);
      console.log(`   MODEL: ${status.currentConfig.model}`);
      console.log(`   SMALL_MODEL: ${status.currentConfig.smallModel}`);
      console.log();

      console.log(chalk.blue('🔧 提供商状态:'));
      for (const [provider, info] of Object.entries(status.providers)) {
        const statusIcon = info.hasValidKeys ? '✅' : '❌';
        console.log(`   ${provider.toUpperCase()}: ${statusIcon} ${info.keyCount} keys, 策略: ${info.strategy}`);

        if (options.detailed && info.keys) {
          info.keys.forEach(key => {
            const healthIcon = key.healthy ? '✅' : '⚠️ ';
            console.log(`     [${key.index}] ${key.masked} - ${healthIcon}${key.healthy ? '健康' : '失败状态'}`);
          });
        }
      }
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Stats command
program
  .command('stats')
  .description('显示使用统计')
  .action(async () => {
    try {
      const ccs = await new CCS().init();
      const stats = await ccs.getUsageStats();

      console.log(chalk.blue('📈 使用统计:'));

      if (Object.keys(stats).length === 0) {
        console.log('   暂无使用记录');
        return;
      }

      for (const [provider, providerStats] of Object.entries(stats)) {
        console.log();
        console.log(chalk.yellow(`${provider.toUpperCase()}:`));

        for (const [keyId, keyStats] of Object.entries(providerStats)) {
          const statusIndicator = keyStats.isActive ? '[当前活跃]' : '[已移除]';
          console.log(`   Key ${keyId}: 总计 ${keyStats.total} 次, 成功率 ${keyStats.successRate}, 最后使用: ${keyStats.lastUsed} ${statusIndicator}`);
        }
      }
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Rotate command
program
  .command('rotate <provider>')
  .description('手动轮换到下一个 key')
  .action(async (provider) => {
    try {
      const ccs = await new CCS().init();
      const result = await ccs.rotateKey(provider);

      console.log(chalk.green(`✅ 已轮换 ${result.provider.toUpperCase()} 到下一个 key`));
      console.log(`   下次使用的 Key: ${result.nextKey}`);
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Test keys command
program
  .command('test-keys')
  .description('测试 API key 可用性')
  .argument('[provider]', '指定提供商（可选）')
  .action(async (provider) => {
    try {
      const ccs = await new CCS().init();
      const results = await ccs.testKeys(provider);

      if (provider) {
        // Single provider results
        console.log(chalk.yellow(`测试 ${results.provider.toUpperCase()} keys:`));

        if (results.results.length === 0) {
          console.log('   无可用 key');
          return;
        }

        for (const result of results.results) {
          const icon = ccs.apiTester.getStatusIcon(result);
          console.log(`   [${result.index}] ${result.keyDisplay} - ${icon}`);
        }

        console.log('   注意: 已进行实际 API 调用测试验证可用性');
      } else {
        // All providers results
        console.log(chalk.blue('🧪 测试所有提供商的 key...'));

        for (const [providerName, providerResults] of Object.entries(results)) {
          console.log();
          console.log(chalk.yellow(`测试 ${providerName.toUpperCase()} keys:`));

          if (providerResults.results.length === 0) {
            console.log('   无可用 key');
            continue;
          }

          for (const result of providerResults.results) {
            const icon = ccs.apiTester.getStatusIcon(result);
            console.log(`   [${result.index}] ${result.keyDisplay} - ${icon}`);
          }
        }

        console.log();
        console.log('   注意: 已进行实际 API 调用测试验证可用性');
      }
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Config command
program
  .command('config')
  .alias('cfg')
  .description('编辑配置文件')
  .option('-i, --interactive', '使用交互式配置向导')
  .action(async (options) => {
    try {
      if (options.interactive) {
        const ccs = await new CCS().init();
        const interactiveConfig = new InteractiveConfig(ccs.configManager);
        await interactiveConfig.startWizard();
        return;
      }

      const ccs = await new CCS().init();
      const configPath = await ccs.editConfig();

      console.log(chalk.blue('🔧 打开配置文件进行编辑...'));
      console.log(chalk.yellow(`配置文件路径: ${configPath}`));

      // Try to open with different editors
      const editors = [
        { cmd: 'cursor', args: [configPath] },
        { cmd: 'code', args: [configPath] },
        { cmd: 'vim', args: [configPath] },
        { cmd: 'nano', args: [configPath] }
      ];

      let opened = false;
      for (const editor of editors) {
        try {
          const child = spawn(editor.cmd, editor.args, {
            stdio: 'inherit',
            detached: process.platform !== 'win32'
          });

          if (editor.cmd === 'cursor' || editor.cmd === 'code') {
            child.unref();
            console.log(chalk.green(`✅ 使用 ${editor.cmd} 编辑器打开配置文件`));
            console.log(chalk.yellow('💡 配置文件已在编辑器中打开，编辑完成后保存即可生效'));
          } else {
            console.log(chalk.green(`✅ 使用 ${editor.cmd} 编辑器打开配置文件`));
          }

          opened = true;
          break;
        } catch (error) {
          continue;
        }
      }

      if (!opened) {
        console.log(chalk.red('❌ 未找到可用的编辑器'));
        console.log(chalk.yellow(`请手动编辑配置文件: ${configPath}`));
        console.log(chalk.yellow('或安装以下编辑器之一: cursor, code, vim, nano'));
      }
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Interactive command
program
  .command('interactive')
  .alias('i')
  .description('启动交互式配置向导')
  .action(async () => {
    try {
      const ccs = await new CCS().init();
      const interactiveConfig = new InteractiveConfig(ccs.configManager);
      await interactiveConfig.startWizard();
    } catch (error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
  });

// Env command for shell evaluation
program
  .command('env <provider>')
  .description('输出 export 语句（用于 shell eval）')
  .action(async (provider) => {
    try {
      const ccs = await new CCS().init();
      const commands = await ccs.generateExportCommands(provider);
      console.log(commands);
    } catch (error) {
      console.error(`# ❌ ${error.message}`, { stdio: 'stderr' });
      process.exit(1);
    }
  });

// Help command override to show model list
program
  .command('help')
  .description('显示帮助信息')
  .action(() => {
    console.log(chalk.blue('🔧 Claude Code Switch 工具 v1.0.0'));
    console.log();
    console.log(chalk.yellow('用法:') + ' ccs [选项]');
    console.log();
    console.log(chalk.yellow('模型选项（输出 export 语句，便于 eval）:'));
    console.log('  deepseek, ds       - 切换到 Deepseek');
    console.log('  kimi, kimi2        - 切换到 KIMI2');
    console.log('  longcat, lc        - 切换到 LongCat');
    console.log('  qwen               - 切换到 Qwen');
    console.log('  glm, glm4          - 切换到 GLM4.5');
    console.log('  claude, sonnet, s  - 切换到 Claude Sonnet');
    console.log('  opus, o            - 切换到 Claude Opus');
    console.log();
    console.log(chalk.yellow('工具选项:'));
    console.log('  status, st         - 显示当前配置（脱敏显示）');
    console.log('  status --detailed  - 显示所有 key 的详细状态');
    console.log('  env [模型]         - 仅输出 export 语句（用于 eval）');
    console.log('  config, cfg        - 编辑配置文件');
    console.log('  config -i, cfg -i  - 使用交互式配置向导');
    console.log('  interactive, i     - 启动交互式配置向导');
    console.log('  stats              - 显示使用统计');
    console.log('  rotate [提供商]    - 手动轮换到下一个 key');
    console.log('  test-keys [提供商] - 测试所有 key 的可用性');
    console.log('  help, h            - 显示此帮助信息');
    console.log();
    console.log(chalk.yellow('示例:'));
    console.log('  eval "$(ccs deepseek)"      # 在当前 shell 中生效（推荐）');
    console.log('  ccs status                  # 查看当前状态（脱敏）');
    console.log('  ccs interactive             # 启动交互式配置向导');
    console.log('  ccs config -i               # 使用交互式向导配置API');
    console.log();
    console.log(chalk.yellow('支持的模型:'));
    console.log('  🌙 KIMI2               - 官方：kimi-k2-0905-preview');
    console.log('  🤖 Deepseek            - 官方：deepseek-chat ｜ 备用：deepseek/deepseek-v3.1 (PPINFRA)');
    console.log('  🐱 LongCat             - 官方：LongCat-Flash-Thinking / LongCat-Flash-Chat');
    console.log('  🐪 Qwen                - 备用：qwen3-next-80b-a3b-thinking (PPINFRA)');
    console.log('  🇨🇳 GLM4.5             - 官方：glm-4.5 / glm-4.5-air');
    console.log('  🧠 Claude Sonnet 4     - claude-sonnet-4-20250514');
    console.log('  🚀 Claude Opus 4.1     - claude-opus-4-1-20250805');
  });

program.parse();