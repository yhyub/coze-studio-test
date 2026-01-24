# 您创建的GitHub自动化配置文件

以下是您在项目根目录下创建的GitHub Actions YAML文件：

## 1. coze-deploy.yml

```yaml
name: Coze Studio 自动化部署

on:
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        default: 'development'
        type: choice
        options:
          - development
