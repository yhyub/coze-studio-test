# Docker 白屏闪退问题解决方案

## 问题描述

Docker Desktop 在 Windows 或 macOS 系统上安装或启动时出现白屏闪退的情况，具体表现为：
- 双击 Docker Desktop 图标后，只显示空白窗口
- 窗口出现后立即崩溃退出
- 没有任何错误提示信息
- 进程在任务管理器中短暂出现后消失

## 常见原因

1. **系统兼容性问题**
   - Windows 版本过低或不支持
   - 硬件虚拟化未启用
   - 系统缺少必要的依赖组件

2. **旧版本 Docker 残留**
   - 卸载不彻底导致的配置冲突
   - 注册表项残留
   - 数据目录权限问题

3. **WSL2 配置问题**
   - WSL2 版本过旧
   - WSL2 网络配置错误
   - WSL2 虚拟机损坏

4. **Hyper-V 服务问题**
   - Hyper-V 服务未启动
   - Hyper-V 组件损坏
   - Hyper-V 与其他虚拟化软件冲突

5. **网络和安全问题**
   - 防火墙阻止 Docker 网络连接
   - 杀毒软件误报
   - 代理服务器配置错误

6. **硬件和驱动问题**
   - 显卡驱动过时
   - 内存不足
   - 磁盘空间不足

## 解决方案

### 方案 1：使用自动化修复工具

1. **运行修复脚本**
   ```powershell
   # 以管理员权限运行
   .\fix-docker-env.ps1
   ```

2. **重启电脑**

3. **重新安装 Docker Desktop**

### 方案 2：手动修复步骤

#### 步骤 1：检查系统要求

1. **Windows 系统要求**
   - Windows 10/11 专业版/企业版/教育版（64位）
   - 版本号至少为 1909 或更高
   - 至少 4GB RAM
   - 至少 50GB 可用磁盘空间

2. **检查虚拟化支持**
   - 打开任务管理器 → 性能 → CPU
   - 查看右下角是否显示 "虚拟化：已启用"
   - 如果未启用，进入 BIOS/UEFI 开启虚拟化

#### 步骤 2：清理旧版本 Docker

1. **卸载 Docker Desktop**
   - 控制面板 → 程序和功能 → 卸载 Docker Desktop

2. **删除残留文件夹**
   ```powershell
   # 删除主要目录
   Remove-Item -Path "$env:ProgramFiles\Docker" -Recurse -Force
   Remove-Item -Path "$env:LOCALAPPDATA\Docker" -Recurse -Force
   Remove-Item -Path "$env:USERPROFILE\.docker" -Recurse -Force
   Remove-Item -Path "$env:ProgramData\Docker" -Recurse -Force
   
   # 删除 WSL 相关文件
   wsl --unregister docker-desktop
   wsl --unregister docker-desktop-data
   ```

3. **清理注册表**
   - 按 `Win + R` → 输入 `regedit`
   - 删除以下键值：
     - `HKEY_CURRENT_USER\Software\Docker Inc.`
     - `HKEY_LOCAL_MACHINE\SOFTWARE\Docker Inc.`

#### 步骤 3：修复 WSL2

1. **更新 WSL2**
   ```powershell
   wsl --update
   wsl --set-default-version 2
   ```

2. **重置 WSL2**
   ```powershell
   wsl --shutdown
   wsl --unregister docker-desktop
   wsl --unregister docker-desktop-data
   ```

3. **检查 WSL2 状态**
   ```powershell
   wsl --list --verbose
   ```

#### 步骤 4：修复 Hyper-V

1. **重启 Hyper-V 服务**
   ```powershell
   # 停止服务
   Stop-Service -Name "vmms" -Force
   Stop-Service -Name "Hyper-V Host Compute Service" -Force
   
   # 启动服务
   Start-Service -Name "vmms"
   Start-Service -Name "Hyper-V Host Compute Service"
   ```

2. **重置 Hyper-V 配置**
   ```powershell
   # 禁用 Hyper-V
   dism.exe /Online /Disable-Feature:Microsoft-Hyper-V /All /NoRestart
   
   # 启用 Hyper-V
   dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /NoRestart
   ```

#### 步骤 5：修复网络配置

1. **重置网络堆栈**
   ```powershell
   netsh winsock reset
   netsh int ip reset
   ipconfig /release
   ipconfig /renew
   ipconfig /flushdns
   ```

2. **清理 Docker 网络**
   ```powershell
   # 删除 Docker 虚拟网络适配器
   Get-NetAdapter | Where-Object {$_.Name -like "vEthernet (WSL)*"} | ForEach-Object {
       Remove-NetAdapter -Name $_.Name -Confirm:$false
   }
   ```

#### 步骤 6：修复文件权限

1. **重置用户配置文件权限**
   ```powershell
   $userProfile = $env:USERPROFILE
   $acl = Get-Acl $userProfile
   $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
   $acl.SetAccessRule($rule)
   Set-Acl $userProfile $acl
   ```

