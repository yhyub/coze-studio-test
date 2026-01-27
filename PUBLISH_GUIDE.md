# GitHub Marketplace 发布指南

## 项目配置

### 已创建的文件

1. **action.yml** - GitHub Action 元数据文件
2. **package.json** - Node.js 项目配置
3. **src/index.js** - Action 核心逻辑
4. **README.md** - 项目说明文档
5. **marketplace-config.json** - 市场配置
6. **.github/workflows/release.yml** - 自动发布工作流

## 发布步骤

### 1. 本地测试

```bash
npm install
npm run build
```

### 2. 创建 GitHub Release

1. 访问仓库的 Releases 页面
2. 点击 "Draft a new release"
3. 填写版本号（如 v1.0.0）
4. 点击 "Publish release"

### 3. 提交到 Marketplace

1. 访问 [GitHub Marketplace](https://github.com/marketplace)
2. 点击 "Submit new action"
3. 选择你的仓库
4. 配置市场信息
5. 提交审核

## 市场链接

- 市场地址: https://github.com/marketplace
- 扩展地址: https://github.com/marketplace/gitee3
- 编辑地址: https://github.com/marketplace/gitee3/edit

## 注意事项

- 确保 `dist/` 目录已包含在版本中
- 所有依赖已正确打包
- 遵循 GitHub Marketplace 审核规则