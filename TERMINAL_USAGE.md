# 终端配置文件使用说明

## 概述

本目录包含了完美复刻本地 Windows PowerShell 终端和 Node.js command prompt 终端的配置文件，支持在 GitHub Actions 中使用与本地相同的终端命令和环境。同时，提供了与 pre-commit.ci 集成的自动化安全扫描和修复功能，确保终端配置文件符合安全要求并自动修复所有错误。

## 目录结构

```
.github/actions-config/
├── actions.yaml              # 主配置文件，管理所有已安装的 Actions 和终端配置
├── powershell-terminal.yml   # PowerShell 终端配置文件
├── nodejs-command-prompt.yml # Node.js command prompt 终端配置文件
├── terminal-examples.yml     # 终端使用示例工作流
├── terminal-security-scan.sh # 终端配置文件安全扫描脚本
├── terminal-auto-fix.sh      # 终端配置文件自动修复脚本
├── .pre-commit-config.yaml   # pre-commit 配置文件
├── .yamllint                 # YAML  lint 配置文件
└── TERMINAL_USAGE.md         # 本使用说明文档
```

## 终端配置文件说明

### 1. PowerShell 终端配置

**文件**: `powershell-terminal.yml`

**描述**: 完美复刻本地 Windows PowerShell 终端的使用体验，支持在 GitHub Actions 中使用与本地相同的 PowerShell 命令和环境。

**主要功能**:
- 复刻本地 Windows PowerShell 环境变量
- 配置 PowerShell 执行策略
- 创建 PowerShell 配置文件，包含常用别名和函数
- 安装常用 PowerShell 模块（如 PSReadLine、PSScriptAnalyzer）
- 验证 PowerShell 配置

### 2. Node.js Command Prompt 终端配置

**文件**: `nodejs-command-prompt.yml`

**描述**: 完美复刻本地 Node.js command prompt 终端的使用体验，支持在 GitHub Actions 中使用与本地相同的 Node.js 命令和环境。

**主要功能**:
- 复刻本地 Node.js command prompt 环境变量
- 安装 Node.js 和常用 npm 工具
- 配置 npm 环境和全局安装路径
- 创建命令提示符配置文件
- 验证 Node.js 配置

## 在 GitHub Actions 中使用终端配置

### 1. 直接使用终端配置文件

```yaml
jobs:
  test:
    runs-on: windows-latest
    defaults:
      run:
        shell: powershell  # 或 shell: cmd
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: 测试 PowerShell 命令
        run: |
          Write-Host "Hello from PowerShell!"
          Get-ChildItem

      - name: 测试 Node.js 命令
        shell: cmd
        run: |
          echo Hello from Node.js!
          node --version
```

### 2. 使用示例工作流

运行 `terminal-examples.yml` 工作流，测试终端配置文件的功能：

```bash
# 在 GitHub 仓库页面手动触发 workflow_dispatch 事件
# 或使用 GitHub CLI 触发
gh workflow run terminal-examples.yml --ref main
```

## 安全扫描和自动修复

### 1. 运行安全扫描

**手动运行**:

```bash
# 进入配置目录
cd .github/actions-config

# 运行终端配置文件安全扫描
./terminal-security-scan.sh

# 显示详细输出并保存日志
./terminal-security-scan.sh -v -l

# 只扫描指定终端配置文件
./terminal-security-scan.sh -t powershell-terminal
```

### 2. 运行自动修复

**手动运行**:

```bash
# 进入配置目录
cd .github/actions-config

# 运行终端配置文件自动修复
./terminal-auto-fix.sh

# 显示详细输出并保存日志
./terminal-auto-fix.sh -v -l

# 只修复指定终端配置文件
./terminal-auto-fix.sh -t powershell-terminal
```

### 3. 与 pre-commit.ci 集成

**配置步骤**:

1. 确保 `.pre-commit-config.yaml` 文件存在且配置正确
2. 在 GitHub 仓库中启用 pre-commit.ci 应用
3. 提交更改时，pre-commit.ci 会自动运行安全扫描和自动修复

**pre-commit.ci 会自动**:
- 检查 YAML 语法错误
- 扫描终端配置文件中的安全问题
- 自动修复发现的错误
- 提交修复后的更改

## 与 pre-commit.ci 集成的自动化操作

