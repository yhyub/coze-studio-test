# 综合修复与优化工具包使用指南

## 1. 项目概述

本工具包旨在解决以下核心问题：
- Docker Desktop 4.56.0 兼容性问题修复
- GitHub 访问加速与网络优化
- 2345浏览器访问GitHub的问题修复
- Coze Studio 部署与运行管理

## 2. 系统要求

- Windows 10/11 64位操作系统
- PowerShell 5.1 或更高版本
- 管理员权限
- 稳定的网络连接

## 3. Docker Desktop 修复指南

### 3.1 问题概述

Docker Desktop 4.56.0 版本存在以下严重问题：
- Privileged 相关错误
- hosts 文件访问被拒绝
- API 版本兼容性问题（500 Internal Server Error）
- 无法拉取 Coze Studio 所需镜像

### 3.2 推荐解决方案

**核心解决方案：降级到兼容版本 Docker Desktop 4.28.0**

### 3.3 修复步骤

#### 步骤1：卸载当前版本

1. 打开 **控制面板** → **程序和功能**
2. 找到 **Docker Desktop** 并选择 **卸载**
3. 勾选 "删除所有数据" 选项
4. 重启计算机

#### 步骤2：下载兼容版本

- 下载链接：[Docker Desktop 4.28.0](https://github.com/docker/docker-desktop/releases/download/v4.28.0/DockerDesktop-4.28.0.exe)
- 保存到：`C:\Users\Administrator\Desktop\fcjgfycrteas\DockerDesktop-4.28.0.exe`

#### 步骤3：安装 Docker Desktop

1. 双击下载的安装程序
2. 按照向导完成安装
3. 启动 Docker Desktop 并完成初始化

#### 步骤4：配置 Docker 引擎

使用以下配置文件（daemon.json）：

```json
{
  "registry-mirrors": [
    "https://mirror.aliyuncs.com",
    "https://hub-mirror.c.163.com",
    "https://mirrors.ustc.edu.cn/dockerhub/",
    "https://docker.mirrors.ustc.edu.cn/",
    "https://dockerproxy.com",
    "https://docker.1ms.run"
  ],
  "exec-opts": ["isolation=process"],
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "no-hosts": true,
  "max-concurrent-downloads": 10
}
```

**配置说明**：
- `registry-mirrors`：镜像加速源列表，提高拉取速度
- `exec-opts`：使用进程隔离模式，提高兼容性
- `experimental`：禁用实验性功能，提高稳定性
- `buildkit`：启用 BuildKit 构建引擎
- `no-hosts`：不修改 hosts 文件，避免权限问题
- `max-concurrent-downloads`：增加并发下载数，提高下载速度

**配置方法**：

1. 打开 Docker Desktop 设置
2. 进入 **Docker Engine** 选项卡
3. 复制上述配置内容
4. 点击 **Apply & Restart** 保存配置

### 3.4 Docker 命名管道修复

如果遇到命名管道相关错误，执行以下脚本：

```powershell
# 停止所有 Docker 进程
$processes = @("Docker Desktop", "com.docker.backend", "dockerd", "docker")   
foreach ($p in $processes) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# 停止 Docker 服务     
Stop-Service com.docker.service -Force -ErrorAction SilentlyContinue

# 等待 5 秒
Start-Sleep -Seconds 5

# 启动 Docker 服务    
Start-Service com.docker.service

# 等待 10 秒
Start-Sleep -Seconds 10   

# 启动 Docker Desktop    
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Start-Process -FilePath $dockerPath
}
```

## 4. GitHub 访问修复与优化

### 4.1 常见问题

- 访问超时（ERR_CONNECTION_TIMED_OUT）
- 连接被重置（ERR_CONNECTION_RESET）
- 2345浏览器无法正常访问GitHub

### 4.2 hosts 文件修复

以管理员身份运行以下脚本修复hosts文件：

```powershell
# GitHub访问修复脚本 - 修复hosts文件中的重复条目
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$tempPath = "$env:TEMP\hosts.tmp"

# 读取当前hosts文件内容
$hostsContent = Get-Content -Path $hostsPath -Raw

# 移除重复的github.com条目
$fixedContent = $hostsContent -replace '20\.205\.243\.166\s+github\.com', ''
# 添加单个正确的github.com条目
$fixedContent = $fixedContent + "`n# GitHub entry for reliable access`n20.205.243.166 github.com"

# 写入临时文件
Set-Content -Path $tempPath -Value $fixedContent

# 复制到系统hosts文件（需要管理员权限）
Copy-Item -Path $tempPath -Destination $hostsPath -Force

# 刷新DNS缓存
Clear-DnsClientCache

# 重启2345浏览器
Stop-Process -Name "2345Explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
& "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"

# 添加防火墙出站允许规则
$browserPath = "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"
if (Test-Path $browserPath) {
    $ruleExists = Get-NetFirewallApplicationFilter -Program $browserPath -ErrorAction SilentlyContinue
    if (-not $ruleExists) {
        New-NetFirewallRule -DisplayName "Allow 2345 Explorer Outbound" -Direction Outbound -Program $browserPath -Action Allow -Protocol TCP -RemotePort 80,443
    }
}
```

### 4.3 GitHub 镜像源推荐

使用以下可靠的GitHub镜像源加速访问：

| 镜像源名称 | 访问地址 | 特点 |
|---------|---------|------|
| 淘宝npm镜像 | https://github.com.cnpmjs.org | 阿里巴巴运营，同步稳定 |
| 腾讯云镜像 | https://mirrors.cloud.tencent.com/github/ | 国内访问稳定 |
| 中科大镜像 | https://github.ustc.edu.cn/ | 学术机构运营 |
| kgithub | https://kgithub.com/ | 支持完整GitHub功能 |
| gitclone | https://gitclone.com/ | 专注git clone加速 |

### 4.4 网络优化设置

执行以下脚本优化系统网络设置：

```powershell
# GitHub网络访问优化脚本

# 优化DNS设置
$dnsServers = @("1.1.1.1", "8.8.8.8", "9.9.9.9", "114.114.114.114")
Set-DnsClientServerAddress -InterfaceAlias "WLAN" -ServerAddresses $dnsServers -ErrorAction SilentlyContinue

# 清除DNS缓存
Clear-DnsClientCache      

# 优化Windows网络参数
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

# 优化TCP窗口大小
Set-ItemProperty -Path $regPath -Name "TcpWindowSize" -Value 65536 -Type DWord -ErrorAction SilentlyContinue

# 减少TIME_WAIT延迟       
Set-ItemProperty -Path $regPath -Name "TcpTimedWaitDelay" -Value 30 -Type DWord -ErrorAction SilentlyContinue

# 增加重传次数
Set-ItemProperty -Path $regPath -Name "TcpMaxDataRetransmissions" -Value 10 -Type DWord -ErrorAction SilentlyContinue

# 增加最大连接数
Set-ItemProperty -Path $regPath -Name "TcpNumConnections" -Value 16777214 -Type DWord -ErrorAction SilentlyContinue

# 优化ACK频率
Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value 2 -Type DWord -ErrorAction SilentlyContinue

# 配置SSL/TLS协议
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
```

## 5. Coze Studio 部署与管理

### 5.1 前提条件

- 已安装兼容版本的 Docker Desktop 4.28.0
- 已配置正确的 Docker 引擎设置
- 足够的磁盘空间（建议至少 20GB）

### 5.2 拉取 Coze Studio 镜像

```powershell
# 拉取 Coze Studio 所需镜像
docker pull docker.1ms.run/cozedev/coze-studio-server:latest
docker pull docker.1ms.run/cozedev/coze-studio-web:latest
docker pull docker.1ms.run/mysql:8.4.5
docker pull docker.1ms.run/bitnamilegacy/redis:8.0
docker pull docker.1ms.run/bitnamilegacy/elasticsearch:8.18.0
docker pull docker.1ms.run/minio/minio:RELEASE.2025-06-13T11-33-47Z-cpuv1
docker pull docker.1ms.run/milvusdb/milvus:v2.5.10
docker pull docker.1ms.run/nsqio/nsq:v1.2.1
```

### 5.3 启动 Coze Studio

```powershell
# 切换到 Coze Studio Docker 目录
cd "C:\Users\Administrator\Desktop\fcjgfycrteas\coze-studio-0.5.0\docker"

# 启动所有服务
docker compose --profile * up -d
```

### 5.4 访问 Coze Studio

服务启动后，在浏览器中访问：`http://localhost:8888`

## 6. 测试与验证

### 6.1 GitHub 访问测试

执行以下脚本测试GitHub访问：

```powershell
# GitHub访问测试脚本
Write-Host "=== GitHub访问测试 ==="

# 测试基本网络连接        
Write-Host "\n1. 测试GitHub基本网络连接："
Test-Connection -ComputerName github.com -Count 2   

# 测试DNS解析
Write-Host "\n2. 测试GitHub DNS解析："
Resolve-DnsName github.com | Select-Object Name, IP4Address

# 测试HTTP访问
Write-Host "\n3. 测试GitHub HTTP访问："
try {
    $response = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ HTTP访问成功！状态码：" $response.StatusCode
} catch {
    Write-Host "✗ HTTP访问失败：" $_.Exception.Message
}

# 测试目标页面访问        
Write-Host "\n4. 测试目标GitHub Actions页面访问："  
try {
    $targetUrl = "https://github.com/yhyub/fsegrdtfghvjbn/actions/new?category=continuous-integration"  
    $response = Invoke-WebRequest -Uri $targetUrl -UseBasicParsing -TimeoutSec 15
    Write-Host "✓ 目标页面访问成功！状态码：" $response.StatusCode
} catch {
    Write-Host "✗ 目标页面访问失败：" $_.Exception.Message
}
```

### 6.2 Docker 状态验证

```powershell
# 验证Docker服务状态
Get-Service com.docker.service | Select-Object Name, Status

# 验证Docker版本
docker --version

# 验证Docker镜像
docker images | grep coze
```

## 7. 配置文件说明

### 7.1 daemon.json (Docker引擎配置)

```json
{
  "registry-mirrors": [
    "https://mirror.aliyuncs.com",
    "https://hub-mirror.c.163.com",
    "https://mirrors.ustc.edu.cn/dockerhub/",
    "https://docker.mirrors.ustc.edu.cn/",
    "https://dockerproxy.com",
    "https://docker.1ms.run"
  ],
  "exec-opts": ["isolation=process"],
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "no-hosts": true,
  "max-concurrent-downloads": 10
}
```

### 7.2 .env.example (环境变量示例)

包含运行Coze Studio所需的环境变量配置模板。

### 7.3 requirements.txt (Python依赖)

Coze Studio 所需的Python依赖包列表。

## 8. 故障排除

### 8.1 常见问题与解决方案

#### 问题1：Docker安装失败

**解决方案**：
- 确保已完全卸载旧版本
- 关闭杀毒软件和防火墙后重试
- 检查系统是否满足最低要求

#### 问题2：拉取镜像失败

**解决方案**：
- 检查网络连接
- 验证镜像加速配置是否生效
- 尝试切换不同的镜像源

#### 问题3：GitHub访问超时

**解决方案**：
- 运行hosts文件修复脚本
- 优化DNS设置
- 尝试使用GitHub镜像源

#### 问题4：Coze Studio无法启动

**解决方案**：
- 检查Docker服务状态
- 查看容器日志：`docker logs coze-server`
- 确保已安装兼容的Docker版本

### 8.2 日志查看

- Docker日志：`C:\ProgramData\Docker\logs`
- 工具包执行日志：脚本执行时会在当前目录生成日志文件

## 9. 总结

本工具包提供了一套完整的解决方案，用于修复和优化以下问题：

1. **Docker Desktop**：通过降级版本和优化配置解决兼容性问题
2. **GitHub访问**：通过hosts文件修复、DNS优化和网络设置提升访问速度
3. **2345浏览器**：解决浏览器访问GitHub的特定问题
4. **Coze Studio**：提供完整的部署和运行管理指南

通过使用本工具包，您可以快速解决上述问题，确保系统和应用程序的稳定运行。

---

**版本信息**：v1.0.0
**最后更新**：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
