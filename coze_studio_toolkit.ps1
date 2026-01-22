<#
.SYNOPSIS
Coze Studio 工具包 - 综合管理和修复脚本

.DESCRIPTION
此脚本整合了docs和scripts文件夹中的所有功能，包括：
1. Docker Desktop 问题修复
2. GitHub 访问问题修复
3. Coze Studio 部署和启动
4. 系统网络优化
5. 配置文件管理

.NOTES
需要以管理员身份运行
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_MENU = 'Cyan'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'

Write-Host "`n=== Coze Studio 工具包 ===" -ForegroundColor $COLOR_TITLE
Write-Host "综合管理和修复脚本 v1.0" -ForegroundColor $COLOR_INFO

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

# 显示菜单
function Show-Menu {
    Write-Host "`n请选择要执行的功能：" -ForegroundColor $COLOR_MENU
    Write-Host "1. Docker Desktop 问题修复" -ForegroundColor $COLOR_MENU
    Write-Host "2. GitHub 访问问题修复" -ForegroundColor $COLOR_MENU
    Write-Host "3. Coze Studio 部署" -ForegroundColor $COLOR_MENU
    Write-Host "4. Coze Studio 启动" -ForegroundColor $COLOR_MENU
    Write-Host "5. 系统网络优化" -ForegroundColor $COLOR_MENU
    Write-Host "6. 配置文件管理" -ForegroundColor $COLOR_MENU
    Write-Host "0. 退出脚本" -ForegroundColor $COLOR_MENU
    
    $choice = Read-Host "`n请输入您的选择 (0-6)"
    return $choice
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

# GitHub访问修复模块
function Fix-GitHubAccess {
    Write-Host "`n=== GitHub 访问问题修复 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行GitHub访问修复功能" "Info"
    
    $hostsPath = "C:\windows\System32\drivers\etc\hosts"
    
    # 1. 修复hosts文件权限
    Write-Log "修复hosts文件权限" "Info"
    try {
        $acl = Get-Acl $hostsPath
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $permission = $currentUser, "Modify", "Allow"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl $hostsPath $acl
        Write-Log "hosts文件权限已修复" "Success"
    } catch {
        Write-Log "修复hosts文件权限失败: $($_.Exception.Message)" "Error"
    }
    
    # 2. 添加GitHub相关IP条目
    Write-Log "添加GitHub相关IP条目到hosts文件" "Info"
    try {
        $hostsContent = Get-Content $hostsPath -Raw
        
        # 定义GitHub相关IP条目
        $githubHosts = @"

# GitHub访问优化（修复2345浏览器访问问题）
140.82.114.3 github.com
140.82.114.4 gist.github.com
185.199.108.153 assets-cdn.github.com
185.199.109.153 assets-cdn.github.com
185.199.110.153 assets-cdn.github.com
185.199.111.153 assets-cdn.github.com
199.232.69.194 github.global.ssl.fastly.net
140.82.114.9 codeload.github.com
140.82.114.10 api.github.com
185.199.111.133 raw.githubusercontent.com
185.199.110.133 raw.githubusercontent.com
185.199.109.133 raw.githubusercontent.com
185.199.108.133 raw.githubusercontent.com
"@
        
        # 如果hosts文件中没有GitHub条目，则添加
        if (-not $hostsContent.Contains("# GitHub访问优化")) {
            Add-Content -Path $hostsPath -Value $githubHosts
            Write-Log "GitHub hosts条目已添加" "Success"
        } else {
            Write-Log "GitHub hosts条目已存在" "Info"
        }
    } catch {
        Write-Log "修改hosts文件失败: $($_.Exception.Message)" "Error"
    }
    
    # 3. 清除网络缓存
    Write-Log "清除网络缓存" "Info"
    try {
        # 清除DNS缓存
        ipconfig /flushdns | Out-Null
        Write-Log "DNS缓存已清除" "Success"
        
        # 重置Winsock
        netsh winsock reset | Out-Null
        Write-Log "Winsock已重置" "Success"
        
        # 重置TCP/IP
        netsh int ip reset | Out-Null
        Write-Log "TCP/IP已重置" "Success"
    } catch {
        Write-Log "清除网络缓存失败: $($_.Exception.Message)" "Error"
    }
    
    # 4. 验证GitHub连接
    Write-Log "验证GitHub连接" "Info"
    try {
        $githubTest = Test-Connection -ComputerName github.com -Count 1 -Quiet
        if ($githubTest) {
            Write-Log "GitHub连接正常" "Success"
        } else {
            Write-Log "GitHub连接测试失败" "Warning"
        }
    } catch {
        Write-Log "验证GitHub连接失败: $($_.Exception.Message)" "Error"
    }
    
    Write-Log "GitHub访问修复功能执行完成" "Info"
    Write-Host "`n=== GitHub访问修复完成 ===" -ForegroundColor $COLOR_SUCCESS
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

# Coze Studio启动模块
function Start-CozeStudio {
    Write-Host "`n=== Coze Studio 启动 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行Coze Studio启动功能" "Info"
    
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
    
    Write-Log "Coze Studio Docker目录: $cozeDockerPath" "Info"
    
    # 检查目录是否存在
    if (-not (Test-Path $cozeDockerPath)) {
        Write-Log "Coze Studio目录不存在" "Error"
        Write-Host "请先下载并解压Coze Studio安装包" -ForegroundColor $COLOR_WARNING
        return
    }
    
    # 启动Coze Studio服务
    try {
        Set-Location -Path $cozeDockerPath
        Write-Log "正在启动Coze Studio服务" "Info"
        
        docker compose --profile "*" up -d
        Write-Log "Coze Studio服务启动命令已执行" "Success"
        
        # 等待服务启动完成
        Write-Log "等待服务启动完成..." "Info"
        $maxWaitTime = 600  # 最大等待时间（秒）
        $waitTime = 0
        $serviceStarted = $false
        
        while ($waitTime -lt $maxWaitTime -and -not $serviceStarted) {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 5
            $waitTime += 5
            
            # 检查coze-server容器状态
            try {
                $containerStatus = docker ps --filter "name=coze-server" --format "{{.Status}}" 2>&1
                if ($containerStatus -match "Up") {
                    $serviceStarted = $true
                    Write-Host ""
                    Write-Log "Coze Studio服务已成功启动" "Success"
                }
            } catch {
                # 忽略错误，继续等待
            }
        }
        
        if (-not $serviceStarted) {
            Write-Host ""
            Write-Log "Coze Studio服务启动超时" "Warning"
        } else {
            # 显示服务状态
            Write-Log "显示Coze Studio服务状态" "Info"
            docker ps --filter "name=coze-"
            
            # 显示访问地址
            Write-Host "`n访问Coze Studio控制台:" -ForegroundColor $COLOR_MENU
            Write-Host "   本地访问地址: http://localhost:8888" -ForegroundColor $COLOR_SUCCESS
            Write-Host "   请在浏览器中访问上述地址" -ForegroundColor $COLOR_WARNING
        }
        
    } catch {
        Write-Log "启动Coze Studio服务失败: $($_.Exception.Message)" "Error"
    } finally {
        Set-Location -Path $PSScriptRoot
    }
    
    Write-Log "Coze Studio启动功能执行完成" "Info"
    Write-Host "`n=== Coze Studio启动完成 ===" -ForegroundColor $COLOR_SUCCESS
}

# 系统优化模块
function Optimize-System {
    Write-Host "`n=== 系统网络优化 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行系统优化功能" "Info"
    
    # 1. 修复hosts文件
    Write-Log "修复hosts文件" "Info"
    try {
        $hostsPath = "C:\windows\System32\drivers\etc\hosts"
        $acl = Get-Acl $hostsPath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "Allow")
        $acl.SetAccessRule($rule)
        Set-Acl $hostsPath $acl
        Write-Log "hosts文件权限修复成功" "Success"
    } catch {
        Write-Log "修复hosts文件失败: $($_.Exception.Message)" "Error"
    }
    
    # 2. 清理网络缓存
    Write-Log "清理网络缓存" "Info"
    try {
        # 清除DNS缓存
        ipconfig /flushdns | Out-Null
        Write-Log "DNS缓存已清除" "Success"
        
        # 重置Winsock
        netsh winsock reset | Out-Null
        Write-Log "Winsock已重置" "Success"
        
        # 重置TCP/IP
        netsh int ip reset | Out-Null
        Write-Log "TCP/IP已重置" "Success"
        
        # 清除ARP缓存
        arp -d * | Out-Null
        Write-Log "ARP缓存已清除" "Success"
    } catch {
        Write-Log "清理网络缓存失败: $($_.Exception.Message)" "Error"
    }
    
    # 3. 显示网络状态
    Write-Log "显示网络状态" "Info"
    try {
        ipconfig /all | Select-String -Pattern "IPv4 Address|DNS Servers|Default Gateway"
    } catch {
        Write-Log "获取网络状态失败: $($_.Exception.Message)" "Error"
    }
    
    Write-Log "系统优化功能执行完成" "Info"
    Write-Host "`n=== 系统优化完成 ===" -ForegroundColor $COLOR_SUCCESS
}

# 配置管理模块
function Manage-Config {
    Write-Host "`n=== 配置文件管理 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始执行配置管理功能" "Info"
    
    # 1. 备份Docker配置
    Write-Log "备份Docker配置" "Info"
    try {
        $dockerConfigPath = "$env:ProgramData\Docker\config\daemon.json"
        if (Test-Path $dockerConfigPath) {
            $backupPath = "$PSScriptRoot\daemon.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $dockerConfigPath $backupPath -Force
            Write-Log "Docker配置已备份到: $backupPath" "Success"
        } else {
            Write-Log "Docker配置文件不存在" "Warning"
        }
    } catch {
        Write-Log "备份Docker配置失败: $($_.Exception.Message)" "Error"
    }
    
    # 2. 准备新的Docker配置
    Write-Log "准备新的Docker配置" "Info"
    try {
        $newConfig = @"
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
"@
        
        $newConfigPath = "$PSScriptRoot\daemon.json.new"
        $newConfig | Out-File -FilePath $newConfigPath -Encoding UTF8 -Force
        Write-Log "新的Docker配置已准备: $newConfigPath" "Success"
        Write-Host "使用方法: 将此文件复制到 $env:ProgramData\Docker\config\daemon.json" -ForegroundColor $COLOR_INFO
    } catch {
        Write-Log "准备Docker配置失败: $($_.Exception.Message)" "Error"
    }
    
    Write-Log "配置管理功能执行完成" "Info"
    Write-Host "`n=== 配置管理完成 ===" -ForegroundColor $COLOR_SUCCESS
}

# 主程序入口
function Main {
    # 检查管理员权限
    Check-Admin
    
    while ($true) {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" {
                Fix-Docker
            }
            "2" {
                Fix-GitHubAccess
            }
            "3" {
                Deploy-CozeStudio
            }
            "4" {
                Start-CozeStudio
            }
            "5" {
                Optimize-System
            }
            "6" {
                Manage-Config
            }
            "0" {
                Write-Host "`n感谢使用Coze Studio工具包！" -ForegroundColor $COLOR_TITLE
                Write-Log "脚本执行结束" "Info"
                break
            }
            default {
                Write-Host "无效的选择，请重新输入" -ForegroundColor $COLOR_ERROR
            }
        }
        
        if ($choice -eq "0") {
            break
        }
        
        Write-Host "`n按任意键继续..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# 执行主程序
Main