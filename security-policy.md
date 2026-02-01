# GitHub Action 安全策略

## 1. 版本管理
- 所有GitHub Action必须使用固定版本（如v4、v5）
- 禁止使用动态版本（如latest、master、HEAD）

## 2. 来源管理
- 只允许使用以下来源的Action：
  - actions/*（官方Action）
  - peaceiris/*（知名开源Action）
  - 经过安全审核的自定义Action

## 3. 安全审核
- 所有新添加的Action必须经过安全审核
- 自定义Action必须提供完整的源代码和安全报告
- 定期审核已安装的Action，确保没有安全漏洞

## 4. 扫描策略
- 每天自动运行安全扫描
- 每次提交代码时自动运行安全扫描
- 发现安全问题立即通知管理员

## 5. 应急响应
- 发现安全漏洞立即禁用相关Action
- 及时更新Action到最新版本
- 记录安全事件并进行根因分析