<#
非交互式执行Coze Studio部署功能
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'

Write-Host "`n=== Coze Studio 部署 ===" -ForegroundColor $COLOR_TITLE

# 日志记录函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logPath = "$PSScriptRoot\coze_toolkit_$(Get-Date -Format 'yyyyMMdd').log"
    
    $logEntry = "[$timestamp] [$Type] $Message"
    $logEntry | Out-File -FilePath $logPath -Append
    
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

# Coze Studio部署模块
function Deploy-CozeStudio {
    Write-Host "`n=== Coze Studio 部署 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行Coze Studio部署功能" "Info"
    
    # 检查Docker服务状态
    Write-Log "检查Docker服务状态" "Info"
    $dockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
    if ($dockerService -eq $null -or $dockerService.Status -ne 'Running') {
        Write-Log "Docker服务未运行，正在启动" "Warning"
        try {
            Start-Service -Name 'com.docker.service'
            Start-Sleep -Seconds 10
            Write-Log "Docker服务已启动" "Success"
        } catch {
            Write-Log "启动Docker服务失败: $($_.Exception.Message)" "Error"
            return
        }
    } else {
        Write-Log "Docker服务正在运行" "Success"
    }
    
    # 定义Coze Studio目录路径
    $cozePath = "$PSScriptRoot\coze-studio-0.5.0"
    $cozeDockerPath = "$cozePath\docker"
    
    Write-Log "Coze Studio目录: $cozeDockerPath" "Info"
    
    # 检查目录是否存在
    if (-not (Test-Path $cozeDockerPath)) {
        Write-Log "Coze Studio目录不存在" "Error"
        Write-Host "请先下载并解压Coze Studio安装包" -ForegroundColor $COLOR_WARNING
        return
    }
    
    # 切换到Docker目录并启动服务
    try {
        Set-Location -Path $cozeDockerPath
        Write-Log "正在拉取Coze Studio镜像" "Info"
        Write-Host "首次运行需下载镜像（约5-10分钟，取决于网络）" -ForegroundColor $COLOR_WARNING
        
        $pullCommands = @(
            "docker pull docker.1ms.run/cozedev/coze-studio-server:latest",
            "docker pull docker.1ms.run/cozedev/coze-studio-web:latest",
            "docker pull docker.1ms.run/mysql:8.4.5",
            "docker pull docker.1ms.run/bitnamilegacy/redis:8.0",
            "docker pull docker.1ms.run/bitnamilegacy/elasticsearch:8.18.0",
            "docker pull docker.1ms.run/minio/minio:RELEASE.2025-06-13T11-33-47Z-cpuv1",
            "docker pull docker.1ms.run/milvusdb/milvus:v2.5.10",
            "docker pull docker.1ms.run/nsqio/nsq:v1.2.1"
        )
        
        foreach ($cmd in $pullCommands) {
            Write-Log "执行命令: $cmd" "Info"
            Invoke-Expression $cmd
        }
        
        Write-Log "Coze Studio镜像拉取完成" "Success"
    } catch {
        Write-Log "拉取Coze Studio镜像失败: $($_.Exception.Message)" "Error"
    } finally {
        Set-Location -Path $PSScriptRoot
    }
    
    Write-Log "Coze Studio部署功能执行完成" "Info"
    Write-Host "`n=== Coze Studio部署完成 ===" -ForegroundColor $COLOR_SUCCESS
}

# 执行Coze Studio部署
Deploy-CozeStudio

Write-Host "`n=== 部署完成 ===" -ForegroundColor $COLOR_TITLE
