# Coze Studio 完整修复与启动指南

## 任务概述
- **主要目标**：删除重复的 PowerShell 脚本文件，合并为单一综合脚本，修复 Docker 和 WSL 问题，确保 Coze Studio 成功启动并显示完整登录页面
- **访问地址**：http://localhost:8888

## 技术栈
- Docker API 版本管理（1.52→1.51→1.50 自动回退机制）
- WSL（Windows Subsystem for Linux）配置与故障排除
- Docker Desktop 安装、更新与重置
- Docker Compose 服务编排与依赖管理
- Nginx 代理配置
- 网络优化（TCP 设置、DNS 配置）
- PowerShell 系统管理脚本
- Docker 镜像加速配置

## 解决方案

### 1. 脚本合并与优化
**创建的文件**：
- `coze_studio_full_fix.ps1` - 综合修复脚本
- `run_coze_studio.bat` - 执行批处理文件

**删除的重复文件**：
- `coze_studio_start_fix.ps1`
- `coze_studio_toolkit_complete.ps1`
- `coze_studio_toolkit_esrdtfyge.ps1`
- `coze_studio_toolkit_final.ps1`
- `coze_studio_toolkit_fixed.ps1`
- `coze_studio_toolkit_merged.ps1`
- `coze_studio_toolkit.ps1`

### 2. 核心功能模块

#### Docker 修复模块
- **API 版本管理**：实现 1.52→1.51→1.50 自动回退机制
- **服务重启**：完全停止并重启 Docker 服务
- **配置重置**：清理临时文件和缓存
- **环境变量设置**：系统级和用户级 DOCKER_API_VERSION 配置

#### WSL 修复模块
- **分发管理**：停止所有 WSL 分发
- **Docker 分发重置**：注销 docker-desktop 和 docker-desktop-data
- **服务重启**：重启 LxssManager 服务

#### Docker 镜像加速
- **多镜像源配置**：阿里云、网易、USTC、DockerProxy 等
- **系统级配置**：创建 daemon.json 配置文件
- **下载优化**：最大并发下载设置为 10

#### 网络优化模块
- **GitHub 访问修复**：DNS 缓存刷新、网络栈重置
- **TCP 优化**：启用快速打开、自动调优
- **DNS 配置**：设置 Cloudflare 和 Google DNS

#### Coze Studio 部署模块
- **依赖服务管理**：MySQL、Redis、Elasticsearch、MinIO、Milvus、NSQ
- **镜像拉取**：使用国内镜像源加速
- **服务启动**：完整启动所有服务并验证状态
- **访问验证**：确认 http://localhost:8888 可访问并显示登录页面

### 3. 执行流程
1. **权限检查**：确保以管理员身份运行
2. **Docker 更新**：更新到最新版本
3. **Docker 修复**：解决 API 版本不匹配问题
4. **WSL 修复**：解决 WSL 相关错误
5. **网络优化**：修复 GitHub 访问和网络设置
6. **镜像加速**：配置 Docker 镜像加速
7. **缓存清理**：清理 Docker 和系统缓存
8. **配置更新**：修改 docker-compose.yml 依赖条件
9. **服务部署**：启动 Coze Studio 及其依赖服务
10. **访问验证**：验证服务可访问性

### 4. 执行方法
1. **方法一**：双击运行 `run_coze_studio.bat`
2. **方法二**：以管理员身份运行 PowerShell 并执行：
   ```powershell
   pwsh -ExecutionPolicy Bypass -File "c:\Users\Administrator\Desktop\fcjgfycrteas\coze_studio_full_fix.ps1"
   ```

### 5. 预期结果
- ✅ Docker 服务正常运行
- ✅ WSL 配置正确
- ✅ Coze Studio 服务启动成功
- ✅ 可访问 http://localhost:8888
- ✅ 显示完整的登录页面
- ✅ 所有依赖服务正常运行

### 6. 故障排除
- **Docker 启动失败**：检查 API 版本设置，尝试不同版本回退
- **WSL 错误**：运行 `wsl --shutdown` 并重启 WSL 服务
- **网络问题**：刷新 DNS 缓存，检查防火墙设置
- **镜像拉取失败**：确认镜像加速配置正确
- **服务启动超时**：增加等待时间，检查系统资源

### 7. 配置文件
**Docker 配置**：
- `~/.docker/config.json` - 用户级配置
- `C:\ProgramData\Docker\config\daemon.json` - 系统级配置

**Coze Studio 配置**：
- `coze-studio-0.5.0\docker\docker-compose.yml` - 服务编排配置

### 8. 日志与监控
- **日志文件**：`%TEMP%\CozeStudioToolkit\toolkit_*.log`
- **服务状态**：使用 `docker compose ps` 查看服务状态
- **容器日志**：使用 `docker logs <container-name>` 查看容器日志

## 总结
本方案通过综合修复脚本解决了 Docker 和 WSL 的常见问题，确保 Coze Studio 能够顺利启动和运行。脚本实现了自动化的问题检测和修复，减少了手动操作的复杂性，同时通过镜像加速和网络优化提高了部署效率。

**访问地址**：http://localhost:8888
**管理地址**：http://localhost:8888/admin
**注册地址**：http://localhost:8888/sign