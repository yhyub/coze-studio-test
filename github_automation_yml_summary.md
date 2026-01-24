# GitHub自动化配置文件汇总

以下是项目中所有GitHub Actions YAML文件的详细内容：

## 根目录GitHub Actions配置 (./.github/workflows/)

### 1. coze-deploy.yml
- **名称**: Coze Studio 自动化部署
- **触发条件**: 手动触发 (workflow_dispatch)
- **主要功能**:
  - 支持多环境部署（development、staging、production）
  - 支持多种部署类型（full、backend-only、frontend-only、docker-only）
  - 包含环境设置、Docker部署、清理和安全扫描等作业
  - 支持部署通知

### 2. coze-studio-deployment.yml
- **名称**: Coze Studio 自动化部署与完整功能集成
- **触发条件**: push到main/master分支、PR到