### 1. 自动安全扫描

pre-commit.ci 会在每次提交时自动运行 `terminal-security-scan.sh` 脚本，扫描终端配置文件中的安全问题，包括：

- 文件权限问题
- 敏感信息泄露
- YAML 语法错误
- 硬编码路径问题
- Shell 配置问题

### 2. 自动错误修复

pre-commit.ci 会在每次提交时自动运行 `terminal-auto-fix.sh` 脚本，自动修复发现的错误，包括：

- 修复文件权限
- 移除敏感信息
- 修复 YAML 语法错误
- 修复缩进问题
- 确保文件以换行符结尾
- 修复路径分隔符
- 确保正确的 shell 配置

### 3. 完整错误内容显示

pre-commit.ci 会在扫描和修复过程中显示完整的错误内容，包括：

- 错误类型和位置
- 修复前的内容
- 修复后的内容
- 修复结果状态

## 常见问题和解决方案

### 1. 终端配置文件不存在

**问题**: 运行安全扫描时提示终端配置文件不存在

**解决方案**:
```bash
# 检查文件是否存在
ls -la .github/actions-config/

# 如果文件不存在，重新创建
cp .github/actions-config/powershell-terminal.yml.example .github/actions-config/powershell-terminal.yml
```

### 2. 安全扫描失败

**问题**: 安全扫描脚本执行失败

**解决方案**:
```bash
# 检查脚本权限
chmod +x .github/actions-config/terminal-security-scan.sh

# 检查脚本依赖
which bash
which grep
which sed
```

### 3. 自动修复失败

**问题**: 自动修复脚本执行失败

**解决方案**:
```bash
# 检查脚本权限
chmod +x .github/actions-config/terminal-auto-fix.sh

# 检查 Python 是否可用（用于修复 YAML 缩进）
python3 --version

# 查看日志文件了解具体错误
cat logs/terminal-auto-fix-*.log
```

### 4. pre-commit.ci 集成失败

**问题**: pre-commit.ci 未自动运行或运行失败

**解决方案**:
1. 确保在 GitHub 仓库中启用了 pre-commit.ci 应用
2. 检查 `.pre-commit-config.yaml` 文件配置是否正确
3. 确保脚本文件有执行权限
4. 查看 pre-commit.ci 日志了解具体错误

## 高级配置

### 1. 自定义终端配置

**修改 PowerShell 终端配置**:

```yaml
# 在 powershell-terminal.yml 中修改
runs-on:
  - windows-latest

defaults:
  run:
    shell: powershell

env:
  # 添加自定义环境变量
  CUSTOM_VAR: "custom_value"

steps:
  # 添加自定义步骤
  - name: 自定义步骤
    run: |
      Write-Host "Custom step executed!"
```

**修改 Node.js command prompt 终端配置**:

```yaml
# 在 nodejs-command-prompt.yml 中修改
runs-on:
  - windows-latest

defaults:
  run:
    shell: cmd

env:
  # 添加自定义环境变量
  CUSTOM_VAR: "custom_value"

steps:
  # 添加自定义步骤
  - name: 自定义步骤
    run: |
      echo Custom step executed!
```

### 2. 扩展安全扫描规则

**修改安全扫描脚本**:

```bash
# 编辑 terminal-security-scan.sh 文件
# 添加自定义扫描规则
```

**修改 YAML lint 规则**:

```yaml
# 在 .yamllint 文件中添加自定义规则
rules:
  # 现有规则...
  
  # 添加自定义规则
  custom-rule:
    level: error
```

## 最佳实践

1. **定期运行安全扫描**: 确保终端配置文件符合安全要求
2. **使用自动修复**: 及时修复发现的错误，保持配置文件的正确性
3. **启用 pre-commit.ci**: 实现自动化的安全扫描和修复
4. **备份配置文件**: 在修改前创建备份，防止意外错误
5. **遵循 YAML 最佳实践**: 使用正确的缩进和语法，确保配置文件的可读性
6. **避免硬编码敏感信息**: 使用 GitHub Secrets 存储敏感信息
7. **使用固定版本**: 为 Actions 和依赖项指定固定版本，避免不可预测的更新

## 联系信息

如有任何问题或建议，请联系仓库管理员。

---

**最后更新时间**: $(date +"%Y-%m-%d %H:%M:%S")
