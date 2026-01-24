# Coze Studio 手动修复指南
# 版本: 1.0.0

## 问题分析
1. **Docker配置文件格式问题**: features字段格式错误
2. **Docker服务未运行**: Docker引擎无法连接
3. **WSL执行错误**: Docker Desktop无法正常启动

## 修复步骤

### 步骤1：修复Docker配置文件
**操作方法**:
1. 打开文件资源管理器
2. 导航到: `C:\Users\Administrator\.docker\`
3. 找到并编辑 `config.json` 文件
4. 将内容替换为以下正确格式:

```json
{
  "auths": {},
  "credsStore": "desktop.exe",
  "currentContext": "desktop-linux",
  "features": ""
}
```

**关键修复**: 将 `features` 字段从对象格式改为空字符串格式

### 步骤2：启动Docker Desktop
**操作方法**:
1. 点击Windows开始菜单
2. 搜索并启动 "Docker Desktop"
3. 等待Docker Desktop完全启动（约30-60秒）
4. 确保右下角Docker图标显示为绿色（表示运行正常）

### 步骤3：验证Docker服务
**操作方法**:
1. 打开PowerShell（以管理员身份运行）
2. 运行以下命令:
   ```powershell
   docker version
   ```
3. 如果显示Docker版本信息，则表示服务正常运行

### 步骤4：启动Coze Studio服务
**操作方法**:
1. 打开PowerShell（以管理员身份运行）
2. 导航到Coze Studio目录:
   ```powershell
   cd "C:\Users\Administrator\Desktop\fcjgfycrteas\coze-studio-0.5.0\docker"
   ```
3. 停止旧的容器（如果存在）:
   ```powershell
   docker compose down --remove-orphans
   ```
4. 清理Docker缓存:
   ```powershell
   docker system prune -f
   docker volume prune -f
   docker network prune -f
   ```
5. 启动所有服务:
   ```powershell
   docker compose up -d
   ```
6. 等待服务完全启动（约2-3分钟）

### 步骤5：验证服务状态
**操作方法**:
1. 运行以下命令查看容器状态:
   ```powershell
   docker compose ps
   ```
2. 确保所有容器状态为 "Up"
3. 特别检查 `coze-web` 容器是否运行

### 步骤6：访问Coze Studio
**操作方法**:
1. 打开浏览器
2. 访问以下地址:
   ```
   http://localhost:8888
   ```
3. 确认显示完整的Coze Studio登录页面

## 访问地址信息
```
访问地址：
- Coze Studio 主界面：http://localhost:8888
- Coze Studio 注册地址：http://localhost:8888/sign
- Coze Studio 管理界面：http://localhost:8888/admin
```

## 故障排除

### 问题1：Docker配置文件权限不足
**解决方案**:
- 右键点击 `config.json` 文件 → 属性 → 安全 → 编辑 → 添加当前用户并授予完全控制权限

### 问题2：Docker Desktop启动失败
**解决方案**:
- 重启计算机
- 以管理员身份运行Docker Desktop
- 检查Windows服务中 "Docker Desktop Service" 是否已启动

### 问题3：Coze Studio服务启动失败
**解决方案**:
- 检查Docker镜像是否下载成功
- 查看容器日志: `docker logs coze-web`
- 确保端口8888未被其他服务占用

### 问题4：访问页面显示错误
**解决方案**:
- 等待更长时间（首次启动需要3-5分钟）
- 检查网络连接
- 刷新浏览器页面

## 技术支持
如果以上步骤都无法解决问题，请提供以下信息以便进一步分析:
1. Docker版本信息
2. 错误日志截图
3. 容器状态输出
4. 系统环境信息

## 预期结果
✅ Docker配置文件修复完成
✅ Docker服务正常运行
✅ Coze Studio所有服务启动成功
✅ 浏览器显示完整的Coze Studio登录页面
✅ 可以正常访问 http://localhost:8888