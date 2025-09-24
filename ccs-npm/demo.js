#!/usr/bin/env node

// Demo script to showcase CCS npm package functionality

const CCS = require('./src/index');

async function demo() {
  console.log('🚀 Claude Code Switch (NPM版本) 演示\n');

  try {
    // Initialize CCS
    console.log('1. 初始化 CCS...');
    const ccs = await new CCS().init();
    console.log('✅ CCS 初始化完成\n');

    // Show provider list
    console.log('2. 支持的提供商:');
    const providers = ccs.getProviderList();
    providers.forEach(provider => {
      console.log(`   ${provider.description}`);
    });
    console.log();

    // Show current status
    console.log('3. 当前状态:');
    const status = await ccs.getStatus();
    console.log(`   BASE_URL: ${status.currentConfig.baseUrl}`);
    console.log(`   AUTH_TOKEN: ${status.currentConfig.authToken}`);
    console.log(`   MODEL: ${status.currentConfig.model}`);
    console.log();

    // Show provider configurations
    console.log('4. 提供商配置状态:');
    for (const [provider, info] of Object.entries(status.providers)) {
      const statusIcon = info.hasValidKeys ? '✅' : '❌';
      console.log(`   ${provider.toUpperCase()}: ${statusIcon} ${info.keyCount} keys, 策略: ${info.strategy}`);
    }
    console.log();

    // Show usage stats
    console.log('5. 使用统计:');
    const stats = await ccs.getUsageStats();
    if (Object.keys(stats).length === 0) {
      console.log('   暂无使用记录');
    } else {
      console.log('   有使用记录（详情请运行 ccs stats 查看）');
    }
    console.log();

    // Generate example export commands
    console.log('6. 示例：生成 Deepseek 切换命令:');
    try {
      const commands = await ccs.generateExportCommands('deepseek');
      console.log('   生成的环境变量设置命令:');
      console.log('   ' + commands.split('\n').join('\n   '));
    } catch (error) {
      console.log(`   ❌ ${error.message}`);
      console.log('   (这是预期的，因为没有配置有效的 API key)');
    }
    console.log();

    // Configuration path
    console.log('7. 配置文件位置:');
    const configPath = await ccs.editConfig();
    console.log(`   ${configPath}`);
    console.log('   (使用 ccs config 编辑配置文件)');
    console.log();

    console.log('🎉 演示完成！');
    console.log('\n📖 使用说明:');
    console.log('   1. 运行 "ccs config" 编辑配置文件');
    console.log('   2. 添加你的 API keys');
    console.log('   3. 使用 "eval \\"$(ccs deepseek)\\"" 切换模型');
    console.log('   4. 使用 "ccs status" 查看状态');
    console.log('   5. 使用 "ccs help" 查看完整帮助');

  } catch (error) {
    console.error('❌ 演示过程中出错:', error.message);
  }
}

demo();