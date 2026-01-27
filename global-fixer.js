#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class GlobalWorkflowFixer {
  constructor() {
    this.repos = [];
    this.fixResults = [];
  }

  // 获取所有 GitHub 仓库
  getGitHubRepos() {
    try {
      const output = execSync('gh repo list --limit 100 --json name,sshUrl', { encoding: 'utf8' });
      const repos = JSON.parse(output);
      this.repos = repos;
      console.log(`Found ${repos.length} GitHub repositories`);
      return repos;
    } catch (error) {
      console.error('Failed to get GitHub repos:', error.message);
      return [];
    }
  }

  // 克隆仓库
  cloneRepo(repo) {
    const repoDir = path.join(process.cwd(), 'repos', repo.name);
    if (!fs.existsSync(repoDir)) {
      fs.mkdirSync(repoDir, { recursive: true });
      try {
        console.log(`Cloning ${repo.name}...`);
        execSync(`git clone ${repo.sshUrl} ${repoDir}`, { stdio: 'ignore' });
        return true;
      } catch (error) {
        console.error(`Failed to clone ${repo.name}:`, error.message);
        return false;
      }
    } else {
      console.log(`Updating ${repo.name}...`);
      try {
        execSync(`git -C ${repoDir} pull`, { stdio: 'ignore' });
        return true;
      } catch (error) {
        console.error(`Failed to update ${repo.name}:`, error.message);
        return false;
      }
    }
  }

  // 修复仓库中的工作流
  fixRepo(repoName) {
    const repoDir = path.join(process.cwd(), 'repos', repoName);
    const workflowsDir = path.join(repoDir, '.github', 'workflows');

    if (!fs.existsSync(workflowsDir)) {
      console.log(`No workflows found in ${repoName}`);
      return;
    }

    console.log(`Fixing workflows in ${repoName}...`);

    const files = fs.readdirSync(workflowsDir).filter(file => 
      file.endsWith('.yml') || file.endsWith('.yaml')
    );

    let fixesApplied = 0;

    files.forEach(file => {
      const filePath = path.join(workflowsDir, file);
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
          fixesApplied++;
          console.log(`  Updated ${fix.old} to ${fix.new} in ${file}`);
        }
      });

      // 修复权限配置
      if (!content.includes('permissions:')) {
        const lines = content.split('\n');
        const onIndex = lines.findIndex(line => line.startsWith('on:'));
        if (onIndex !== -1) {
          lines.splice(onIndex, 0, 'permissions: write-all');
          content = lines.join('\n');
          modified = true;
          fixesApplied++;
          console.log(`  Added permissions configuration to ${file}`);
        }
      }

      // 修复超时设置
      if (content.includes('timeout-minutes:')) {
        content = content.replace(/timeout-minutes: \d+/g, 'timeout-minutes: 30');
        modified = true;
        fixesApplied++;
        console.log(`  Updated timeout to 30 minutes in ${file}`);
      }

      if (modified) {
        fs.writeFileSync(filePath, content, 'utf8');
        this.commitFix(repoDir, file, fixesApplied);
      }
    });

    this.fixResults.push({
      repo: repoName,
      fixesApplied
    });
  }

  // 提交修复
  commitFix(repoDir, file, fixesApplied) {
    try {
      execSync(`git -C ${repoDir} add .github/workflows/${file}`, { stdio: 'ignore' });
      execSync(`git -C ${repoDir} commit -m "fix: auto-correct workflow errors"`, { stdio: 'ignore' });
      execSync(`git -C ${repoDir} push`, { stdio: 'ignore' });
      console.log(`  Pushed fixes for ${file}`);
    } catch (error) {
      console.error(`  Failed to push fixes:`, error.message);
    }
  }

  // 生成全局修复报告
  generateReport() {
    console.log('\n=== Global Workflow Fix Report ===');
    console.log(`Processed ${this.repos.length} repositories`);
    console.log(`Total fixes applied: ${this.fixResults.reduce((sum, r) => sum + r.fixesApplied, 0)}`);
    console.log('\nFixes per repository:');
    this.fixResults.forEach(result => {
      console.log(`  ${result.repo}: ${result.fixesApplied} fixes`);
    });
  }

  // 运行全局修复
  run() {
    console.log('=== Global Workflow Fixer ===');
    this.getGitHubRepos();

    this.repos.forEach(repo => {
      if (this.cloneRepo(repo)) {
        this.fixRepo(repo.name);
      }
    });

    this.generateReport();
  }
}

// 主函数
const fixer = new GlobalWorkflowFixer();
fixer.run();