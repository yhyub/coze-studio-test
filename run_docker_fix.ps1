<#
非交互式执行coze_studio_toolkit.ps1的Docker修复功能
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'

Write-Host "`n=== 运行Docker修复功能 ===" -ForegroundColor $COLOR_TITLE

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

# Docker修复模块
function Fix-Docker {
    Write-Host "`n=== Docker Desktop 问题修复 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行Docker修复功能" "Info"
    
    # 1. 检查当前Docker版本
    Write-Log "检查当前Docker版本" "Info"
    try {
        docker version
    } catch {
        Write-Log "无法获取Docker版本信息: $($_.Exception.Message)" "Error"
    }
    
    # 2. 修复hosts文件权限
    Write-Log "修复hosts文件权限" "Info"
    try {
        $acl = Get-Acl "C:\windows\System32\drivers\etc\hosts"
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "Allow")
        $acl.SetAccessRule($rule)
        Set-Acl "C:\windows\System32\drivers\etc\hosts" $acl
        Write-Log "hosts文件权限修复成功" "Success"
    } catch {
        Write-Log "修复hosts文件权限失败: $($_.Exception.Message)" "Error"
    }
    
    # 3. 停止并清理Docker相关进程
    Write-Log "停止并清理Docker相关进程" "Info"
    try {
        Get-Process -Name *docker* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Service -Name *docker* -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
        Write-Log "Docker进程和服务已停止" "Success"
    } catch {
        Write-Log "停止Docker进程失败: $($_.Exception.Message)" "Error"
    }
    
    # 4. 重置Docker Desktop设置
    Write-Log "重置Docker Desktop设置" "Info"
    try {
        $dockerDataPath = "$env:ProgramData\Docker"
        $dockerConfigPath = "$env:USERPROFILE\.docker"
        
        if (Test-Path $dockerDataPath) {
            Rename-Item -Path $dockerDataPath -NewName "$dockerDataPath.bak" -Force
            Write-Log "Docker数据目录已备份" "Success"
        }
        
        if (Test-Path $dockerConfigPath) {
            Rename-Item -Path $dockerConfigPath -NewName "$dockerConfigPath.bak" -Force
            Write-Log "Docker配置目录已备份" "Success"
        }
        
        Start-Sleep -Seconds 5
        
        # 重新启动Docker服务
        Start-Service -Name 'com.docker.service'
        Write-Log "Docker服务已重启" "Success"
    } catch {
        Write-Log "重置Docker设置失败: $($_.Exception.Message)" "Error"
    }
    
    # 5. 修复Docker API版本问题
    Write-Log "修复Docker API版本问题" "Info"
    
    # 尝试不同的API版本
    $apiVersions = @('1.51', '1.50', '1.49', '1.48', '1.47', '1.46')
    $workingVersion = $null
    
    foreach ($version in $apiVersions) {
        Write-Log "尝试API版本: $version" "Info"
        $env:DOCKER_API_VERSION = $version
        
        try {
            $serverInfo = docker version --format '{{json .Server}}' 2>&1
            if ($serverInfo -notlike "*Error*" -and $serverInfo -ne "") {
                Write-Log "成功连接！API版本: $version" "Success"
                $workingVersion = $version
                break
            }
        } catch {
            # 忽略错误
        }
    }
    
    if ($workingVersion) {
        Write-Log "将API版本保存到环境变量" "Info"
        [Environment]::SetEnvironmentVariable("DOCKER_API_VERSION", $workingVersion, "Process")
    } else {
        Write-Log "无法找到兼容的API版本，正在尝试切换引擎" "Warning"
        try {
            & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchDaemon
            Start-Sleep -Seconds 5
            docker version
            Write-Log "Docker引擎已切换" "Success"
        } catch {
            Write-Log "切换Docker引擎失败: $($_.Exception.Message)" "Error"
        }
    }
    
    Write-Log "Docker修复功能执行完成" "Info"
    Write-Host "`n=== Docker修复完成 ===" -ForegroundColor $COLOR_SUCCESS
}

# 执行Docker修复
Fix-Docker

Write-Host "`n=== 修复完成 ===" -ForegroundColor $COLOR_TITLE
Write-Host "正在重新启动Docker Desktop..." -ForegroundColor $COLOR_INFO
Start-Sleep -Seconds 10