2. **清理临时文件**
   ```powershell
   # 清理系统临时文件夹
   Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
   Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
   ```

### 方案 3：使用替代方案

如果以上方案都无效，可以考虑使用以下替代方案：

#### Windows 系统

1. **使用 WSL2 + Docker Engine**
   ```powershell
   # 安装 WSL2
   wsl --install
   
   # 安装 Ubuntu
   wsl --install -d Ubuntu
   
   # 进入 Ubuntu
   wsl -d Ubuntu
   
   # 在 Ubuntu 中安装 Docker
   sudo apt update
   sudo apt install docker.io
   sudo service docker start
   ```

2. **使用 Rancher Desktop**
   - 从官网下载 Rancher Desktop
   - 安装并启动，选择使用 containerd

#### macOS 系统

1. **使用 Colima**
   ```bash
   # 安装 Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # 安装 Colima
   brew install colima docker
   
   # 启动 Colima
   colima start
   ```

2. **使用 Podman**
   ```bash
   brew install podman
   podman machine init
   podman machine start
   ```

## 日志分析

如果问题仍然存在，可以通过查看日志文件来进一步分析：

### Windows 日志

1. **Docker 日志**
   - 位置：`%LocalAppData%\Docker\log.txt`
   - 内容：Docker Desktop 启动日志

2. **Windows 事件查看器**
   - 打开事件查看器 → Windows 日志 → 应用程序
   - 查找 Docker 相关的错误事件

3. **WSL 日志**
   - 位置：`%LocalAppData%\Microsoft\WSL\logs`
   - 内容：WSL2 启动和运行日志

### macOS 日志

1. **Docker 日志**
   ```bash
   cat ~/Library/Containers/com.docker.docker/Data/log/vm/dockerd.log
   ```

2. **系统日志**
   ```bash
   log show --predicate 'process == "Docker"' --info
   ```

## 常见错误代码和解决方案

| 错误代码 | 描述 | 解决方案 |
|---------|------|--------|
| 0x80070005 | 权限不足 | 以管理员权限运行 |
| 0x80070422 | 服务未启动 | 启动相关服务 |
| 0x80041002 | WMI 错误 | 重建 WMI 数据库 |
| 0x80370102 | 虚拟化未启用 | 进入 BIOS 开启虚拟化 |
| 0x80070057 | 参数错误 | 清理注册表并重新安装 |
| 0x8009030e | 凭证错误 | 重置网络凭证 |
| 0x800700b7 | 文件已存在 | 删除残留文件 |
| 0x80072ee7 | 网络错误 | 检查网络连接 |

## 预防措施

1. **定期更新系统**
   - 保持 Windows/macOS 系统更新
   - 及时更新显卡驱动

2. **正确卸载 Docker**
   - 使用官方卸载程序
   - 运行清理脚本

3. **合理配置资源**
   - 确保至少 8GB RAM
   - 保持充足的磁盘空间

4. **避免冲突软件**
   - 不要同时安装 VirtualBox、VMware 等虚拟化软件
   - 暂时禁用杀毒软件进行测试

5. **使用稳定版本**
   - 避免使用 Beta 或 Edge 版本
   - 从官网下载最新稳定版

## 联系支持

如果所有方案都无效，可以联系 Docker 官方支持：

1. **Docker 官方支持**
   - 网站：https://www.docker.com/support
   - 论坛：https://forums.docker.com

2. **提供以下信息**
   - 操作系统版本
   - Docker Desktop 版本
   - 错误日志文件
   - 尝试过的解决方案
   - 硬件配置信息

## 快速参考

### 修复命令汇总

```powershell
# 检查虚拟化
Get-WmiObject -Class Win32_Processor | Select-Object VirtualizationFirmwareEnabled

# 重置 WSL2
wsl --shutdown
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
wsl --set-default-version 2

# 修复 Hyper-V
dism.exe /Online /Disable-Feature:Microsoft-Hyper-V /All /NoRestart
dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /NoRestart

# 重置网络
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

# 清理 Docker 目录
Remove-Item -Path "$env:LOCALAPPDATA\Docker" -Recurse -Force
Remove-Item -Path "$env:USERPROFILE\.docker" -Recurse -Force

# 查看 Docker 日志
Get-Content "$env:LOCALAPPDATA\Docker\log.txt"
```

### 系统要求检查

```powershell
# 检查 Windows 版本
(Get-WmiObject -Class Win32_OperatingSystem).Version
(Get-WmiObject -Class Win32_OperatingSystem).Caption

# 检查内存
(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB

# 检查磁盘空间
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | Select-Object FreeSpace, Size
```

## 结论

Docker 白屏闪退问题通常是由系统配置、软件冲突或硬件兼容性问题导致的。通过本文提供的解决方案，大多数用户都能成功修复这个问题。如果问题仍然存在，建议尝试替代方案或联系官方支持。

记住，定期维护系统和正确配置 Docker 是避免此类问题的最佳方法。