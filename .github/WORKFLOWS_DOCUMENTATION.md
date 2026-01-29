# GitHub 工作流文档

## 目录结构

```
.github/
├── workflows/              # 工作流文件目录
│   ├── all-in-one-fixer.yml            # 综合工作流修复器
│   ├── ci.yml                          # 基础 CI 工作流
│   ├── ci@backend.yml                  # 后端 CI 工作流
│   ├── ci@main.yml                     # 主分支 CI 工作流
│   ├── claude.yml                      # Claude 相关工作流
│   ├── common-pr-checks.yml            # PR 通用检查工作流
│   ├── complete-ci-cd.yml              # 完整 CI/CD 工作流
│   ├── comprehensive-solution.yml      # 综合解决方案工作流
│   ├── deno.yml                        # Deno 相关工作流
│   ├── deploy.yml                      # 部署工作流
│   ├── marketplace-install.yml         # 市场应用安装工作流
│   ├── marketplace-manager.yml         # 市场应用管理工作流
│   ├── marketplace-submit.yml          # 市场应用提交工作流
│   ├── release.yml                     # 发布工作流
│   ├── security-scan.yml               # 安全扫描工作流
│   ├── semantic-pull-request.yaml      # 语义化 PR 工作流
│   ├── super-automated-workflow.yml    # 超级自动化工作流
│   ├── test-action-fixer.yml           # 测试 Action 修复器
│   ├── ultimate-unified-workflow.yml   # 终极统一工作流
│   ├── workflow-fixer.yml              # 工作流修复器
│   └── workflow-validator.yml          # 工作流验证器
├── actions-config/          # Actions 配置目录
│   ├── actions.yaml                   # Actions 主配置文件
│   ├── install-action.sh               # Action 安装脚本
│   ├── security-scan.sh                # 安全扫描脚本
│   └── marketplace-actions.yaml        # 市场 Actions 配置
└── reports/                 # 报告目录
    └── COMPREHENSIVE_SOLUTION_REPORT.md  # 综合解决方案报告
```

## 工作流详细描述

### 1. all-in-one-fixer.yml
**功能**：综合工作流修复器
**用途**：自动检测和修复所有工作流文件的语法错误、权限配置问题和版本过时问题
**触发方式**：手动触发、工作流执行完成后自动触发
**主要步骤**：
- 语法错误检测和修复
- 权限配置优化
- Action 版本更新
- 自动提交和推送修复

### 2. ci.yml
**功能**：基础 CI 工作流
**用途**：执行基础的持续集成任务，包括依赖安装、构建和测试
**触发方式**：代码推送、Pull Request
**主要步骤**：
- 代码检出
- 依赖安装
- 代码构建
- 测试执行
- 质量检查

### 3. deploy.yml
**功能**：部署工作流
**用途**：将项目部署到 GitHub Pages
**触发方式**：主分支代码推送
**主要步骤**：
- 安全扫描
- 代码检出
- 部署到 GitHub Pages

### 4. security-scan.yml
**功能**：安全扫描工作流
**用途**：执行全面的安全扫描，检测潜在的安全问题
**触发方式**：代码推送、Pull Request、定时执行（每天）
**主要步骤**：
- 代码检出
- 依赖安装
- 安全扫描执行
- 扫描结果上传

### 5. marketplace-install.yml
**功能**：市场应用安装工作流
**用途**：从 GitHub Marketplace 安装安全的免费 Actions 工具
**触发方式**：代码推送、Pull Request、定时执行（每天）
**主要步骤**：
- 代码检出
- Python 环境设置
- 依赖安装
- Marketplace Actions 安装
- 安全扫描

### 6. marketplace-manager.yml
**功能**：市场应用管理工作流
**用途**：管理已安装的 Marketplace Actions，包括同步、验证、清理和审计
**触发方式**：手动触发、定时执行（每天中午）
**主要步骤**：
- 代码检出
- 环境设置（Node.js 和 Python）
- 依赖安装
- Actions 配置验证
- 同步 Marketplace Actions
- 工作流文件验证
- 非官方文件清理
- Marketplace Actions 审计

### 7. marketplace-submit.yml
**功能**：市场应用提交工作流
**用途**：将自定义 Action 提交到 GitHub Marketplace
**触发方式**：发布创建、手动触发
**主要步骤**：
- 代码检出
- 环境设置
- 依赖安装
- Action 构建
- 包验证
- Release 创建
- Marketplace 提交

### 8. release.yml
**功能**：发布工作流
**用途**：将 Action 发布到 GitHub Marketplace
**触发方式**：Release 发布
**主要步骤**：
- 代码检出
- 环境设置
- 依赖安装
- Action 构建
- Marketplace 发布

### 9. test-action-fixer.yml
**功能**：测试 Action 修复器
**用途**：测试自定义 Action 修复器的功能
**触发方式**：代码推送、Pull Request
**主要步骤**：
- 代码检出
- 环境设置
- 测试执行
- 矩阵测试（多值测试）

### 10. workflow-fixer.yml
**功能**：工作流修复器
**用途**：自动修复工作流文件的各种问题
**触发方式**：手动触发、其他工作流执行完成后
**主要步骤**：
- 代码检出
- Git 配置
- 环境设置
- 工作流文件分析
- 自动修复工作流错误
- 修复结果提交

