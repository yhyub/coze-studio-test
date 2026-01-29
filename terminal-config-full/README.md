# GitHub 云端仓库终端功能包

## 概述

本文件夹包含了完美复刻本地 Windows PowerShell 终端和 Node.js command prompt 终端的完整配置，支持在 GitHub Actions 中使用与本地相同的终端命令和环境。同时，提供了与 pre-commit.ci 集成的自动化安全扫描和修复功能，确保终端配置文件符合安全要求并自动修复所有错误。

## 目录结构

```
terminal-config-full/
├── actions.yaml              # 主配置文件，管理所有已安装的 Actions 和终端配置
├── powershell-terminal.yml   # PowerShell 终端配置文件
├── nodejs-command-prompt.yml # Node.js command prompt 终端配置文件
├── terminal-examples.yml     # 终端使用示例工作流
├── terminal-security-scan.sh # 终端配置文件安全扫描脚本
├── terminal-auto-fix.sh      # 终端配置文件自动修复脚本
├── .pre-commit-config.yaml   # pre-commit 配置文件
├── .yamllint                 # YAML lint 配置文件
├── TERMINAL_USAGE.md         # 终端使用详细说明
└── README.md                 # 本说明文档
```

## 功能特性

### 1. 完美复刻本地终端

- **PowerShell 终端**：完美复刻本地 Windows PowerShell 终端的使用体验，包括：
  - 环境变量配置
  - PowerShell 执行策略设置
  - 配置文件创建（包含常用别名和函数）
  - 常用 PowerShell 模块安装

- **Node.js command prompt 终端**：完美复刻本地 Node.js command prompt 终端的使用体验，包括：
  - Node.js 安装和配置
  - npm 工具安装和配置
  - 环境变量设置
  - 命令提示符配置

### 2. 自动化安全扫描与修复

- **自动安全扫描**：与 pre-commit.ci 集成，自动扫描终端配置文件中的安全问题：
  - 文件权限问题
  - 敏感信息泄露
  - YAML 语法错误
  - 硬编码路径问题
  - Shell 配置问题

- **自动错误修复**：自动修复发现的错误：
  - 修复文件权限
  - 移除敏感信息
  - 修复 YAML 语法错误
  - 修复缩进问题
  - 确保文件以换行符结尾
  - 修复路径分隔符
  - 确保正确的 shell 配置

### 3. 完整错误内容显示

- **详细错误信息**：完整捕获并显示终端运行时的全部错误内容：
  - 错误类型和位置
  - 修复前的内容
  - 修复后的内容
  - 修复结果状态

## 安装与配置

### 1. 安装到 GitHub 仓库

1. 将本文件夹中的所有文件复制到您的 GitHub 仓库的 `.github/actions-config/` 目录中：

```bash
# 复制文件到 GitHub 仓库
cp -r terminal-config-full/* /path/to/your/repo/.github/actions-config/
```

2. 确保脚本文件有执行权限：

```bash
# 设置执行权限
chmod +x /path/to/your/repo/.github/actions-config/terminal-security-scan.sh
chmod +x /path/to/your/repo/.github/actions-config/terminal-auto-fix.sh
```

### 2. 与 pre-commit.ci 集成

1. 在 GitHub 仓库中启用 pre-commit.ci 应用：
   - 访问 https://pre-commit.ci/
   - 点击 "Sign in with GitHub"
   - 授权 pre-commit.ci 访问您的仓库
   - 启用您的仓库

2. 提交更改：
   - pre-commit.ci 会在每次提交时自动运行安全扫描和修复
   - 修复后的更改会自动提交

## 使用方法

### 1. 在 GitHub Actions 中使用终端配置

**使用 PowerShell 终端**：

```yaml
jobs:
  test:
    runs-on: windows-latest
    defaults:
      run:
        shell: powershell
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: 测试 PowerShell 命令
        run: |
          Write-Host "Hello from PowerShell!"
          Get-ChildItem
          # 其他 PowerShell 命令...
```

**使用 Node.js command prompt 终端**：

```yaml
jobs:
  test:
    runs-on: windows-latest
    defaults:
      run:
        shell: cmd
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: 安装 Node.js
        uses: actions/setup-node@v5
        with:
          node-version: '20'
      - name: 测试 Node.js 命令
        run: |
          echo Hello from Node.js!
          node --version
          npm --version
          # 其他 Node.js 命令...
```

### 2. 运行示例工作流

运行 `terminal-examples.yml` 工作流，测试终端配置文件的功能：

```bash
# 使用 GitHub CLI 触发
 gh workflow run terminal-examples.yml --ref main
```

### 3. 手动运行安全扫描和自动修复

**运行安全扫描**：

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

**运行自动修复**：

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

## 安全标准

本终端功能包的安全标准符合 `https://results.pre-commit.ci/run/github/` 中规定的安全规范，包括：

- **文件权限安全**：确保配置文件权限正确，防止未授权访问
- **敏感信息保护**：自动检测和移除配置文件中的敏感信息
- **语法错误修复**：自动检测和修复 YAML 语法错误
- **路径安全**：避免硬编码路径带来的安全问题
- **Shell 配置安全**：确保 Shell 配置正确，防止命令注入

