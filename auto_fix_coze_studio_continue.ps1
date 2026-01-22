<#
Coze Studio 自动化修复脚本（重启后继续）

此脚本用于在计算机重启后继续执行以下步骤：
1. 安装Docker Desktop
2. 配置Docker国内镜像源
3. 验证Docker安装
4. 部署Coze Studio

使用方法：
1. 以管理员身份运行此脚本
2. 按照提示操作
3. 等待脚本执行完成

注意：此脚本应在执行完 auto_fix_coze_studio.ps1 并重启计算机后运行
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'
$COLOR_MENU = 'Cyan'

# 日志文件路径
$logFile = "$PSScriptRoot\coze_auto_fix_continue_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# 步骤1：安装Docker Desktop
function Install-DockerDesktop {
    Write-Host "`n=== 步骤1：安装Docker Desktop ===" -ForegroundColor $COLOR_TITLE
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

# 步骤2：配置Docker国内镜像源
function Configure-DockerMirrors {
    Write-Host "`n=== 步骤2：配置Docker国内镜像源 ===" -ForegroundColor $COLOR_TITLE
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
            # 启动Docker Desktop应用程序
            $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerPath) {
                Write-Log "启动Docker Desktop应用程序" "Info"
                Start-Process -FilePath $dockerPath
                Write-Host "正在启动Docker Desktop，请等待其完全启动..." -ForegroundColor $COLOR_WARNING
                Write-Host "启动完成后，请按任意键继续..." -ForegroundColor $COLOR_MENU
                
                # 等待用户输入
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            
            # 尝试重启Docker服务
            Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            Start-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
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

# 步骤3：验证Docker安装
function Test-DockerInstallation {
    Write-Host "`n=== 步骤3：验证Docker安装 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始验证Docker安装" "Info"
    
    try {
        # 检查Docker版本
        Write-Log "检查Docker版本" "Info"
        $dockerVersion = docker version 2>&1
        Write-Log "Docker版本信息: $dockerVersion" "Info"
        Write-Host $dockerVersion -ForegroundColor $COLOR_INFO
        
        # 运行测试容器
        Write-Log "运行测试容器" "Info"
        Write-Host "正在运行Docker测试容器..." -ForegroundColor $COLOR_INFO
        $testResult = docker run hello-world 2>&1
        if ($testResult -match "Hello from Docker!") {
            Write-Log "Docker测试容器运行成功" "Success"
            Write-Host "Docker测试容器运行成功" -ForegroundColor $COLOR_SUCCESS
        } else {
            Write-Log "Docker测试容器运行失败: $testResult" "Warning"
            Write-Host "Docker测试容器运行失败，请检查Docker状态" -ForegroundColor $COLOR_WARNING
        }
        
        # 检查WSL状态
        Write-Log "检查WSL状态" "Info"
        $wslStatus = wsl -l -v
        Write-Log "WSL状态: $wslStatus" "Info"
        Write-Host $wslStatus -ForegroundColor $COLOR_INFO
        
        # 检查Docker相关的WSL分发版
        if ($wslStatus -match "docker-desktop" -and $wslStatus -match "docker-desktop-data") {
            Write-Log "Docker WSL分发版已成功创建" "Success"
            Write-Host "Docker WSL分发版已成功创建" -ForegroundColor $COLOR_SUCCESS
        } else {
            Write-Log "Docker WSL分发版未找到，请检查Docker Desktop状态" "Warning"
            Write-Host "Docker WSL分发版未找到，请检查Docker Desktop状态" -ForegroundColor $COLOR_WARNING
        }
        
    } catch {
        Write-Log "验证Docker安装失败: $($_.Exception.Message)" "Error"
        Write-Host "验证Docker安装失败，请检查系统状态" -ForegroundColor $COLOR_ERROR
    }
    
    Start-Sleep -Seconds 5
}

# 步骤4：部署Coze Studio
function Deploy-CozeStudio {
    Write-Host "`n=== 步骤4：部署Coze Studio ===" -ForegroundColor $COLOR_TITLE
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
        
        # 检查服务健康状态
        Write-Host "`n=== 服务健康状态检查 ===" -ForegroundColor $COLOR_TITLE
        $services = @(
            "coze-server",
            "coze-web",
            "coze-mysql",
            "coze-redis",
            "coze-elasticsearch",
            "coze-minio",
            "coze-milvus",
            "coze-nsq"
        )
        
        foreach ($service in $services) {
            try {
                $containerStatus = docker ps --filter "name=$service" --format "{{.Status}}" 2>&1
                if ($containerStatus -match "Up") {
                    Write-Host "✅ $service: 运行中" -ForegroundColor $COLOR_SUCCESS
                } else {
                    Write-Host "❌ $service: 未运行" -ForegroundColor $COLOR_ERROR
                    # 显示容器日志
                    $logs = docker logs $service --tail 10 2>&1
                    Write-Host "日志: $logs" -ForegroundColor $COLOR_INFO
                }
            } catch {
                Write-Host "❌ $service: 检查失败" -ForegroundColor $COLOR_ERROR
            }
        }
        
        # 显示访问地址
        Write-Host "`n=== Coze Studio 部署完成 ===" -ForegroundColor $COLOR_SUCCESS
        Write-Host "访问地址: http://localhost:8888" -ForegroundColor $COLOR_SUCCESS
        Write-Host "请在浏览器中打开上述地址访问Coze Studio" -ForegroundColor $COLOR_INFO
        Write-Host "`n如果服务未完全启动，请等待几分钟后刷新页面" -ForegroundColor $COLOR_WARNING
        
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
    Write-Host "`n=== Coze Studio 自动化修复脚本（重启后继续）===" -ForegroundColor $COLOR_TITLE
    Write-Host "版本: 1.0"
    Write-Host "用途: 完成Docker Desktop安装和Coze Studio部署"
    Write-Host "日志文件: $logFile"
    Write-Host "`n注意：此脚本应在执行完 auto_fix_coze_studio.ps1 并重启计算机后运行" -ForegroundColor $COLOR_WARNING
    Write-Host "按任意键开始执行，或按Ctrl+C取消..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # 执行修复步骤
    Install-DockerDesktop
    Configure-DockerMirrors
    Test-DockerInstallation
    Deploy-CozeStudio
    
    # 显示完成信息
    Write-Host "`n=== 修复完成 ===" -ForegroundColor $COLOR_SUCCESS
    Write-Host "所有修复步骤已执行完成" -ForegroundColor $COLOR_INFO
    Write-Host "日志文件: $logFile" -ForegroundColor $COLOR_INFO
    Write-Host "`nCoze Studio 已成功部署，访问地址: http://localhost:8888" -ForegroundColor $COLOR_SUCCESS
    Write-Host "`n如果遇到问题，请查看日志文件或联系技术支持" -ForegroundColor $COLOR_WARNING
    Write-Host "`n按任意键退出..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 执行主函数
Main
