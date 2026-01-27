#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

class WorkflowFixer {
  constructor() {
    this.workflowsDir = path.join(process.cwd(), '.github', 'workflows');
    this.fixes = [];
  }

  // 检查所有工作流文件
  async checkWorkflows() {
    if (!fs.existsSync(this.workflowsDir)) {
      console.error('No workflows directory found');
      return;
    }

    const files = fs.readdirSync(this.workflowsDir).filter(file => 
      file.endsWith('.yml') || file.endsWith('.yaml')
    );

    for (const file of files) {
      await this.checkWorkflowFile(file);
    }

    this.generateReport();
  }

  // 检查单个工作流文件
  async checkWorkflowFile(file) {
    const filePath = path.join(this.workflowsDir, file);
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const workflow = yaml.load(content);
      
      this.checkSyntax(workflow, file);
      this.checkPermissions(workflow, file);
      this.checkVersions(workflow, file);
      this.checkTimeouts(workflow, file);
      
    } catch (error) {
      this.fixes.push({
        file,
        type: 'syntax',
        message: `YAML syntax error: ${error.message}`,
        line: error.mark ? error.mark.line : 0
      });
    }
  }

  // 检查语法错误
  checkSyntax(workflow, file) {
    if (!workflow.on) {
      this.fixes.push({
        file,
        type: 'syntax',
        message: 'Missing "on" trigger configuration'
      });
    }

    if (!workflow.jobs) {
      this.fixes.push({
        file,
        type: 'syntax',
        message: 'Missing "jobs" configuration'
      });
    }
  }

  // 检查权限配置
  checkPermissions(workflow, file) {
    if (!workflow.permissions) {
      this.fixes.push({
        file,
        type: 'permissions',
        message: 'Missing permissions configuration'
      });
    } else if (JSON.stringify(workflow.permissions) === '{}') {
      this.fixes.push({
        file,
        type: 'permissions',
        message: 'Empty permissions configuration'
      });
    }
  }

  // 检查Action版本
  checkVersions(workflow, file) {
    const oldVersions = {
      'actions/checkout@v3': 'actions/checkout@v4',
      'actions/setup-node@v3': 'actions/setup-node@v4',
      'actions/setup-go@v4': 'actions/setup-go@v5'
    };

    Object.values(workflow.jobs || {}).forEach(job => {
      (job.steps || []).forEach(step => {
        if (step.uses && oldVersions[step.uses]) {
          this.fixes.push({
            file,
            type: 'version',
            message: `Outdated action version: ${step.uses}`,
            fix: `Update to ${oldVersions[step.uses]}`
          });
        }
      });
    });
  }

  // 检查超时设置
  checkTimeouts(workflow, file) {
    Object.values(workflow.jobs || {}).forEach(job => {
      if (!job['timeout-minutes'] || job['timeout-minutes'] < 10) {
        this.fixes.push({
          file,
          type: 'timeout',
          message: 'Timeout too short or missing'
        });
      }
    });
  }

  // 生成修复报告
  generateReport() {
    console.log('\n=== Workflow Fix Report ===');
    console.log(`Found ${this.fixes.length} issues:\n`);

    this.fixes.forEach(fix => {
      console.log(`[${fix.type}] ${fix.file}:`);
      console.log(`  ${fix.message}`);
      if (fix.fix) console.log(`  Fix: ${fix.fix}`);
      if (fix.line) console.log(`  Line: ${fix.line}`);
      console.log();
    });

    if (this.fixes.length > 0) {
      console.log('Run with --fix to apply all fixes automatically');
    }
  }

  // 自动修复所有问题
  async fixAll() {
    for (const fix of this.fixes) {
      await this.applyFix(fix);
    }
    console.log('All fixes applied successfully!');
  }

  // 应用单个修复
  async applyFix(fix) {
    const filePath = path.join(this.workflowsDir, fix.file);
    let content = fs.readFileSync(filePath, 'utf8');

    switch (fix.type) {
      case 'version':
        const oldVersion = fix.message.match(/Outdated action version: (.*)/)[1];
        const newVersion = fix.fix.match(/Update to (.*)/)[1];
        content = content.replace(oldVersion, newVersion);
        break;
        
      case 'permissions':
        if (!content.includes('permissions:')) {
          content = `permissions: write-all\n${content}`;
        }
        break;
        
      case 'timeout':
        content = content.replace(/timeout-minutes: \d+/g, 'timeout-minutes: 30');
        break;
    }

    fs.writeFileSync(filePath, content, 'utf8');
  }
}

// 主函数
async function main() {
  const fixer = new WorkflowFixer();
  await fixer.checkWorkflows();

  if (process.argv.includes('--fix')) {
    await fixer.fixAll();
  }
}

main().catch(console.error);