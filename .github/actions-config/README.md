# GitHub Actions 配置管理

## 概述

本目录用于安全管理和配置仓库中使用的GitHub Actions。通过集中管理Actions的安装、版本和安全策略，确保仓库使用的Actions都是经过审核和安全的。

## 目录结构

```
存放/actions-config/
├── actions.yaml              # 主配置文件，管理所有已安装的Actions
├── README.md                 # 本说明文件
├── install-action.sh         # Action安装脚本
├── security-scan.sh          # 安全扫描脚本
├── installation-scripts/     # 用于存放安装脚本的YAML文件
├── custom-yaml-files/        # 用于存放各种其他创建的YAML文件
└── logs/                     # 审核日志目录
```

## 主要功能

### 1. 集中管理已安装的Actions

- 记录所有已安装的Actions及其版本
- 跟踪Actions的使用情况和安全状态
- 管理Actions的来源和权限

### 2. 安全策略管理

- 强制使用固定版本的Actions，避免不可预测的更新
- 定期检查Actions的安全更新
- 自动更新安全补丁版本
- 定义允许和禁止的Actions来源

### 3. 工作流配置

- 管理工作流文件的存放位置
- 定义允许和禁止的工作流触发事件

### 4. 审核日志

- 记录Actions的安装和更新历史
- 记录安全扫描结果
- 提供可追溯的审核记录

## 使用方法

### 安装新的GitHub Action

要安装新的GitHub Action，请按照以下步骤操作：

1. 在`actions.yaml`文件的`installed_actions`列表中添加Action的配置
2. 运行安全审核脚本：`./security-scan.sh`
3. 更新相关工作流文件，使用新安装的Action
4. 测试工作流运行
5. 更新审核日志

### 示例：安装新Action

```yaml
# 在actions.yaml中添加新Action
installed_actions:
  - name: actions/setup-rust
    version: v3
    source: marketplace
    usage: 用于设置Rust开发环境
    security: 待审核
    workflows: [rust-ci.yml]
```

### 运行安全扫描

```bash
./security-scan.sh
```

### 更新Actions版本

1. 修改`actions.yaml`文件中对应Action的`version`字段
2. 运行安全审核脚本
3. 更新相关工作流文件
4. 测试工作流运行
5. 更新审核日志

## 安全最佳实践

1. **始终使用固定版本**：避免使用`master`或`latest`等动态版本，防止不可预测的更新
2. **定期审核Actions**：定期检查Actions的安全状态和更新
3. **限制Actions权限**：在工作流中最小化Actions的权限范围
4. **只使用可信来源**：优先使用GitHub Marketplace中的Actions，避免使用未知来源的Actions
5. **定期更新安全补丁**：及时更新Actions的安全补丁版本

## 配置文件说明

### actions.yaml

主要配置文件，包含以下部分：

- **global**：全局配置，包括允许的Actions来源、禁止的Actions和安全扫描配置
- **installed_actions**：已安装的Actions列表，包含Action的名称、版本、来源、用途、安全状态和使用的工作流
- **custom_actions**：自定义Action的配置，包括存放目录和自定义Action列表
- **security_policy**：安全策略配置，包括版本管理、安全更新检查和自动更新设置
- **workflow_config**：工作流配置，包括工作流文件存放位置和允许的触发事件
- **audit_log**：审核日志配置，包括日志目录、保留天数和日志级别

## 审核流程

1. **检查Action的源代码**：查看Action的实现，确保没有恶意代码
2. **检查Action的依赖**：检查Action使用的依赖是否存在安全漏洞
3. **检查Action的权限要求**：确保Action只请求必要的权限
4. **检查Action的安全漏洞**：使用安全扫描工具检查Action是否存在已知漏洞
5. **记录审核结果**：将审核结果记录在`actions.yaml`文件中

## 自动化脚本

### install-action.sh

用于安全安装新的GitHub Action的脚本，包含以下功能：

- 检查Action的来源是否合法
- 检查Action的版本是否固定
- 运行安全扫描
- 更新`actions.yaml`文件
- 更新审核日志

### security-scan.sh

用于扫描已安装的Actions是否存在安全漏洞的脚本，包含以下功能：

- 检查Actions的版本是否存在已知漏洞
- 检查Actions的依赖是否存在安全问题
- 生成安全扫描报告
- 更新审核日志

## 常见问题

### 1. 如何添加自定义Action？

将自定义Action的代码放在`.github/actions/`目录下，然后在`actions.yaml`文件的`custom_actions.list`中添加对应的配置。

### 2. 如何处理Action的安全警告？

- 检查Action的安全公告
- 更新Action到安全版本
- 如果没有安全版本，考虑使用替代方案
- 记录处理结果到审核日志

### 3. 如何查看审核日志？

审核日志存放在`logs/`目录下，可以使用文本编辑器查看。

## 联系信息

如有任何问题或建议，请联系仓库管理员。
