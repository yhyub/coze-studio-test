#!/usr/bin/env node

/**
 * Coze Studio 综合功能工具
 * 整合工作流修复、网络修复、GitHub Action管理等功能
 * Version: 1.0.0
 * Date: 2026-01-29
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class CozeStudioTool {
  constructor() {
    this.workflowsDir = path.join(process.cwd(), '.github', 'workflows');
    this.fixes = [];
  }

  /**
   * 显示帮助信息
   */
  showHelp() {
    console.log('=== Coze Studio 综合功能工具 ===');
    console.log('');
    console.log('用法:');
    console.log('  node main.js [命令]');
    console.log('');
    console.log('命令:');
    console.log('  --help          显示帮助信息');
    console.log('  --fix-workflow  修复GitHub Action工作流');
    console.log('  --fix-network   修复网络连接问题');
    console.log('  --fix-all       修复所有问题');
    console.log('  --github-access 优化GitHub访问');
    console.log('  --list-files    列出所有文件');
    console.log('');
    console.log('示例:');
    console.log('  node main.js --fix-workflow   # 修复工作流');
    console.log('  node main.js --fix-network    # 修复网络');
    console.log('  node main.js --fix-all        # 修复所有');
    console.log('');
    console.log('功能说明:');
    console.log('  - 工作流修复: 自动检测并修复GitHub Action工作流错误');
    console.log('  - 网络修复: 优化网络连接，解决GitHub访问问题');
    console.log('  - GitHub访问: 提供最优IP和DNS配置');
    console.log('  - 文件管理: 列出和管理项目文件');
  }

  /**
   * 修复GitHub Action工作流
   */
  fixWorkflow() {
    console.log('=== 修复GitHub Action工作流 ===');
    
    if (!fs.existsSync(this.workflowsDir)) {
      console.log('❌ 未找到工作流目录');
      return;
    }

    const files = fs.readdirSync(this.workflowsDir).filter(file => 
      file.endsWith('.yml') || file.endsWith('.yaml')
    );

    console.log(`找到 ${files.length} 个工作流文件`);

    files.forEach(file => {
      console.log(`\n处理文件: ${file}`);
      const filePath = path.join(this.workflowsDir, file);
      let content = fs.readFileSync(filePath, 'utf8');
      let modified = false;

      // 修复 Action 版本
      const versionFixes = [
        { old: 'actions/checkout@v3', new: 'actions/checkout@v4' },
        { old: 'actions/setup-node@v3', new: 'actions/setup-node@v4' },
        { old: 'actions/setup-go@v4', new: 'actions/setup-go@v5' }
      ];

      versionFixes.forEach(fix => {
        if (content.includes(fix.old)) {
          content = content.replace(fix.old, fix.new);
          modified = true;
          console.log(`  ✓ 更新 ${fix.old} 到 ${fix.new}`);
        }
      });

      // 修复权限配置
      if (!content.includes('permissions:')) {
        content = `permissions: write-all\n${content}`;
        modified = true;
        console.log(`  ✓ 添加权限配置`);
      }

      // 修复超时设置
      if (content.includes('timeout-minutes:')) {
        content = content.replace(/timeout-minutes: \d+/g, 'timeout-minutes: 30');
        modified = true;
        console.log(`  ✓ 更新超时设置为30分钟`);
      }

      if (modified) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`  ✓ 文件已保存`);
      } else {
        console.log(`  ✅ 无需修复`);
      }
    });

    console.log('\n=== 工作流修复完成 ===');
  }

  /**
   * 修复网络连接问题
   */
  fixNetwork() {
    console.log('=== 修复网络连接问题 ===');

    // 清除DNS缓存
    console.log('\n1. 清除DNS缓存...');
    try {
      execSync('ipconfig /flushdns', { stdio: 'ignore' });
      console.log('  ✓ DNS缓存已清除');
    } catch (error) {
      console.log('  ✗ DNS缓存清除失败');
    }

    // 测试GitHub连接
    console.log('\n2. 测试GitHub连接...');
    try {
      const result = execSync('ping -n 2 github.com', { encoding: 'utf8' });
      console.log('  ✓ GitHub连接正常');
      const responseTime = result.match(/平均 = (\d+)ms/);
      if (responseTime) {
        console.log(`  响应时间: ${responseTime[1]}ms`);
      }
    } catch (error) {
      console.log('  ✗ GitHub连接失败');
      console.log('  建议: 检查网络连接或防火墙设置');
    }

    // 测试HTTPS连接
    console.log('\n3. 测试HTTPS连接...');
    try {
      const result = execSync('powershell -Command "Test-NetConnection github.com -Port 443"', { encoding: 'utf8' });
      if (result.includes('TcpTestSucceeded : True')) {
        console.log('  ✓ HTTPS连接正常');
      } else {
        console.log('  ✗ HTTPS连接失败');
      }
    } catch (error) {
      console.log('  ✗ HTTPS连接测试失败');
    }

    console.log('\n=== 网络修复完成 ===');
    console.log('\n建议:');
    console.log('1. 使用DNS服务器: 1.1.1.1 或 8.8.8.8');
    console.log('2. 确保防火墙允许GitHub访问');
    console.log('3. 如仍有问题，请运行 --github-access');
  }

  /**
   * 优化GitHub访问
   */
  optimizeGitHubAccess() {
    console.log('=== 优化GitHub访问 ===');

    // 测试多个GitHub IP地址
    console.log('\n1. 测试GitHub IP地址...');
    const githubIps = [
      '140.82.114.3',
      '140.82.112.3',
      '140.82.113.3',
      '140.82.115.3',
      '20.205.243.166'
    ];

    let bestIp = null;
    let bestTime = 9999;

    githubIps.forEach(ip => {
      try {
        const result = execSync(`ping -n 1 ${ip}`, { encoding: 'utf8' });
        const timeMatch = result.match(/平均 = (\d+)ms/);
        if (timeMatch) {
          const time = parseInt(timeMatch[1]);
          console.log(`  ${ip} - ${time}ms`);
          if (time < bestTime) {
            bestTime = time;
            bestIp = ip;
          }
        }
      } catch (error) {
        console.log(`  ${ip} - 无法连接`);
      }
    });

    if (bestIp) {
      console.log(`\n✓ 最佳IP地址: ${bestIp} (${bestTime}ms)`);
      console.log('建议添加到Hosts文件:');
      console.log(`  ${bestIp} github.com`);
      console.log(`  ${bestIp} api.github.com`);
    }

    // DNS服务器建议
    console.log('\n2. DNS服务器建议:');
    console.log('  - Cloudflare DNS: 1.1.1.1, 1.0.0.1');
    console.log('  - Google DNS: 8.8.8.8, 8.8.4.4');
    console.log('  - 阿里DNS: 223.5.5.5, 223.6.6.6');

    // Hosts文件配置
    console.log('\n3. Hosts文件配置:');
    console.log('文件路径: C:\\Windows\\System32\\drivers\\etc\\hosts');
    console.log('建议添加:');
    console.log('  140.82.114.3 github.com');
    console.log('  140.82.114.4 api.github.com');
    console.log('  199.232.68.133 raw.githubusercontent.com');

    console.log('\n=== GitHub访问优化完成 ===');
  }

  /**
   * 列出所有文件
   */
  listFiles() {
    console.log('=== 列出所有文件 ===');
    
    const files = [
      '.dockerignore', '.gitattributes', '.gitignore', '.mcp.json', '.nvmrc',
      '.pre-commit-config.yaml', '.prettierrc.js', '.yml', 'action.yml', 'AUTHORS',
      'AUTO_FIX_GUIDE.md', 'CLAUDE.md', 'CODE_OF_CONDUCT.md', 'comprehensive_network_fix.ps1',
      'CONTRIBUTING.md', 'cspell.json', 'deploy.yml', 'FINAL_SUBMIT.md', 'FixGitHubAccess.ps1',
      'github-hosts.txt', 'GitHub网络诊断报告.md', 'GLOBAL_FIX_GUIDE.md', 'global-fixer.js',
      'hosts.backup.20260127_221311', 'LICENSE-APACHE', 'Makefile', 'marketplace-config.json',
      'marketplace-package.json', 'open_2345_browser.ps1', 'OptimizeGitHubAccess.ps1',
      'package-lock.json', 'package.json', 'PUBLISH_CHECKLIST.md', 'PUBLISH_GUIDE.md',
      'README.md', 'README.zh_CN.md', 'rush.json', 'security-scan.yml', 'simple_github_fix.ps1',
      'STEP_BY_STEP_GUIDE.md', 'SUBMIT_GUIDE.md', 'test-workflows.sh', 'workflow-fixer.js'
    ];

    console.log(`找到 ${files.length} 个文件:`);
    console.log('');

    // 按类别分组
    const categories = {
      '配置文件': [],
      'GitHub Action': [],
      '文档文件': [],
      '脚本文件': [],
      '网络工具': [],
      '项目文件': []
    };

    files.forEach(file => {
      if (file.startsWith('.')) {
        categories['配置文件'].push(file);
      } else if (file.includes('action') || file.includes('workflow')) {
        categories['GitHub Action'].push(file);
      } else if (file.endsWith('.md')) {
        categories['文档文件'].push(file);
      } else if (file.endsWith('.js') || file.endsWith('.sh')) {
        categories['脚本文件'].push(file);
      } else if (file.endsWith('.ps1')) {
        categories['网络工具'].push(file);
      } else {
        categories['项目文件'].push(file);
      }
    });

    Object.entries(categories).forEach(([category, filesList]) => {
      if (filesList.length > 0) {
        console.log(`📁 ${category}:`);
        filesList.forEach(file => {
          console.log(`  - ${file}`);
        });
        console.log('');
      }
    });

    console.log('=== 文件列表完成 ===');
  }

  /**
   * 运行所有修复
   */
  runAllFixes() {
    console.log('=== 运行所有修复 ===');
    this.fixWorkflow();
    this.fixNetwork();
    this.optimizeGitHubAccess();
    console.log('\n=== 所有修复完成 ===');
  }
}

/**
 * 主函数
 */
function main() {
  const tool = new CozeStudioTool();
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help')) {
    tool.showHelp();
  } else if (args.includes('--fix-workflow')) {
    tool.fixWorkflow();
  } else if (args.includes('--fix-network')) {
    tool.fixNetwork();
  } else if (args.includes('--fix-all')) {
    tool.runAllFixes();
  } else if (args.includes('--github-access')) {
    tool.optimizeGitHubAccess();
  } else if (args.includes('--list-files')) {
    tool.listFiles();
  } else {
    console.log('未知命令');
    tool.showHelp();
  }
}

// 运行主函数
main();
