# GitHub Marketplace Actions 扩展创建与发布全流程指南

## 准备工作

### 1. 环境要求
- Node.js 20+ (推荐 LTS 版本)
- npm 或 yarn 包管理器
- GitHub 账号
- Git 客户端

### 2. 创建 GitHub 仓库
1. 访问 [GitHub](https://github.com/new) 创建新仓库
2. 仓库名建议与 Action 名称一致（如 `coze-workflow-action`）
3. 选择公开仓库（Marketplace 要求公开）

---

## 步骤 1: 初始化项目

### 1.1 克隆仓库
```bash
git clone https://github.com/your-username/your-action-repo.git
cd your-action-repo
```

### 1.2 初始化 npm 项目
```bash
npm init -y
```

### 1.3 安装依赖
```bash
npm install @actions/core @actions/http-client
npm install --save-dev @vercel/ncc
```

---

## 步骤 2: 编写 Action 代码

### 2.1 创建 action.yml
```yaml
name: 'Coze AI Workflow Action'
description: 'Run AI workflows using Coze platform'
author: 'Your Name'
branding:
  icon: 'code'
  color: 'blue'

inputs:
  api-key:
    description: 'Coze API Key'
    required: true
  workflow-id:
    description: 'Workflow ID to execute'
    required: true

runs:
  using: 'node20'
  main: 'dist/index.js'
```

### 2.2 编写核心逻辑
创建 `src/index.js` 文件：
```javascript
const core = require('@actions/core');

async function run() {
  try {
    const apiKey = core.getInput('api-key');
    const workflowId = core.getInput('workflow-id');
    
    // 你的业务逻辑
    console.log(`Executing workflow: ${workflowId}`);
    
    // 设置输出
    core.setOutput('result', 'success');
  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
```

---

## 步骤 3: 构建与测试

### 3.1 配置构建脚本
在 `package.json` 中添加：
```json
"scripts": {
  "build": "ncc build src/index.js -o dist",
  "package": "npm run build"
}
```

### 3.2 本地构建
```bash
npm run build
```

### 3.3 本地测试
创建测试工作流 `.github/workflows/test.yml`：
```yaml
name: Test Action

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test Action
        uses: ./
        with:
          api-key: test-key
          workflow-id: test-workflow
```

---

## 步骤 4: 提交到 GitHub

### 4.1 添加文件
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### 4.2 创建 Release
1. 访问仓库的 Releases 页面
2. 点击 "Draft a new release"
3. 填写版本号（如 v1.0.0）
4. 点击 "Publish release"

---

## 步骤 5: 发布到 Marketplace

### 5.1 提交到 Marketplace
1. 访问 [GitHub Marketplace](https://github.com/marketplace)
2. 点击 "Submit new action"
3. 选择你的仓库
4. 配置市场信息：
   - 标题：Coze AI Workflow Action
   - 描述：运行 AI 工作流的 GitHub Action
   - 分类：AI、Automation
   - 价格：免费

### 5.2 审核流程
- GitHub 团队会审核你的 Action
- 审核时间通常为 1-3 个工作日
- 审核通过后会收到邮件通知

---

## 步骤 6: 管理与更新

### 6.1 发布新版本
1. 修改代码
2. 更新版本号
3. 创建新的 Release
4. 自动同步到 Marketplace

### 6.2 编辑市场信息
访问 `https://github.com/marketplace/gitee3/edit` 可以：
- 更新描述和分类
- 上传新的 logo
- 修改定价策略

---

## 常见问题

### Q: 如何处理审核不通过？
A: 查看 GitHub 发送的审核反馈邮件，根据要求修改后重新提交。

### Q: 如何设置私有 Action？
A: 私有 Action 无法发布到 Marketplace，但可以在内部仓库使用。

### Q: 如何更新已发布的 Action？
A: 创建新的 Release 即可自动更新到 Marketplace。

---

## 资源链接

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Marketplace 指南](https://docs.github.com/en/marketplace)
- [ncc 打包工具](https://github.com/vercel/ncc)