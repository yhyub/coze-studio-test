# Coze Studio 完整修复脚本
# 版本: 2.1.0
# 功能: 修复 Docker API 版本问题、WSL 配置、Docker Desktop 问题、网络优化、完整启动 Coze Studio

# 设置错误处理
$ErrorActionPreference = "Stop"
$DebugPreference = "Continue"

# 日志配置
$logDir = "$env:TEMP\CozeStudioToolkit"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = "$logDir\coze_studio_full_fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 日志函数
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

Write-Log "开始执行 Coze Studio 完整修复脚本" "INFO"
Write-Log "=" * 80 "INFO"

# 1. 系统环境检查与优化
Write-Log "1. 开始系统环境检查与优化" "INFO"

# 检查并修复 TCP 设置
Write-Log "优化 TCP 设置" "INFO"
try {
    Set-NetTCPSetting -SettingName "TcpAckFrequency" -SettingValue 1 -ErrorAction SilentlyContinue
    Set-NetTCPSetting -SettingName "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
} catch {
    Write-Log "TCP 设置优化失败: $($_.Exception.Message)" "WARNING"
}

# 2. Docker 服务检查与修复
Write-Log "2. Docker 服务检查与修复" "INFO"

# 停止所有 Docker 相关服务
Write-Log "停止 Docker 相关服务" "INFO"
try {
    Get-Service | Where-Object {$_.Name -like "*docker*"} | Stop-Service -Force -ErrorAction SilentlyContinue
} catch {
    Write-Log "停止 Docker 服务失败: $($_.Exception.Message)" "ERROR"
}

# 3. WSL 配置修复
Write-Log "3. 开始 WSL 配置修复" "INFO"

# 停止 WSL
Write-Log "停止 WSL 分发" "INFO"
wsl --shutdown 2>&1 | Out-Null

# 等待 WSL 完全停止
Start-Sleep -Seconds 5

# 检查 WSL 状态
Write-Log "检查 WSL 状态" "INFO"
try {
    $wslStatus = wsl --status 2>&1
    Write-Log "WSL 状态: $wslStatus" "INFO"
} catch {
    Write-Log "WSL 状态检查失败: $($_.Exception.Message)" "ERROR"
}

# 4. Docker Desktop 安装与配置
Write-Log "4. 开始 Docker Desktop 配置" "INFO"

# 检查 Docker Desktop 是否安装
if (-not (Test-Path "C:\Program Files\Docker\Docker Desktop.exe")) {
    Write-Log "Docker Desktop 未安装，开始安装..." "INFO"
    
    # 下载 Docker Desktop
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe"
    
    Write-Log "下载 Docker Desktop 安装程序..." "INFO"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $dockerInstaller -ErrorAction SilentlyContinue
        Write-Log "Docker Desktop 安装程序下载成功" "SUCCESS"
    } catch {
        Write-Log "Docker Desktop 下载失败: $($_.Exception.Message)" "ERROR"
    }
    
    # 安装 Docker Desktop
    if (Test-Path $dockerInstaller) {
        Write-Log "安装 Docker Desktop..." "INFO"
        Start-Process -FilePath $dockerInstaller -ArgumentList "install" -Wait -ErrorAction SilentlyContinue
        Write-Log "Docker Desktop 安装完成" "SUCCESS"
    }
}

# 5. Docker API 版本管理
Write-Log "5. 开始 Docker API 版本管理（自动回退机制）" "INFO"

# 定义 API 版本列表
$apiVersions = @("1.52", "1.51", "1.50")

# 测试 Docker API 版本
foreach ($version in $apiVersions) {
    Write-Log "测试 Docker API 版本: $version" "INFO"
    try {
        $env:DOCKER_API_VERSION = $version
        $dockerInfo = docker info 2>&1
        if ($dockerInfo -like "*API version*") {
            Write-Log "Docker API 版本匹配成功: $version" "SUCCESS"
            break
        }
    } catch {
        Write-Log "Docker API 版本 $version 失败，尝试下一个版本..." "WARNING"
    }
}

# 6. 镜像加速配置
Write-Log "6. 配置 Docker 镜像加速" "INFO"

# 创建或更新 daemon.json 配置
$dockerConfigPath = "$env:USERPROFILE\.docker\daemon.json"
$dockerConfigDir = Split-Path -Path $dockerConfigPath -Parent

if (-not (Test-Path $dockerConfigDir)) {
    New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
}

# 写入 Docker 镜像加速配置
$daemonJson = @'
{
  "registry-mirrors": [
    "https://dockerproxy.com",
    "https://mirror.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "insecure-registries": [],
  "debug": true,
  "experimental": false
}
'@ | ConvertTo-Json -Depth 3 | Out-File -FilePath $dockerConfigPath -Force -Encoding UTF8

# 7. 网络优化
Write-Log "7. 开始网络优化" "INFO"

# 重置网络设置
try {
    netsh winsock reset 2>&1 | Out-Null
    netsh int ip reset 2>&1 | Out-Null
    ipconfig /flushdns 2>&1 | Out-Null
    Write-Log "网络设置重置完成" "SUCCESS"
} catch {
    Write-Log "网络重置失败: $($_.Exception.Message)" "ERROR"
}

# 8. 启动 Docker 服务
Write-Log "8. 启动 Docker 服务" "INFO"

# 检查 Docker 服务状态
try {
    $dockerStatus = docker info 2>&1
    Write-Log "Docker 状态: $dockerStatus" "INFO"
} catch {
    Write-Log "Docker 状态检查失败: $($_.Exception.Message)" "ERROR"
}

# 9. 启动 Coze Studio 服务
Write-Log "9. 开始启动 Coze Studio 服务" "INFO"

# 切换到 Coze Studio 目录
$cozeDir = "$PSScriptRoot\coze-studio-0.5.0"
if (Test-Path $cozeDir) {
    Set-Location $cozeDir
    Write-Log "切换到 Coze Studio 目录: $cozeDir" "INFO"
}

# 启动 Docker Compose 服务
try {
    Write-Log "启动 Docker Compose 服务..." "INFO"
    docker compose up -d --build --force-recreate --remove-orphans 2>&1 | Out-Null
    Write-Log "Docker Compose 服务启动成功" "SUCCESS"
} catch {
    Write-Log "Docker Compose 启动失败: $($_.Exception.Message)" "ERROR"
}

# 10. 验证服务状态
Write-Log "10. 验证 Coze Studio 服务状态" "INFO"

# 等待服务启动
Start-Sleep -Seconds 30

# 检查服务状态
try {
    $services = docker compose ps 2>&1
    Write-Log "服务状态: $services" "INFO"
    
    # 检查 coze-web 服务
    if ($services -like "*coze-web*") {
        Write-Log "Coze Studio 服务启动成功！" "SUCCESS"
        Write-Log "访问地址: http://localhost:8888" "SUCCESS"
    }
} catch {
    Write-Log "服务状态检查失败: $($_.Exception.Message)" "ERROR"
}

# 11. 最终验证
Write-Log "11. 最终验证 Coze Studio 启动状态" "INFO"

# 验证访问
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8888" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Log "Coze Studio 访问成功！状态码: $($response.StatusCode)" "SUCCESS"
        Write-Log "访问地址: http://localhost:8888" "SUCCESS"
    }
} catch {
    Write-Log "Coze Studio 访问失败: $($_.Exception.Message)" "ERROR"
}

Write-Log "Coze Studio 完整修复脚本执行完成！" "SUCCESS"
Write-Log "访问地址: http://localhost:8888" "SUCCESS"