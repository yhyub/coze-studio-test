<#
Coze Studio 自动化修复脚本

此脚本用于自动解决以下问题：
1. Docker Desktop WSL 相关错误
2. Docker 镜像拉取网络超时问题
3. Coze Studio 部署问题

使用方法：
1. 以管理员身份运行此脚本
2. 按照提示操作
3. 等待脚本执行完成

注意：此脚本会执行系统级操作，请确保您了解其影响
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'
$COLOR_MENU = 'Cyan'

# 日志文件路径
$logFile = "$PSScriptRoot\coze_auto_fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 日志记录函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Type] $Message"
    $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    # 根据类型选择颜色
    switch ($Type) {
        "Success" { $color = $COLOR_SUCCESS }
        "Error" { $color = $COLOR_ERROR }
        "Warning" { $color = $COLOR_WARNING }
        "Info" { $color = $COLOR_INFO }
        default { $color = $COLOR_INFO }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# 检查管理员权限
function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Error "需要以管理员身份运行此脚本！"
        Write-Host "请右键点击脚本并选择'以管理员身份运行'" -ForegroundColor $COLOR_WARNING
        Start-Sleep -Seconds 5
        Exit 1
    }
}

# 步骤1：卸载Docker Desktop
function Uninstall-DockerDesktop {
    Write-Host "`n=== 步骤1：卸载Docker Desktop ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始卸载Docker Desktop" "Info"
    
    try {
        # 停止Docker服务
        Write-Log "停止Docker服务" "Info"
        Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
        
        # 停止Docker进程
        Write-Log "停止Docker进程" "Info"
        Get-Process -Name *docker* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 检查Docker Desktop是否安装
        $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            Write-Log "运行Docker Desktop卸载程序" "Info"
            Start-Process -FilePath $dockerPath -ArgumentList "--uninstall" -Wait
            Write-Log "Docker Desktop卸载完成" "Success"
        } else {
            Write-Log "Docker Desktop未安装，跳过卸载步骤" "Info"
        }
    } catch {
        Write-Log "卸载Docker Desktop失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤2：清理WSL环境
function Cleanup-WSL {
    Write-Host "`n=== 步骤2：清理WSL环境 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始清理WSL环境" "Info"
    
    try {
        # 停止所有WSL分发版
        Write-Log "停止所有WSL分发版" "Info"
        wsl --shutdown
        Start-Sleep -Seconds 5
        
        # 注销Docker相关的WSL分发版
        Write-Log "注销Docker相关的WSL分发版" "Info"
        wsl --unregister docker-desktop 2>$null
        wsl --unregister docker-desktop-data 2>$null
        Start-Sleep -Seconds 5
        
        # 检查剩余的WSL分发版
        Write-Log "检查当前WSL分发版状态" "Info"
        $wslStatus = wsl -l -v
        Write-Log "WSL状态: $wslStatus" "Info"
        Write-Host $wslStatus -ForegroundColor $COLOR_INFO
        
        Write-Log "WSL环境清理完成" "Success"
    } catch {
        Write-Log "清理WSL环境失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 5
}

# 步骤3：清理Docker配置文件
function Cleanup-DockerConfig {
    Write-Host "`n=== 步骤3：清理Docker配置文件 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始清理Docker配置文件" "Info"
    
    try {
        # 删除Docker程序数据
        Write-Log "删除Docker程序数据" "Info"
        if (Test-Path "$env:ProgramData\Docker") {
            Remove-Item -Path "$env:ProgramData\Docker" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Docker程序数据删除成功" "Success"
        } else {
            Write-Log "Docker程序数据不存在，跳过删除步骤" "Info"
        }
        
        # 删除用户目录下的Docker配置
        Write-Log "删除用户目录下的Docker配置" "Info"
        if (Test-Path "$env:USERPROFILE\.docker") {
            Remove-Item -Path "$env:USERPROFILE\.docker" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "用户Docker配置删除成功" "Success"
        } else {
            Write-Log "用户Docker配置不存在，跳过删除步骤" "Info"
        }
        
        Write-Log "Docker配置文件清理完成" "Success"
    } catch {
        Write-Log "清理Docker配置文件失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 5
}

# 步骤4：重置WSL网络
function Reset-WSLNetwork {
    Write-Host "`n=== 步骤4：重置WSL网络 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始重置WSL网络" "Info"
    
    try {
        # 重置Winsock
        Write-Log "重置Winsock" "Info"
        netsh winsock reset | Out-Null
        Write-Log "Winsock重置成功" "Success"
        
        # 重置TCP/IP
        Write-Log "重置TCP/IP" "Info"
        netsh int ip reset | Out-Null
        Write-Log "TCP/IP重置成功" "Success"
        
        # 清除DNS缓存
        Write-Log "清除DNS缓存" "Info"
        ipconfig /flushdns | Out-Null
        Write-Log "DNS缓存清除成功" "Success"
        
        # 清除ARP缓存
        Write-Log "清除ARP缓存" "Info"
        arp -d * 2>$null | Out-Null
        Write-Log "ARP缓存清除成功" "Success"
        
        Write-Log "WSL网络重置完成" "Success"
    } catch {
        Write-Log "重置WSL网络失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 5
}

# 步骤5：重新安装Docker Desktop
function Install-DockerDesktop {
    Write-Host "`n=== 步骤5：安装Docker Desktop ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始安装Docker Desktop" "Info"
    
    try {
        # 检查是否已安装
        $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            Write-Log "Docker Desktop已安装，跳过安装步骤" "Info"
            return
        }
        
        # 打开微软商店下载页面
        Write-Log "打开微软商店下载Docker Desktop" "Info"
        Write-Host "正在打开微软商店，请手动下载并安装Docker Desktop..." -ForegroundColor $COLOR_WARNING
        Write-Host "下载完成后，请按任意键继续..." -ForegroundColor $COLOR_MENU
        
        # 打开微软商店
        Start-Process 'ms-windows-store://pdp/?ProductId=9PDXGNCFSCZV'
        
        # 等待用户输入
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        # 验证安装
        if (Test-Path $dockerPath) {
            Write-Log "Docker Desktop安装成功" "Success"
        } else {
            Write-Log "Docker Desktop安装验证失败，请手动确认安装状态" "Warning"
        }
    } catch {
        Write-Log "安装Docker Desktop失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤6：配置Docker国内镜像源
function Configure-DockerMirrors {
    Write-Host "`n=== 步骤6：配置Docker国内镜像源 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始配置Docker国内镜像源" "Info"
    
    try {
        # 创建Docker配置目录
        $dockerConfigDir = "$env:ProgramData\Docker\config"
        if (-not (Test-Path $dockerConfigDir)) {
            New-Item -Path $dockerConfigDir -ItemType Directory -Force | Out-Null
            Write-Log "创建Docker配置目录成功" "Info"
        }
        
        # 创建daemon.json配置文件
        $daemonConfig = @"
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.aityp.com",
    "https://mirror.aliyuncs.com",
    "https://hub-mirror.c.163.com",
    "https://mirrors.ustc.edu.cn/dockerhub/"
  ],
  "exec-opts": ["isolation=process"],
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "no-hosts": true,
  "max-concurrent-downloads": 10
}
"@
        
        $daemonConfigPath = "$dockerConfigDir\daemon.json"
        $daemonConfig | Out-File -FilePath $daemonConfigPath -Encoding UTF8 -Force
        Write-Log "Docker配置文件创建成功: $daemonConfigPath" "Success"
        
        # 显示配置内容
        Write-Log "Docker配置内容: $daemonConfig" "Info"
        
        # 重启Docker服务
        Write-Log "重启Docker服务以应用配置" "Info"
        try {
            Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            Start-Service -Name 'com.docker.service'
            Start-Sleep -Seconds 10
            Write-Log "Docker服务重启成功" "Success"
        } catch {
            Write-Log "重启Docker服务失败: $($_.Exception.Message)" "Warning"
            Write-Host "请手动重启Docker Desktop以应用配置" -ForegroundColor $COLOR_WARNING
        }
        
    } catch {
        Write-Log "配置Docker国内镜像源失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤7：验证Docker安装
function Test-DockerInstallation {
    Write-Host "`n=== 步骤7：验证Docker安装 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始验证Docker安装" "Info"
    
    try {
        # 检查Docker版本
        Write-Log "检查Docker版本" "Info"
        $dockerVersion = docker version 2>&1
        Write-Log "Docker版本信息: $dockerVersion" "Info"
        
        # 运行测试容器
        Write-Log "运行测试容器" "Info"
        $testResult = docker run hello-world 2>&1
        if ($testResult -match "Hello from Docker!") {
            Write-Log "Docker测试容器运行成功" "Success"
        } else {
            Write-Log "Docker测试容器运行失败: $testResult" "Warning"
        }
        
        # 检查WSL状态
        Write-Log "检查WSL状态" "Info"
        $wslStatus = wsl -l -v
        Write-Log "WSL状态: $wslStatus" "Info"
        Write-Host $wslStatus -ForegroundColor $COLOR_INFO
        
    } catch {
        Write-Log "验证Docker安装失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 5
}

# 步骤8：部署Coze Studio
function Deploy-CozeStudio {
    Write-Host "`n=== 步骤8：部署Coze Studio ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始部署Coze Studio" "Info"
    
    try {
        # 检查Coze Studio目录
        $cozePath = "$PSScriptRoot\coze-studio-0.5.0"
        $cozeDockerPath = "$cozePath\docker"
        
        if (-not (Test-Path $cozeDockerPath)) {
            Write-Log "Coze Studio目录不存在: $cozeDockerPath" "Error"
            Write-Host "请先下载并解压Coze Studio安装包" -ForegroundColor $COLOR_ERROR
            return
        }
        
        # 切换到Docker目录
        Set-Location -Path $cozeDockerPath
        Write-Log "切换到Coze Studio Docker目录: $cozeDockerPath" "Info"
        
        # 拉取镜像（使用国内镜像源）
        Write-Host "正在拉取Coze Studio镜像（首次运行需要较长时间）..." -ForegroundColor $COLOR_WARNING
        
        $images = @(
            "docker.1ms.run/cozedev/coze-studio-server:latest",
            "docker.1ms.run/cozedev/coze-studio-web:latest",
            "docker.1ms.run/mysql:8.4.5",
            "docker.1ms.run/bitnamilegacy/redis:8.0",
            "docker.1ms.run/bitnamilegacy/elasticsearch:8.18.0",
            "docker.1ms.run/minio/minio:RELEASE.2025-06-13T11-33-47Z-cpuv1",
            "docker.1ms.run/milvusdb/milvus:v2.5.10",
            "docker.1ms.run/nsqio/nsq:v1.2.1"
        )
        
        foreach ($image in $images) {
            Write-Log "拉取镜像: $image" "Info"
            try {
                docker pull $image
                Write-Log "镜像拉取成功: $image" "Success"
            } catch {
                Write-Log "镜像拉取失败: $image - $($_.Exception.Message)" "Error"
            }
        }
        
        # 启动服务
        Write-Log "启动Coze Studio服务" "Info"
        Write-Host "正在启动Coze Studio服务..." -ForegroundColor $COLOR_INFO
        
        try {
            docker compose --profile "*" up -d
            Write-Log "Coze Studio服务启动命令执行成功" "Success"
        } catch {
            Write-Log "启动Coze Studio服务失败: $($_.Exception.Message)" "Error"
        }
        
        # 等待服务启动
        Write-Host "等待服务启动完成（约60秒）..." -ForegroundColor $COLOR_INFO
        Start-Sleep -Seconds 60
        
        # 检查服务状态
        Write-Log "检查Coze Studio服务状态" "Info"
        $containers = docker ps
        Write-Log "容器状态: $containers" "Info"
        Write-Host $containers -ForegroundColor $COLOR_INFO
        
        # 显示访问地址
        Write-Host "`n=== Coze Studio 部署完成 ===" -ForegroundColor $COLOR_SUCCESS
        Write-Host "访问地址: http://localhost:8888" -ForegroundColor $COLOR_SUCCESS
        Write-Host "请在浏览器中打开上述地址访问Coze Studio" -ForegroundColor $COLOR_INFO
        
    } catch {
        Write-Log "部署Coze Studio失败: $($_.Exception.Message)" "Error"
    } finally {
        # 切换回脚本目录
        Set-Location -Path $PSScriptRoot
    }
    
    Start-Sleep -Seconds 5
}

# 主函数
function Main {
    # 检查管理员权限
    Check-Admin
    
    # 显示欢迎信息
    Write-Host "`n=== Coze Studio 自动化修复脚本 ===" -ForegroundColor $COLOR_TITLE
    Write-Host "版本: 1.0"
    Write-Host "用途: 自动解决Docker Desktop和Coze Studio部署问题"
    Write-Host "日志文件: $logFile"
    Write-Host "`n注意：此脚本会执行系统级操作，请确保您了解其影响" -ForegroundColor $COLOR_WARNING
    Write-Host "按任意键开始执行，或按Ctrl+C取消..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # 执行修复步骤
    Uninstall-DockerDesktop
    Cleanup-WSL
    Cleanup-DockerConfig
    Reset-WSLNetwork
    
    # 重启计算机
    Write-Host "`n=== 重启计算机 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "需要重启计算机以应用更改" "Info"
    Write-Host "计算机将在30秒后重启，请保存所有工作..." -ForegroundColor $COLOR_WARNING
    Write-Host "按任意键立即重启，或等待自动重启..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入或自动重启
    $timeout = 30
    $counter = 0
    while ($counter -lt $timeout) {
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
        $counter++
        
        # 检查是否有按键输入
        if ($Host.UI.RawUI.KeyAvailable) {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            break
        }
    }
    
    Write-Host "`n正在重启计算机..." -ForegroundColor $COLOR_INFO
    Restart-Computer -Force
    
    # 重启后继续执行的步骤（需要手动再次运行）
    # Install-DockerDesktop
    # Configure-DockerMirrors
    # Test-DockerInstallation
    # Deploy-CozeStudio
    
    # 显示完成信息
    Write-Host "`n=== 修复完成 ===" -ForegroundColor $COLOR_SUCCESS
    Write-Host "所有修复步骤已执行完成" -ForegroundColor $COLOR_INFO
    Write-Host "日志文件: $logFile" -ForegroundColor $COLOR_INFO
    Write-Host "`n如果遇到问题，请查看日志文件或联系技术支持" -ForegroundColor $COLOR_WARNING
    Write-Host "`n按任意键退出..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 执行主函数
Main
