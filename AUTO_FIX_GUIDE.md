# 工作流自动化修复指南

## 🎯 功能概述

已为你的 GitHub Marketplace 扩展（`https://github.com/marketplace/gitee3`）创建了完整的自动化修复系统，能够一键检测并修复所有工作流错误。

## 🛠️ 已实现的修复功能

### 1. 自动修复脚本
- **workflow-fixer.js** - 命令行工具，自动检测并修复工作流错误
- **.github/workflows/workflow-fixer.yml** - GitHub Action 工作流，自动运行修复

### 2. 支持修复的错误类型

| 错误类型 | 检测内容 | 修复方式 |
|---------|---------|---------|
| **语法错误** | YAML 语法错误、缺失必填字段 | 自动修复语法问题 |
| **权限错误** | 缺失权限配置、空权限 | 添加完整权限配置 |
| **版本错误** | 过时的 Action 版本 | 自动更新到最新稳定版 |
| **超时错误** | 超时设置过短或缺失 | 统一设置为 30 分钟 |

## 🚀 使用方法

### 方法 1: 命令行一键修复

```bash
# 检查所有工作流错误
node workflow-fixer.js

# 自动修复所有错误
node workflow-fixer.js --fix
```

### 方法 2: GitHub Action 自动修复

1. 访问仓库的 Actions 页面
2. 选择 "Workflow Auto-Fixer"
3. 点击 "Run workflow"
4. 选择修复类型（建议选择 "all"）
5. 点击 "Run workflow"

### 方法 3: 自动触发修复

系统会在以下情况自动运行：
- 任何工作流运行完成后
- 手动触发

## 📊 修复效果

已修复的问题包括：
- ✅ 将 `actions/checkout@v3` 更新为 `v4`
- ✅ 将 `actions/setup-node@v3` 更新为 `v4`
- ✅ 修复权限配置问题
- ✅ 统一超时设置

## 🔒 安全保障

- **只读检查**：默认仅检查不修改
- **自动备份**：修复前自动创建备份
- **可回滚**：所有修改都可以通过 Git 回滚
- **最小权限**：仅修改必要的配置

## 📝 修复报告

运行修复后会生成详细报告，包括：
- 发现的错误数量
- 每个错误的位置和类型
- 修复建议
- 修复结果

## 🎯 最佳实践

1. **定期检查**：每周运行一次修复
2. **CI 集成**：在 PR 检查中添加工作流验证
3. **监控**：关注工作流运行状态
4. **更新**：定期更新 Action 版本

## 📚 相关文件

- `workflow-fixer.js` - 核心修复工具
- `.github/workflows/workflow-fixer.yml` - 自动修复工作流
- `AUTO_FIX_GUIDE.md` - 本指南

## 🤝 支持

如果在使用过程中遇到问题，请：
1. 查看修复报告
2. 检查 GitHub Actions 日志
3. 运行 `node workflow-fixer.js` 重新检查