### 11. ultimate-unified-workflow.yml
**功能**：终极统一工作流
**用途**：整合所有工作流功能，实现一站式自动化操作
**触发方式**：代码推送、Pull Request、定时执行（每天）、手动触发
**主要步骤**：
- 工作流自动修复
- 安全扫描
- CI 构建
- 部署
- 综合报告生成

## 自定义 Action

### action-fixer
**功能**：工作流自动修复器
**用途**：自动检测和修复 GitHub 工作流文件的各种问题
**位置**：`.github/actions/action-fixer/`
**文件结构**：
- `action.yml`：Action 配置文件
- `fixer.py`：修复器主脚本
- `run.sh`：运行脚本
- `README.md`：Action 文档
- `LICENSE`：许可证文件

## 配置文件

### actions.yaml
**功能**：Actions 主配置文件
**用途**：管理所有已安装的 Actions，包括版本、来源和用途
**位置**：`.github/actions-config/actions.yaml`
**主要配置项**：
- `allowed_sources`：允许的 Action 来源
- `installed_actions`：已安装的 Actions 列表
- `security_policies`：安全策略配置

### security-policy.md
**功能**：安全策略文件
**用途**：定义 Actions 使用的安全策略和最佳实践
**位置**：`.github/actions-config/security-policy.md`

## 使用指南

### 手动触发工作流

1. 打开 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 选择要运行的工作流
4. 点击 "Run workflow" 按钮
5. 选择运行模式（如适用）
6. 点击 "Run workflow" 确认

### 查看工作流执行结果

1. 打开 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 选择已执行的工作流运行
4. 查看详细的执行日志
5. 检查生成的报告和构建产物

### 查看安全扫描结果

安全扫描结果会作为构建产物上传，可以在工作流执行详情页面下载查看。

### 查看综合解决方案报告

综合解决方案报告会生成在 `.github/reports/COMPREHENSIVE_SOLUTION_REPORT.md` 文件中，包含详细的修复内容和验证结果。

## 最佳实践

### 1. Action 版本管理
- **使用固定版本**：始终使用固定版本的 Action（如 `actions/checkout@v4`）
- **定期更新**：定期检查并更新 Action 到最新稳定版本
- **避免使用 master 分支**：不要使用 `@master` 或 `@main` 作为 Action 版本

### 2. 权限配置
- **最小权限原则**：只授予工作流必要的权限
- **明确权限**：在工作流文件中明确指定权限配置
- **避免使用 write-all**：除非必要，否则不要使用 `permissions: write-all`

### 3. 工作流优化
- **缓存依赖**：使用 `actions/cache` 缓存依赖，加速构建过程
- **并行执行**：合理使用 `needs` 关键字，优化工作流执行顺序
- **设置超时**：为所有作业设置合理的超时时间
- **错误处理**：添加适当的错误处理和通知机制

### 4. 安全最佳实践
- **使用官方 Action**：优先使用官方或验证过的 Action
- **定期安全扫描**：定期运行安全扫描，检测潜在问题
- **避免硬编码**：不要在工作流文件中硬编码敏感信息
- **使用 secrets**：使用 GitHub Secrets 存储敏感信息

## 故障排除

### 常见错误及解决方案

1. **语法错误**
   - 症状：工作流执行失败，显示语法错误信息
   - 解决方案：检查 YAML 语法，确保缩进正确，使用 yq 工具验证

2. **权限错误**
   - 症状：工作流执行失败，显示权限不足错误
   - 解决方案：在工作流文件中添加适当的权限配置

3. **Action 版本错误**
   - 症状：工作流执行失败，显示 Action 版本不存在
   - 解决方案：使用正确的 Action 版本，避免使用不存在的版本

4. **网络连接错误**
   - 症状：工作流执行失败，显示网络连接超时
   - 解决方案：检查网络连接，使用国内镜像，增加超时时间

5. **依赖安装错误**
   - 症状：工作流执行失败，显示依赖安装失败
   - 解决方案：检查依赖配置，使用缓存，尝试不同的依赖源

### 调试技巧

1. **启用详细日志**：在工作流文件中添加 `run: echo "::debug::Debug message"`
2. **使用 tmate**：在工作流中使用 `mxschmitt/action-tmate` 进行实时调试
3. **分段测试**：将复杂工作流拆分为多个小步骤，逐一测试
4. **本地测试**：使用 `act` 工具在本地测试工作流

## 后续维护

### 定期维护任务

1. **每周检查**：检查工作流执行状态，确保所有工作流正常运行
2. **每月更新**：更新 Action 版本到最新稳定版
3. **季度审计**：进行全面的安全审计和性能评估
4. **半年回顾**：回顾工作流配置，优化执行流程

### 文档更新

- 当添加新的工作流文件时，更新本文档
- 当修改工作流功能时，更新相应的描述
- 当发现新的最佳实践时，更新最佳实践部分

## 结论

本仓库的 GitHub 工作流系统已经完全优化和修复，包括：

- ✅ 脚本文件换行符问题修复
- ✅ 工作流文件语法错误修复
- ✅ 权限配置问题修复
- ✅ Action 版本更新
- ✅ 工作流文件整理和优化
- ✅ 详细的文档和报告

所有工作流现在都应该能够在云端正常运行，无需手动干预。通过定期维护和遵循最佳实践，可以确保工作流系统的持续健康运行。