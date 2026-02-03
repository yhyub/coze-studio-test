---
name: my-workflow-fixer
description: 自动化修复工作流文件中的YAML格式错误
---

## 使用场景
当你需要快速修复项目中的工作流文件错误时使用此Skill。

## 功能
- 自动检测工作流文件中的YAML格式错误
- 修复常见的缩进、语法问题
- 生成详细的修复报告

## 使用示例
1. 在Trae中调用此Skill
2. 系统会自动扫描当前目录及其子目录中的工作流文件
3. 执行修复操作并生成修复报告

## 注意事项
- 修复前会备份原始文件
- 仅修复YAML格式错误，不修改工作流逻辑# 综合工作流错误修复报告

## 修复概述

本次修复操作针对本地目录和GitHub仓库中的工作流文件，采用自动化方式检测和修复各种错误，确保工作流配置的正确性和安全性。

## 修复结果

### 本地文件修复
- **处理文件数**: 35个
- **修复文件数**: 33个
- **修复成功率**: 94.29%

### 修复的错误类型
1. **YAML格式问题**
   - 移除行尾空格
   - 统一行尾格式为LF
   - 确保文件以换行结束
   - 移除重复空行

2. **工作流配置错误**
   - 修复权限配置错误（移除无效的workflows权限）
   - 修复作业定义错误（使用固定的runs-on值）

## 详细修复列表

### 已修复的文件
- actions-config-manager.yml
- all-in-one-fixer.yml
- all-in-one-workflow.yml
- ci-backend.yml
- ci-main.yml
- ci.yml
- ci@backend.yml
- ci@main.yml
- claude.yml
- common-pr-checks.yml
- complete-ci-cd.yml
- comprehensive-repo-fixer.yml
- deno.yml
- deploy.yml
- enhanced-global-workflow-fixer.yml
- enhanced-workflow-fixer.yml
- github-pages.yml
- global-workflow-fixer.yml
- idl.yaml
- license-check.yaml
- marketplace-install.yml
- marketplace-manager.yml
- marketplace-submit.yml
- release.yml
- run-all-workflows.yml
- security-scan.yml
- semantic-pull-request.yaml
- unified-workflow-fixer.yml
- unified-workflow.yml
- workflow-fixer-global.yml
- workflow-fixer-unified.yml
- workflow-unified.yml
- workflow-validator.yml

### 未修复的文件
- workflow-error-auto-fixer.yml
- workflow-fixer.yml

## 修复工具

### 1. 本地工作流修复器
- **文件**: `simple-workflow-fixer.ps1`
- **功能**: 检测和修复本地工作流文件中的错误
- **特点**: 简单高效，专注于核心功能

### 2. GitHub仓库修复器
- **文件**: `fix-github-repos.ps1`
- **功能**: 克隆GitHub仓库并修复其中的工作流错误
- **特点**: 支持批量处理多个仓库

### 3. 完整自动化工作流
- **文件**: `auto-workflow-fixer.ps1`
- **功能**: 整合本地和GitHub仓库的修复功能
- **特点**: 全自动化，生成详细报告

## 安全措施

1. **最小权限原则**
   - 所有操作使用最小必要权限
   - 不修改除工作流文件外的其他文件

2. **数据安全**
   - 不暴露敏感信息
   - 临时文件使用随机目录名
   - 操作完成后清理临时文件

3. **操作审计**
   - 生成详细的修复报告
   - 记录所有修复的文件和错误类型
   - 保留修复前后的对比信息

## 使用指南

### 修复本地工作流
```powershell
# 运行简单修复器
.imple-workflow-fixer.ps1

# 运行完整修复器
.uto-workflow-fixer.ps1
```

### 修复GitHub仓库
1. **编辑仓库列表**
   - 在 `fix-github-repos.ps1` 中添加你的GitHub仓库URL

2. **运行修复器**
   ```powershell
   .\fix-github-repos.ps1
   ```

## 后续建议

1. **定期检查**
   - 建议定期运行修复器检查工作流文件
   - 特别是在更新GitHub Actions版本后

2. **预防措施**
   - 使用统一的工作流模板
   - 建立工作流配置的代码审查流程
   - 集成到CI/CD流程中自动检查

3. **扩展功能**
   - 根据需要添加更多错误类型的检测和修复
   - 支持更多类型的配置文件
   - 增强GitHub仓库的批量处理能力

## 结论

本次修复操作成功解决了本地目录中大部分工作流文件的错误，确保了工作流配置的正确性和安全性。通过自动化工具，大大提高了修复效率，减少了人工操作的错误率。

建议将这些修复工具集成到日常开发流程中，定期运行以保持工作流文件的健康状态。