## 兼容性

### GitHub 云端仓库环境兼容性

- **GitHub Actions 兼容性**：支持在 GitHub Actions 中使用所有终端功能
- **Windows 环境兼容性**：专门针对 Windows 环境优化，确保与本地 Windows 终端完全兼容
- **pre-commit.ci 兼容性**：与 pre-commit.ci 完全集成，实现自动化安全扫描和修复

### 异常处理

- **自动错误检测**：自动检测终端运行过程中出现的所有错误
- **自动错误修复**：自动修复发现的所有错误，确保终端功能正常运行
- **错误内容捕获**：完整捕获并显示终端运行时的全部错误内容
- **异常情况处理**：能够正确处理各种异常情况，确保自动化操作的稳定性

## 配置步骤

### 1. 基本配置

1. 将本文件夹中的所有文件复制到您的 GitHub 仓库的 `.github/actions-config/` 目录中
2. 确保脚本文件有执行权限
3. 在 GitHub 仓库中启用 pre-commit.ci 应用

### 2. 自定义配置

**修改 PowerShell 终端配置** (`powershell-terminal.yml`)：

```yaml
# 修改环境变量
env:
  PSModulePath: "${{ github.workspace }}\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules"
  # 添加自定义环境变量
  CUSTOM_VAR: "custom_value"

# 修改步骤
steps:
  # 添加自定义步骤
  - name: 自定义步骤
    run: |
      Write-Host "Custom step executed!"
      # 自定义 PowerShell 命令...
```

**修改 Node.js command prompt 终端配置** (`nodejs-command-prompt.yml`)：

```yaml
# 修改 Node.js 版本
- name: 安装 Node.js
  uses: actions/setup-node@v5
  with:
    node-version: '18'  # 修改为所需的 Node.js 版本
    cache: 'npm'

# 修改步骤
steps:
  # 添加自定义步骤
  - name: 自定义步骤
    run: |
      echo Custom step executed!
      # 自定义 Node.js 命令...
```

## 使用说明

### 1. 终端使用

**PowerShell 终端**：
- 支持所有本地 Windows PowerShell 命令
- 支持 PowerShell 模块和函数
- 支持 PowerShell 脚本执行

**Node.js command prompt 终端**：
- 支持所有 Node.js 命令
- 支持 npm、yarn、pnpm 等包管理工具
- 支持 Node.js 脚本执行

### 2. 自动化操作

**自动安全扫描**：
- pre-commit.ci 会在每次提交时自动运行安全扫描
- 扫描结果会显示在 GitHub 仓库的 Actions 页面
- 发现的安全问题会被自动修复

**自动错误修复**：
- pre-commit.ci 会自动修复发现的所有错误
- 修复后的更改会自动提交
- 修复结果会显示在 GitHub 仓库的 Actions 页面

### 3. 错误处理

**错误捕获**：
- 完整捕获终端运行时的全部错误内容
- 错误信息包括错误类型、位置、修复前和修复后的内容

**错误修复**：
- 自动修复所有发现的错误
- 对于无法自动修复的错误，会显示详细的错误信息和手动修复建议

## 常见问题和解决方案

### 1. 终端配置文件不存在

**问题**：运行安全扫描时提示终端配置文件不存在

**解决方案**：
```bash
# 检查文件是否存在
ls -la .github/actions-config/

# 如果文件不存在，确保已正确复制所有文件
cp -r terminal-config-full/* .github/actions-config/
```

### 2. 安全扫描失败

**问题**：安全扫描脚本执行失败

**解决方案**：
```bash
# 检查脚本权限
chmod +x .github/actions-config/terminal-security-scan.sh

# 检查脚本依赖
which bash
which grep
which sed
```

### 3. 自动修复失败

**问题**：自动修复脚本执行失败

**解决方案**：
```bash
# 检查脚本权限
chmod +x .github/actions-config/terminal-auto-fix.sh

# 检查 Python 是否可用（用于修复 YAML 缩进）
python3 --version

# 查看日志文件了解具体错误
cat logs/terminal-auto-fix-*.log
```

### 4. pre-commit.ci 集成失败

**问题**：pre-commit.ci 未自动运行或运行失败

**解决方案**：
1. 确保在 GitHub 仓库中启用了 pre-commit.ci 应用
2. 检查 `.pre-commit-config.yaml` 文件配置是否正确
3. 确保脚本文件有执行权限
4. 查看 pre-commit.ci 日志了解具体错误

## 最佳实践

1. **定期运行安全扫描**：确保终端配置文件符合安全要求
2. **使用自动修复**：及时修复发现的错误，保持配置文件的正确性
3. **启用 pre-commit.ci**：实现自动化的安全扫描和修复
4. **备份配置文件**：在修改前创建备份，防止意外错误
5. **遵循 YAML 最佳实践**：使用正确的缩进和语法，确保配置文件的可读性
6. **避免硬编码敏感信息**：使用 GitHub Secrets 存储敏感信息
7. **使用固定版本**：为 Actions 和依赖项指定固定版本，避免不可预测的更新

## 联系信息

如有任何问题或建议，请联系仓库管理员。

---

**最后更新时间**：2026-01-29
