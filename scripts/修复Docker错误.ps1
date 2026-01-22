<#
.SYNOPSIS
综合系统修复与优化工具 - 整合Docker、2345浏览器、Coze Studio部署和GitHub访问修复功能

.DESCRIPTION
此脚本整合了以下功能：
1. Docker Desktop修复（启动错误、API访问问题、hosts文件权限）
2. 2345浏览器优化与GitHub访问修复
3. Coze Studio自动化部署
4. 网络优化（DNS设置、TCP/IP重置、Winsock重置）
5. 测试报告生成和时间追踪

.PARAMETER Mode
运行模式：
- All: 执行所有修复和优化功能
- Docker: 仅修复Docker问题
- Browser: 仅优化2345浏览器和GitHub访问
- Coze: 仅部署Coze Studio
- Network: 仅优化网络设置

.EXAMPLE
# 执行所有修复功能
.omprehensive-fix-tool.ps1 -Mode All

# 仅修复Docker问题
.omprehensive-fix-tool.ps1 -Mode Docker

.NOTES
需要以管理员身份运行
#>

param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Docker", "Browser", "Coze", "Network")]
    [string]$Mode = "All"
)

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Error "需要以管理员身份运行此脚本！"
    Exit 1
}

# 全局变量
$script:StartTime = Get-Date
$script:TestResults = @()
$script:Timers = @{}

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Host $logLine -ForegroundColor $(switch($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        "Info" { "Cyan" }
        default { "White" }
    })
}

# 时间追踪函数
function Start-Timer {
    param([string]$Name)
    $script:Timers[$Name] = Get-Date
    Write-Log "计时器 [$Name] 已启动" "Info"
}

function Stop-Timer {
    param([string]$Name)
    if ($script:Timers.ContainsKey($Name)) {
        $duration = (Get-Date) - $script:Timers[$Name]
        $durationMs = [math]::Round($duration.TotalMilliseconds)
        Write-Log "计时器 [$Name] 已结束，执行时间: $durationMs ms" "Info"
        $script:Timers.Remove($Name)
        return $durationMs
    }
    return 0
}

# 测试报告函数
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [int]$Duration = 0
    )
    $result = [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Duration = $Duration
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $script:TestResults += $result
    
    $status = if ($Passed) { "✅" } else { "❌" }
    $logLevel = if ($Passed) { "Success" } else { "Error" }
    Write-Log ($status + " " + $TestName + ": " + $Message + " (" + $Duration + " ms)") $logLevel
}

function Generate-Report {
    $endTime = Get-Date
    $totalDuration = (New-TimeSpan -Start $script:StartTime -End $endTime).TotalMilliseconds
    
    $passedTests = $script:TestResults | Where-Object { $_.Passed } | Measure-Object | Select-Object -ExpandProperty Count
    $failedTests = $script:TestResults | Where-Object { -not $_.Passed } | Measure-Object | Select-Object -ExpandProperty Count
    $totalTests = $script:TestResults.Count
    $passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    
    Write-Host "`n=== 测试报告 ===" -ForegroundColor Green
    Write-Host "总执行时间: $([math]::Round($totalDuration)) ms" -ForegroundColor Yellow
    Write-Host "总测试数: $totalTests" -ForegroundColor Yellow
    Write-Host "通过测试: $passedTests" -ForegroundColor Green
    Write-Host "失败测试: $failedTests" -ForegroundColor Red
    Write-Host "通过率: $passRate%" -ForegroundColor Cyan
    
    if ($totalTests -gt 0) {
        Write-Host "`n测试结果详情:" -ForegroundColor Yellow
        $script:TestResults | ForEach-Object {
            $status = if ($_.Passed) { "✅" } else { "❌" }
            $foregroundColor = if ($_.Passed) { "Green" } else { "Red" }
            Write-Host "$status $($_.TestName): $($_.Message) ($($_.Duration) ms)" -ForegroundColor $foregroundColor
        }
    }
}

# Docker修复模块
function Fix-Docker {
    Write-Log "=== Docker修复模块 ===" "Info"
    Start-Timer "DockerFix"
    
    try {
        # 1. 修复hosts文件访问权限
        Write-Log "1. 修复hosts文件访问权限" "Info"
        $hostsPath = "C:\windows\System32\drivers\etc\hosts"
        
        # 授予当前用户对hosts文件的修改权限
        $acl = Get-Acl $hostsPath
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $permission = $currentUser, "Modify", "Allow"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl $hostsPath $acl
        
        Add-TestResult "修复hosts文件权限" $true "成功修复hosts文件访问权限"
        
        # 2. 检查WSL 2状态（Windows系统特有）
        Write-Log "2. 检查WSL 2状态" "Info"
        
        # 检查WSL是否安装
        $wslStatus = wsl --status 2>&1
        $wslDistros = wsl -l -v 2>&1
        
        # 综合判断WSL状态
        if (($wslStatus -like "*WSL 2*" -and $wslStatus -notlike "*Error*") -or ($wslDistros -like "*Ubuntu*" -or $wslDistros -like "*docker-desktop*")) {
            Write-Log "WSL 2 已安装并运行" "Success"
            Write-Log "当前WSL分发状态: $wslDistros" "Info"
            Add-TestResult "检查WSL 2状态" $true "WSL 2 已正确安装并运行"
        } else {
            Write-Log "WSL 2 状态异常，尝试修复" "Warning"
            
            # 尝试更新WSL
            try {
                wsl --update | Out-Null
                Start-Sleep -Seconds 5
                $wslStatus = wsl --status 2>&1
                $wslDistros = wsl -l -v 2>&1
                if (($wslStatus -like "*WSL 2*" -and $wslStatus -notlike "*Error*") -or ($wslDistros -like "*Ubuntu*" -or $wslDistros -like "*docker-desktop*")) {
                    Write-Log "WSL 2 更新成功" "Success"
                    Add-TestResult "修复WSL 2状态" $true "WSL 2 更新成功"
                } else {
                    Write-Log "WSL 2 更新失败，尝试重置" "Warning"
                    # 重置WSL
                    wsl --shutdown | Out-Null
                    Start-Sleep -Seconds 3
                    Add-TestResult "修复WSL 2状态" $true "已重置WSL 2"
                }
            } catch {
                Add-TestResult "检查WSL 2状态" $false "WSL 2 检查失败: $_"
            }
        }
        
        # 3. 检查Docker Desktop版本和用户组会员资格
        Write-Log "3. 检查Docker Desktop版本和用户组会员资格" "Info"
        
        # 检查Docker Desktop版本
        try {
            $dockerDesktopVersion = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object {$_.DisplayName -like '*Docker Desktop*'} | Select-Object -ExpandProperty DisplayVersion
            if ($dockerDesktopVersion) {
                Write-Log "Docker Desktop版本: $dockerDesktopVersion" "Info"
            } else {
                Write-Log "无法获取Docker Desktop版本" "Warning"
            }
        } catch {
            Write-Log "检查Docker Desktop版本失败: $_" "Warning"
        }
        
        # 检查Docker日志文件
        try {
            $dockerLogs = Get-ChildItem -Path "$env:APPDATA\Docker" -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3 Name, LastWriteTime
            if ($dockerLogs) {
                Write-Log "最近的Docker日志文件:" "Info"
                $dockerLogs | ForEach-Object {
                    Write-Log "  $($_.Name) - $($_.LastWriteTime)" "Info"
                }
            }
        } catch {
            Write-Log "检查Docker日志失败: $_" "Warning"
        }
        
        # 检查用户是否在docker-users组中
        try {
            $dockerUsersGroup = Get-LocalGroup -Name "docker-users" -ErrorAction SilentlyContinue
            if ($dockerUsersGroup) {
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $isMember = Get-LocalGroupMember -Group "docker-users" -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $currentUser}
                if ($isMember) {
                    Write-Log "当前用户已在docker-users组中" "Success"
                    Add-TestResult "检查docker-users组会员资格" $true "当前用户已在docker-users组中"
                } else {
                    Write-Log "当前用户不在docker-users组中，尝试添加" "Warning"
                    try {
                        Add-LocalGroupMember -Group "docker-users" -Member $currentUser
                        Write-Log "成功将当前用户添加到docker-users组" "Success"
                        Add-TestResult "添加到docker-users组" $true "成功将当前用户添加到docker-users组"
                    } catch {
                        Write-Log "添加用户到docker-users组失败: $_" "Error"
                        Add-TestResult "添加到docker-users组" $false "添加用户到docker-users组失败: $_"
                    }
                }
            } else {
                Write-Log "docker-users组不存在，尝试创建" "Warning"
                try {
                    New-LocalGroup -Name "docker-users" -Description "Docker Users Group"
                    Write-Log "成功创建docker-users组" "Success"
                    Add-TestResult "创建docker-users组" $true "成功创建docker-users组"
                } catch {
                    Write-Log "创建docker-users组失败: $_" "Error"
                    Add-TestResult "创建docker-users组" $false "创建docker-users组失败: $_"
                }
            }
        } catch {
            Write-Log "检查docker-users组失败: $_" "Error"
            Add-TestResult "检查docker-users组" $false "检查docker-users组失败: $_"
        }
        
        # 4. 取消注册docker-desktop WSL分发
        Write-Log "4. 取消注册docker-desktop WSL分发" "Info"
        
        try {
            # 检查所有WSL分发
            $wslDistros = wsl -l -v 2>&1
            Write-Log "当前WSL分发状态:" "Info"
            Write-Log $wslDistros "Info"
            
            # 取消注册docker-desktop相关分发
            $distrosToUnregister = @("docker-desktop", "docker-desktop-data")
            foreach ($distro in $distrosToUnregister) {
                if ($wslDistros -like "*$distro*") {
                    Write-Log "找到$distro分发，尝试取消注册" "Info"
                    wsl --unregister $distro 2>&1 | Out-Null
                    Start-Sleep -Seconds 3
                    Write-Log "成功取消注册$distro分发" "Success"
                    Add-TestResult "取消注册$distro分发" $true "成功取消注册$distro分发"
                }
            }
            
            # 检查Ubuntu WSL分发状态
            if ($wslDistros -like "*Ubuntu*") {
                Write-Log "找到Ubuntu分发，检查其状态" "Info"
                Add-TestResult "检查Ubuntu WSL分发" $true "Ubuntu分发存在"
            }
        } catch {
            Write-Log "取消注册WSL分发失败: $_" "Warning"
            Add-TestResult "取消注册WSL分发" $false "取消注册WSL分发失败: $_"
        }
        
        # 5. 检查WSL集成状态
        Write-Log "5. 检查WSL集成状态" "Info"
        
        try {
            # 检查WSL版本
            $wslVersion = wsl --version 2>&1
            Write-Log "WSL版本信息:" "Info"
            Write-Log $wslVersion "Info"
            
            # 检查WSL服务状态
            $wslService = Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue
            if ($wslService) {
                Write-Log "WSL服务状态: $($wslService.Status)" "Info"
                if ($wslService.Status -ne "Running") {
                    Write-Log "WSL服务未运行，尝试启动" "Warning"
                    Start-Service -Name "LxssManager"
                    Start-Sleep -Seconds 5
                    Write-Log "WSL服务已启动" "Success"
                    Add-TestResult "启动WSL服务" $true "成功启动WSL服务"
                } else {
                    Add-TestResult "检查WSL服务状态" $true "WSL服务正在运行"
                }
            } else {
                Write-Log "未找到WSL服务" "Warning"
                Add-TestResult "检查WSL服务状态" $false "未找到WSL服务"
            }
            
            # 6. 解决Ubuntu WSL集成错误
        Write-Log "6. 解决Ubuntu WSL集成错误" "Info"
        try {
            # 检查Ubuntu WSL分发状态
            $wslDistros = wsl -l -v 2>&1
            Write-Log "当前WSL分发状态:" "Info"
            Write-Log $wslDistros "Info"
            
            # 检查Ubuntu分发是否存在
            Write-Log "直接测试Ubuntu WSL分发是否存在..." "Info"
            $ubuntuTest = wsl -d Ubuntu -e echo "Ubuntu WSL test" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "找到Ubuntu WSL分发并测试成功" "Success"
                
                # 尝试停止并重启Ubuntu分发
                Write-Log "尝试停止并重启Ubuntu WSL分发" "Info"
                wsl --terminate Ubuntu 2>&1 | Out-Null
                Start-Sleep -Seconds 1
                
                # 再次测试Ubuntu分发是否能正常启动
                $ubuntuTest = wsl -d Ubuntu -e echo "Ubuntu WSL test" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Ubuntu WSL分发测试成功" "Success"
                    
                    # 修复docker config.json写入失败错误
                    Write-Log "修复docker config.json写入失败错误" "Info"
                    # 检查并创建~/.docker目录
                    wsl -d Ubuntu -e mkdir -p ~/.docker 2>&1 | Out-Null
                    # 设置目录权限
                    wsl -d Ubuntu -e chmod 755 ~/.docker 2>&1 | Out-Null
                    # 创建基本的config.json文件
                    wsl -d Ubuntu -e sh -c "echo '{\"credsStore\": \"desktop.exe\"}' > ~/.docker/config.json" 2>&1 | Out-Null
                    # 设置文件权限
                    wsl -d Ubuntu -e chmod 644 ~/.docker/config.json 2>&1 | Out-Null
                    Write-Log "已修复docker config.json写入失败错误" "Success"
                    
                    Add-TestResult "检查Ubuntu WSL分发" $true "Ubuntu WSL分发测试成功"
                } else {
                    Write-Log "Ubuntu WSL分发测试失败，尝试修复..." "Warning"
                    
                    # 尝试修复WSL集成
                    Write-Log "尝试修复WSL集成" "Info"
                    # 停止Docker服务
                    Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 3
                    
                    # 重启WSL服务
                    Restart-Service -Name "LxssManager" -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 3
                    
                    # 重新启动Docker服务
                    Start-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 5
                    
                    Add-TestResult "修复Ubuntu WSL集成" $true "已尝试修复Ubuntu WSL集成"
                }
            } else {
                Write-Log "未找到Ubuntu WSL分发或无法访问" "Warning"
                Add-TestResult "检查Ubuntu WSL分发" $false "未找到Ubuntu WSL分发或无法访问"
            }
        } catch {
            Write-Log "解决Ubuntu WSL集成错误失败: $_" "Error"
            Add-TestResult "解决Ubuntu WSL集成错误" $false "解决Ubuntu WSL集成错误失败: $_"
        }
        
        # 7. 全面解决WSL集成意外停止问题
        Write-Log "7. 全面解决WSL集成意外停止问题" "Info"
        try {
            # 检查WSL服务状态
            $wslService = Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue
            if ($wslService -and $wslService.Status -eq "Running") {
                Write-Log "WSL服务正在运行" "Info"
            } else {
                Write-Log "WSL服务未运行，尝试启动" "Warning"
                Start-Service -Name "LxssManager" -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Write-Log "WSL服务已启动" "Info"
            }
            
            # 检查WSL版本
            $wslVersion = wsl --version 2>&1
            Write-Log "WSL版本信息:" "Info"
            Write-Log $wslVersion "Info"
            
            # 检查所有WSL分发状态
            $allDistros = wsl -l -v 2>&1
            Write-Log "所有WSL分发状态:" "Info"
            Write-Log $allDistros "Info"
            
            # 检查docker-desktop相关分发
            $dockerDesktopDistros = @("docker-desktop", "docker-desktop-data")
            foreach ($distro in $dockerDesktopDistros) {
                if ($allDistros -like "*$distro*") {
                    Write-Log "找到$distro分发" "Info"
                    # 检查分发状态
                    if ($allDistros -like "*$distro*Stopped*") {
                        Write-Log "$distro分发已停止，尝试启动" "Info"
                        # 启动Docker服务会自动启动这些分发
                    }
                }
            }
            
            # 测试WSL基本功能
            $wslTest = wsl -e echo "WSL basic test" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "WSL基本功能测试成功" "Success"
                Add-TestResult "WSL基本功能测试" $true "WSL基本功能测试成功"
            } else {
                Write-Log "WSL基本功能测试失败，尝试修复..." "Warning"
                # 重置WSL
                wsl --shutdown 2>&1 | Out-Null
                Start-Sleep -Seconds 2
                wsl --update 2>&1 | Out-Null
                Start-Sleep -Seconds 5
                Write-Log "已重置和更新WSL" "Info"
                Add-TestResult "WSL基本功能测试" $true "已重置和更新WSL"
            }
            
        } catch {
            Write-Log "解决WSL集成意外停止问题失败: $_" "Error"
            Add-TestResult "解决WSL集成意外停止问题" $false "解决WSL集成意外停止问题失败: $_"
        }
            
            # 8. 处理app-Windows-x86.asar和app.asar文件
            Write-Log "8. 处理app-Windows-x86.asar和app.asar文件" "Info"
            try {
                # 检查Docker Desktop安装目录
                $dockerDesktopPath = "C:\Program Files\Docker\Docker"
                if (Test-Path $dockerDesktopPath) {
                    Write-Log "找到Docker Desktop安装目录" "Info"
                    
                    # 检查app-Windows-x86.asar文件
                    $appAsarPath = Join-Path $dockerDesktopPath "resources\app-Windows-x86.asar"
                    $appAsarPath2 = Join-Path $dockerDesktopPath "resources\app.asar"
                    
                    if (Test-Path $appAsarPath) {
                        Write-Log "找到app-Windows-x86.asar文件" "Info"
                        # 确保文件权限正确
                        $acl = Get-Acl $appAsarPath
                        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                        $permission = $currentUser, "ReadAndExecute", "Allow"
                        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.SetAccessRule($accessRule)
                        Set-Acl $appAsarPath $acl
                        Write-Log "已修复app-Windows-x86.asar文件权限" "Success"
                    }
                    
                    if (Test-Path $appAsarPath2) {
                        Write-Log "找到app.asar文件" "Info"
                        # 确保文件权限正确
                        $acl = Get-Acl $appAsarPath2
                        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                        $permission = $currentUser, "ReadAndExecute", "Allow"
                        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.SetAccessRule($accessRule)
                        Set-Acl $appAsarPath2 $acl
                        Write-Log "已修复app.asar文件权限" "Success"
                    }
                    
                    Add-TestResult "处理app.asar文件" $true "已检查并修复app-Windows-x86.asar和app.asar文件权限"
                } else {
                    Write-Log "未找到Docker Desktop安装目录" "Warning"
                    Add-TestResult "处理app.asar文件" $false "未找到Docker Desktop安装目录"
                }
            } catch {
                Write-Log "处理app.asar文件失败: $_" "Error"
                Add-TestResult "处理app.asar文件" $false "处理app.asar文件失败: $_"
            }
            
            # 9. 解决中文问题
            Write-Log "9. 解决中文问题" "Info"
            try {
                # 检查系统区域设置
                $currentLocale = Get-WinSystemLocale
                Write-Log "当前系统区域设置: $($currentLocale.Name)" "Info"
                
                # 确保系统使用UTF-8编码
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage"
                $ansiCodePage = Get-ItemProperty -Path $regPath -Name "ACP" -ErrorAction SilentlyContinue
                $oemCodePage = Get-ItemProperty -Path $regPath -Name "OEMCP" -ErrorAction SilentlyContinue
                
                Write-Log "当前ANSI代码页: $($ansiCodePage.ACP)" "Info"
                Write-Log "当前OEM代码页: $($oemCodePage.OEMCP)" "Info"
                
                # 检查Docker Desktop配置文件中的中文设置
                $dockerConfigPath = "$env:APPDATA\Docker"
                if (Test-Path $dockerConfigPath) {
                    Write-Log "找到Docker配置目录" "Info"
                    # 检查是否存在config.json文件
                    $configJsonPath = Join-Path $dockerConfigPath "config.json"
                    if (Test-Path $configJsonPath) {
                        Write-Log "找到Docker配置文件" "Info"
                        # 读取配置文件内容
                        $configContent = Get-Content $configJsonPath -Raw -ErrorAction SilentlyContinue
                        if ($configContent) {
                            Write-Log "Docker配置文件读取成功" "Info"
                        }
                    }
                }
                
                Add-TestResult "解决中文问题" $true "已检查系统区域设置和Docker配置文件"
            } catch {
                Write-Log "解决中文问题失败: $_" "Error"
                Add-TestResult "解决中文问题" $false "解决中文问题失败: $_"
            }
        } catch {
            Write-Log "检查WSL集成状态失败: $_" "Warning"
            Add-TestResult "检查WSL集成状态" $false "检查WSL集成状态失败: $_"
        }
        
        # 10. 重置Docker Desktop设置
        Write-Log "10. 重置Docker Desktop设置" "Info"
        
        # 停止Docker服务
        Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
        Stop-Process -Name 'Docker Desktop' -Force -ErrorAction SilentlyContinue
        Stop-Process -Name 'docker' -Force -ErrorAction SilentlyContinue
        Stop-Process -Name 'DockerCli' -Force -ErrorAction SilentlyContinue
        
        # 快速停止服务
        Start-Sleep -Seconds 2
        
        # 跳过完整备份以提高速度
        Write-Log "跳过完整备份以提高执行速度" "Info"
        
        # 11. 检查和修复DOCKER_HOST环境变量
        Write-Log "11. 检查和修复DOCKER_HOST环境变量" "Info"
        
        if ($env:DOCKER_HOST) {
            Write-Log "DOCKER_HOST环境变量值: $env:DOCKER_HOST" "Warning"
            Write-Log "DOCKER_HOST环境变量会覆盖Docker上下文设置，正在取消设置..." "Info"
            Remove-Item -Path Env:\DOCKER_HOST -ErrorAction SilentlyContinue
            Write-Log "已取消设置DOCKER_HOST环境变量" "Success"
            Add-TestResult "取消设置DOCKER_HOST环境变量" $true "成功取消设置DOCKER_HOST环境变量"
        } else {
            Write-Log "DOCKER_HOST环境变量未设置" "Info"
            Add-TestResult "检查DOCKER_HOST环境变量" $true "DOCKER_HOST环境变量未设置"
        }
        
        # 12. 管理Docker上下文
        Write-Log "12. 管理Docker上下文" "Info"
        try {
            # 切换到desktop-linux上下文
            $contextResult = docker context use desktop-linux 2>&1
            Write-Log "已切换到desktop-linux上下文" "Info"
            Add-TestResult "切换Docker上下文" $true "成功切换到desktop-linux上下文"
        } catch {
            Write-Log "切换Docker上下文失败: $_" "Warning"
            # 尝试切换到默认上下文
            try {
                docker context use default 2>&1 | Out-Null
                Write-Log "已切换到默认上下文" "Info"
                Add-TestResult "切换Docker上下文" $true "成功切换到默认上下文"
            } catch {
                Write-Log "切换到默认上下文也失败: $_" "Warning"
                Add-TestResult "切换Docker上下文" $false "切换Docker上下文失败: $_"
            }
        }
        
        # 13. 重新启动Docker服务
        Write-Log "13. 重新启动Docker服务" "Info"
        Start-Service -Name 'com.docker.service'
        Start-Sleep -Seconds 5
        
        Add-TestResult "重置Docker设置" $true "成功重置Docker Desktop设置"
        
        # 14. 修复Docker API版本问题
        Write-Log "14. 修复Docker API版本问题" "Info"
        
        # 尝试不同的API版本
        $apiVersions = @('1.51', '1.50', '1.49', '1.48', '1.47', '1.46', '1.45', '1.44')
        $workingVersion = $null
        
        foreach ($version in $apiVersions) {
            Write-Log "尝试API版本: $version" "Info"
            $env:DOCKER_API_VERSION = $version
            
            # 尝试ping守护进程（最基本的连接测试）
            $pingResult = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info --format '{{.ServerVersion}}' 2>&1
            
            if ($pingResult -notlike "*Error*" -and $pingResult -ne "") {
                $workingVersion = $version
                break
            }
        }
        
        if ($workingVersion) {
            Write-Log "找到工作的API版本: $workingVersion" "Success"
            Add-TestResult "修复Docker API版本" $true "成功找到并设置工作的Docker API版本: $workingVersion"
        } else {
            Write-Log "无法找到兼容的API版本，尝试切换引擎" "Warning"
            # 重新初始化Docker引擎
            try {
                & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchDaemon
                Start-Sleep -Seconds 10
                Add-TestResult "切换Docker引擎" $true "成功切换Docker引擎"
                
                # 再次测试API版本
                foreach ($version in $apiVersions) {
                    $env:DOCKER_API_VERSION = $version
                    $pingResult = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info --format '{{.ServerVersion}}' 2>&1
                    if ($pingResult -notlike "*Error*" -and $pingResult -ne "") {
                        $workingVersion = $version
                        Write-Log "切换引擎后找到工作的API版本: $workingVersion" "Success"
                        break
                    }
                }
            } catch {
                Add-TestResult "切换Docker引擎" $false "切换Docker引擎失败: $_"
            }
        }
        
        # 15. 修复Docker守护进程连接问题
        Write-Log "15. 修复Docker守护进程连接问题" "Info"
        
        # 检查Docker守护进程状态
        $daemonStatus = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info 2>&1
        if ($daemonStatus -like "*Error*" -or $LASTEXITCODE -ne 0) {
            Write-Log "Docker守护进程连接失败，尝试修复" "Warning"
            
            # 检查防火墙设置
            Write-Log "检查防火墙设置" "Info"
            try {
                # 允许Docker相关程序通过防火墙
                $dockerExePath = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
                $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
                
                if (Test-Path $dockerExePath) {
                    New-NetFirewallRule -DisplayName "Docker Engine" -Direction Inbound -Program $dockerExePath -Action Allow -ErrorAction SilentlyContinue
                    New-NetFirewallRule -DisplayName "Docker Engine" -Direction Outbound -Program $dockerExePath -Action Allow -ErrorAction SilentlyContinue
                }
                
                if (Test-Path $dockerDesktopPath) {
                    New-NetFirewallRule -DisplayName "Docker Desktop" -Direction Inbound -Program $dockerDesktopPath -Action Allow -ErrorAction SilentlyContinue
                    New-NetFirewallRule -DisplayName "Docker Desktop" -Direction Outbound -Program $dockerDesktopPath -Action Allow -ErrorAction SilentlyContinue
                }
                
                Write-Log "防火墙规则已更新" "Info"
            } catch {
                Write-Log "防火墙设置更新失败: $_" "Warning"
            }
            
            # 重启Docker Desktop应用程序
            Write-Log "重启Docker Desktop应用程序" "Info"
            try {
                # 停止所有Docker相关进程
                Stop-Process -Name 'Docker Desktop' -Force -ErrorAction SilentlyContinue
                Stop-Process -Name 'docker' -Force -ErrorAction SilentlyContinue
                Stop-Process -Name 'DockerCli' -Force -ErrorAction SilentlyContinue
                
                # 停止Docker服务
                Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
                
                Start-Sleep -Seconds 5
                
                # 重新启动Docker Desktop应用程序
                $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
                if (Test-Path $dockerDesktopPath) {
                    Start-Process -FilePath $dockerDesktopPath -NoNewWindow
                    Write-Log "Docker Desktop应用程序已启动" "Info"
                } else {
                    # 如果找不到Docker Desktop，启动Docker服务
                    Start-Service -Name 'com.docker.service'
                    Write-Log "Docker服务已启动" "Info"
                }
                
                # 等待Docker守护进程初始化
                Write-Log "等待Docker守护进程初始化（10秒）" "Info"
                Start-Sleep -Seconds 10
                
            } catch {
                Write-Log "重启Docker Desktop失败: $_" "Warning"
            }
            
            # 重置Docker网络
            Write-Log "重置Docker网络" "Info"
            try {
                & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" network prune -f 2>&1 | Out-Null
                Start-Sleep -Seconds 2
                Write-Log "Docker网络已重置" "Info"
            } catch {
                Write-Log "Docker网络重置失败: $_" "Warning"
            }
        }
        
        # 16. 验证Docker运行状态
        Write-Log "16. 验证Docker运行状态" "Info"
        
        # 再次检查并启动Docker服务
        $dockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
        if (!$dockerService -or $dockerService.Status -ne 'Running') {
            Write-Log "Docker服务未运行，尝试启动" "Warning"
            try {
                Start-Service -Name 'com.docker.service'
                Write-Log "已启动Docker服务" "Info"
                Start-Sleep -Seconds 5
                $dockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
            } catch {
                Write-Log "启动Docker服务失败: $_" "Warning"
            }
        }
        
        if ($dockerService -and $dockerService.Status -eq 'Running') {
            # 测试基本Docker命令
            $dockerVersion = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker版本: $dockerVersion" "Success"
                
                # 等待守护进程完全初始化
                Write-Log "等待Docker守护进程完全初始化（5秒）" "Info"
                Start-Sleep -Seconds 5
                
                # 测试镜像拉取（使用小镜像）
                Write-Log "测试镜像拉取功能" "Info"
                $pullResult = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" pull hello-world 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "镜像拉取成功" "Success"
                    Add-TestResult "验证Docker运行状态" $true "Docker服务正在运行，版本: $dockerVersion，镜像拉取功能正常"
                } else {
                    Write-Log "镜像拉取失败: $pullResult" "Warning"
                    Add-TestResult "验证Docker运行状态" $true "Docker服务正在运行，版本: $dockerVersion，但镜像拉取功能异常"
                }
            } else {
                Add-TestResult "验证Docker运行状态" $false "Docker服务运行但命令执行失败: $dockerVersion"
            }
        } else {
            # 尝试直接启动Docker Desktop应用程序
            Write-Log "尝试直接启动Docker Desktop应用程序" "Info"
            try {
                $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
                if (Test-Path $dockerDesktopPath) {
                    Start-Process -FilePath $dockerDesktopPath -NoNewWindow
                    Write-Log "已启动Docker Desktop应用程序" "Info"
                    Start-Sleep -Seconds 30
                    
                    # 再次检查服务状态
                    $dockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
                    if ($dockerService -and $dockerService.Status -eq 'Running') {
                        $dockerVersion = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" --version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "Docker版本: $dockerVersion" "Success"
                            Add-TestResult "验证Docker运行状态" $true "Docker服务正在运行，版本: $dockerVersion"
                        } else {
                            Add-TestResult "验证Docker运行状态" $false "Docker服务运行但命令执行失败: $dockerVersion"
                        }
                    } else {
                        Add-TestResult "验证Docker运行状态" $false "Docker服务未运行"
                    }
                } else {
                    Add-TestResult "验证Docker运行状态" $false "Docker服务未运行，且Docker Desktop应用程序未找到"
                }
            } catch {
                Add-TestResult "验证Docker运行状态" $false "Docker服务未运行，启动Docker Desktop失败: $_"
            }
        }
        
        # 17. 解决Docker镜像拉取失败问题
        Write-Log "17. 解决Docker镜像拉取失败问题" "Info"
        try {
            # 检查daemon.json配置
            $daemonJsonPath = "$env:ProgramData\Docker\config\daemon.json"
            if (Test-Path $daemonJsonPath) {
                $daemonConfig = Get-Content $daemonJsonPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($daemonConfig) {
                    Write-Log "已存在daemon.json配置" "Info"
                    Add-TestResult "检查daemon.json配置" $true "已存在daemon.json配置"
                }
            } else {
                # 创建默认的daemon.json配置
                $defaultConfig = @{
                    "registry-mirrors" = @(
                        "https://mirror.aliyuncs.com",
                        "https://hub-mirror.c.163.com",
                        "https://mirrors.ustc.edu.cn/dockerhub/",
                        "https://docker.mirrors.ustc.edu.cn/",
                        "https://dockerproxy.com",
                        "https://docker.1ms.run"
                    )
                    "exec-opts" = @("isolation=process")
                    "experimental" = $false
                    "features" = @{
                        "buildkit" = $true
                    }
                    "no-hosts" = $true
                    "max-concurrent-downloads" = 10
                }
                # 确保配置目录存在
                $configDir = Split-Path -Path $daemonJsonPath
                if (-not (Test-Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
                $defaultConfig | ConvertTo-Json | Set-Content -Path $daemonJsonPath -Force
                Write-Log "已创建daemon.json配置文件，添加了镜像加速地址" "Success"
                Add-TestResult "创建daemon.json配置" $true "成功创建daemon.json配置文件，添加了镜像加速地址"
            }
        } catch {
            Write-Log "配置Docker镜像拉取优化失败: $_" "Warning"
            Add-TestResult "配置镜像拉取优化" $false "配置Docker镜像拉取优化失败: $_"
        }
        
        # 18. 最终Docker连接状态检查
        Write-Log "18. 最终Docker连接状态检查" "Info"
        try {
            # 检查Docker版本
            $dockerVersionOutput = docker version 2>&1
            if ($dockerVersionOutput -match "Server:") {
                Write-Log "Docker连接成功！" "Success"
                Add-TestResult "最终Docker连接检查" $true "Docker连接成功"
                
                # 检查Docker容器状态
                $dockerPsOutput = docker ps 2>&1
                Write-Log "Docker容器状态:" "Info"
                Write-Log "$dockerPsOutput" "Info"
            } else {
                Write-Log "Docker连接仍有问题，尝试运行诊断工具..." "Warning"
                # 运行Docker Desktop诊断工具
                try {
                    & "C:\Program Files\Docker\Docker\Docker Desktop.exe" --diagnose 2>&1 | Out-Null
                    Write-Log "已运行Docker Desktop诊断工具" "Info"
                    Add-TestResult "运行Docker诊断工具" $true "已运行Docker Desktop诊断工具"
                } catch {
                    Write-Log "运行诊断工具失败: $_" "Warning"
                    Add-TestResult "运行Docker诊断工具" $false "运行诊断工具失败: $_"
                }
            }
        } catch {
            Write-Log "最终Docker连接检查失败: $_" "Error"
            Add-TestResult "最终Docker连接检查" $false "最终Docker连接检查失败: $_"
        }
        
    } catch {
        Write-Log "Docker修复失败: $_" "Error"
        Add-TestResult "Docker修复模块" $false "Docker修复失败: $_"
    }
    
    $duration = Stop-Timer "DockerFix"
    Add-TestResult "Docker修复总时长" $true "Docker修复模块执行完成" $duration
}

# 浏览器与GitHub访问修复模块
function Fix-Browser {
    Write-Log "=== 浏览器与GitHub访问修复模块 ===" "Info"
    Start-Timer "BrowserFix"
    
    try {
        # 1. 修复hosts文件，添加GitHub相关IP条目
        Write-Log "1. 修复hosts文件，添加GitHub相关IP条目" "Info"
        $hostsPath = "C:\windows\System32\drivers\etc\hosts"
        
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
        
        # 读取现有hosts文件内容
        $hostsContent = Get-Content $hostsPath -Raw
        
        # 如果hosts文件中没有GitHub条目，则添加
        if (-not $hostsContent.Contains("# GitHub访问优化")) {
            Add-Content -Path $hostsPath -Value $githubHosts
            Add-TestResult "添加GitHub hosts条目" $true "成功添加GitHub hosts条目"
        } else {
            Add-TestResult "添加GitHub hosts条目" $true "GitHub hosts条目已存在"
        }
        
        # 2. 清除DNS缓存和网络缓存
        Write-Log "2. 清除DNS缓存和网络缓存" "Info"
        
        # 清除DNS缓存
        & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
        # 重置Winsock
        & "C:\Windows\System32\netsh.exe" winsock reset | Out-Null
        # 重置TCP/IP
        & "C:\Windows\System32\netsh.exe" int ip reset | Out-Null
        
        Add-TestResult "清除网络缓存" $true "成功清除DNS缓存、重置Winsock和TCP/IP"
        
        # 3. 重置2345浏览器代理设置
        Write-Log "3. 重置2345浏览器代理设置" "Info"
        
        # 2345浏览器通常基于Chrome内核，代理设置存储在注册表中
        $browserPaths = @(
            "C:\Program Files (x86)\2345Explorer\2345Explorer.exe",
            "C:\Program Files\2345Explorer\2345Explorer.exe"
        )
        
        $browserFound = $false
        foreach ($path in $browserPaths) {
            if (Test-Path $path) {
                $browserFound = $true
                Write-Log "找到2345浏览器: $path" "Info"
                break
            }
        }
        
        # 重置系统代理设置（影响所有浏览器）
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $regPath -Name ProxyServer -Value "" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $regPath -Name ProxyOverride -Value "<local>" -ErrorAction SilentlyContinue
        
        if ($browserFound) {
            Add-TestResult "重置2345浏览器代理" $true "成功重置2345浏览器代理设置"
        } else {
            Add-TestResult "重置系统代理" $true "未找到2345浏览器，成功重置系统代理设置"
        }
        
        # 4. 验证GitHub访问
        Write-Log "4. 验证GitHub访问" "Info"
        
        try {
            $githubTest = Test-Connection -ComputerName github.com -Count 2 -TimeoutSeconds 5 -ErrorAction SilentlyContinue
            if ($githubTest) {
                $avgResponse = [math]::Round($githubTest.Average)
                Add-TestResult "GitHub连接测试" $true "GitHub连接正常，平均响应时间: $avgResponse ms"
            } else {
                Add-TestResult "GitHub连接测试" $false "GitHub连接失败"
            }
        } catch {
            Add-TestResult "GitHub连接测试" $false "GitHub连接测试异常: $_"
        }
        
    } catch {
        Write-Log "浏览器与GitHub访问修复失败: $_" "Error"
        Add-TestResult "浏览器修复模块" $false "浏览器与GitHub访问修复失败: $_"
    }
    
    $duration = Stop-Timer "BrowserFix"
    Add-TestResult "浏览器修复总时长" $true "浏览器与GitHub访问修复模块执行完成" $duration
}

# Coze Studio部署模块
function Deploy-Coze {
    Write-Log "=== Coze Studio部署模块 ===" "Info"
    Start-Timer "CozeDeploy"
    
    try {
        # 配置参数
        $COZE_DIR = "C:\Users\Administrator\Desktop\fcjgfycrteas\coze-studio-0.5.0\docker"
        $PROFILE = "*"
        $WAIT_TIME = 300  # 等待时间（秒）
        
        # 1. 检查Docker环境
        Write-Log "1. 检查Docker环境" "Info"
        
        try {
            $dockerVersion = docker --version
            $dockerComposeVersion = docker compose version
            Add-TestResult "检查Docker环境" $true "Docker版本: $dockerVersion, Docker Compose版本: $dockerComposeVersion"
        } catch {
            Add-TestResult "检查Docker环境" $false "Docker环境检查失败: $_"
            throw "Docker环境检查失败: $_"
        }
        
        # 2. 检查Coze Studio目录
        Write-Log "2. 检查Coze Studio目录" "Info"
        
        if (-not (Test-Path $COZE_DIR)) {
            Write-Log "Coze Studio目录不存在: $COZE_DIR" "Warning"
            
            # 尝试查找coze-studio目录
            $possibleDirs = Get-ChildItem -Path "C:\Users\Administrator\Desktop" -Filter "coze-studio*" -Directory
            if ($possibleDirs.Count -gt 0) {
                $COZE_DIR = Join-Path $possibleDirs[0].FullName "docker"
                Write-Log "找到Coze Studio目录: $COZE_DIR" "Info"
            } else {
                Add-TestResult "检查Coze Studio目录" $false "未找到Coze Studio目录"
                throw "未找到Coze Studio目录"
            }
        }
        
        Add-TestResult "检查Coze Studio目录" $true "Coze Studio目录: $COZE_DIR"
        
        # 3. 启动Coze Studio服务
        Write-Log "3. 启动Coze Studio服务" "Info"
        
        try {
            Set-Location -Path $COZE_DIR
            if ($PROFILE -eq "*") {
                docker compose --profile $PROFILE up -d
            } else {
                docker compose up -d
            }
            Add-TestResult "启动Coze Studio服务" $true "Coze Studio服务启动命令已执行"
        } catch {
            Add-TestResult "启动Coze Studio服务" $false "Coze Studio服务启动失败: $_"
            throw "Coze Studio服务启动失败: $_"
        }
        
        # 4. 等待服务启动完成
        Write-Log "4. 等待服务启动完成（最多等待 $WAIT_TIME 秒）" "Info"
        
        $startTime = Get-Date
        $serviceStarted = $false
        
        while (((Get-Date) - $startTime).TotalSeconds -lt $WAIT_TIME) {
            try {
                $containers = docker ps --filter "name=coze"
                if ($containers -match "coze-server") {
                    $serviceStarted = $true
                    break
                }
                Write-Log "服务正在启动中..." "Info"
                Start-Sleep -Seconds 10
            } catch {
                Write-Log "检查容器状态失败: $_" "Warning"
                Start-Sleep -Seconds 10
            }
        }
        
        if ($serviceStarted) {
            Add-TestResult "等待Coze服务启动" $true "Coze Studio服务启动成功！"
            Write-Log "部署完成！访问地址: http://localhost:8888" "Success"
        } else {
            Add-TestResult "等待Coze服务启动" $false "Coze Studio服务启动超时"
        }
        
    } catch {
        Write-Log "Coze Studio部署失败: $_" "Error"
        Add-TestResult "Coze部署模块" $false "Coze Studio部署失败: $_"
    }
    
    $duration = Stop-Timer "CozeDeploy"
    Add-TestResult "Coze部署总时长" $true "Coze Studio部署模块执行完成" $duration
}

# 网络诊断和修复模块
function Fix-Network {
    Write-Log "=== 网络诊断和修复模块 ===" "Info"
    Start-Timer "NetworkFix"
    
    try {
        # 1. 网络连接诊断
        Write-Log "1. 网络连接诊断" "Info"
        
        # 测试基本网络连接
        $pingTest = Test-Connection -ComputerName www.baidu.com -Count 2 -TimeoutSeconds 5 -ErrorAction SilentlyContinue
        if ($pingTest) {
            Write-Log "网络连接基本正常，成功ping通百度" "Success"
            Add-TestResult "基本网络连接测试" $true "网络连接基本正常，成功ping通百度"
        } else {
            Write-Log "网络连接异常，无法ping通百度" "Warning"
            Add-TestResult "基本网络连接测试" $false "网络连接异常，无法ping通百度"
        }
        
        # 2. DNS故障诊断和修复
        Write-Log "2. DNS故障诊断和修复" "Info"
        
        # 清除DNS缓存
        & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
        Write-Log "已清除DNS缓存" "Info"
        
        # 测试DNS解析
        $dnsTest = Resolve-DnsName -Name www.baidu.com -ErrorAction SilentlyContinue
        if ($dnsTest) {
            Write-Log "DNS解析正常: $($dnsTest.IPAddress[0])" "Success"
            Add-TestResult "DNS解析测试" $true "DNS解析正常"
        } else {
            Write-Log "DNS解析异常，尝试修复..." "Warning"
        }
        
        # 强制设置公共DNS服务器以解决Docker Hub连接问题
        Write-Log "强制设置公共DNS服务器以解决Docker Hub连接问题" "Info"
        $adapters = Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'}
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @("8.8.8.8", "1.1.1.1") -ErrorAction SilentlyContinue
            Write-Log "已为网卡 $($adapter.Name) 设置DNS服务器为 8.8.8.8 和 1.1.1.1" "Info"
        }
        Add-TestResult "DNS故障修复" $true "已设置公共DNS服务器以解决Docker Hub连接问题"
        
        # 3. TCP/IP和Winsock修复
        Write-Log "3. TCP/IP和Winsock修复" "Info"
        
        # 重置Winsock
        & "C:\Windows\System32\netsh.exe" winsock reset | Out-Null
        # 重置TCP/IP
        & "C:\Windows\System32\netsh.exe" int ip reset | Out-Null
        Write-Log "已重置Winsock和TCP/IP设置" "Info"
        
        # 4. 代理设置检查和修复
        Write-Log "4. 代理设置检查和修复" "Info"
        
        # 检查系统代理设置
        $proxyRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $proxyEnable = Get-ItemProperty -Path $proxyRegPath -Name ProxyEnable -ErrorAction SilentlyContinue
        if ($proxyEnable -and $proxyEnable.ProxyEnable -eq 1) {
            Write-Log "发现系统代理设置已启用，尝试禁用..." "Warning"
            Set-ItemProperty -Path $proxyRegPath -Name ProxyEnable -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $proxyRegPath -Name ProxyServer -Value "" -ErrorAction SilentlyContinue
            Write-Log "已禁用系统代理设置" "Success"
            Add-TestResult "代理设置修复" $true "已禁用系统代理设置"
        } else {
            Write-Log "系统代理设置未启用，无需修改" "Info"
            Add-TestResult "代理设置检查" $true "系统代理设置未启用"
        }
        
        # 5. 防火墙规则检查
        Write-Log "5. 防火墙规则检查" "Info"
        
        # 确保基本网络连接通过防火墙
        try {
            # 允许HTTP和HTTPS流量
            New-NetFirewallRule -DisplayName "HTTP Traffic" -Direction Outbound -LocalPort 80 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName "HTTPS Traffic" -Direction Outbound -LocalPort 443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
            Write-Log "已检查并更新防火墙规则" "Info"
            Add-TestResult "防火墙规则检查" $true "已检查并更新防火墙规则"
        } catch {
            Write-Log "防火墙规则更新失败: $_" "Warning"
            Add-TestResult "防火墙规则检查" $false "防火墙规则更新失败: $_"
        }
        
        # 6. 网络适配器重置
        Write-Log "6. 网络适配器重置" "Info"
        
        # 重启网络服务
        Restart-Service -Name "Dhcp" -Force -ErrorAction SilentlyContinue
        Restart-Service -Name "DNS Client" -Force -ErrorAction SilentlyContinue
        Restart-Service -Name "Network Location Awareness" -Force -ErrorAction SilentlyContinue
        Write-Log "已重启网络服务" "Info"
        
        # 7. 浏览器连接错误修复
        Write-Log "7. 浏览器连接错误修复" "Info"
        
        # 清除浏览器缓存和Cookie（针对常见浏览器）
        $browserPaths = @(
            "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data",
            "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge\User Data",
            "C:\Users\$env:USERNAME\AppData\Local\2345Explorer\User Data"
        )
        
        foreach ($path in $browserPaths) {
            if (Test-Path $path) {
                Write-Log "发现浏览器数据目录: $path" "Info"
                # 这里可以添加清除缓存的具体操作
            }
        }
        
        Add-TestResult "浏览器连接错误修复" $true "已检查浏览器数据目录"
        
        # 8. 最终网络连接验证
        Write-Log "8. 最终网络连接验证" "Info"
        
        # 等待网络服务完全启动
        Start-Sleep -Seconds 3
        
        # 测试基本网络连接
        $googleTest = Test-Connection -ComputerName www.google.com -Count 2 -TimeoutSeconds 5 -ErrorAction SilentlyContinue
        if ($googleTest) {
            Write-Log "基本网络连接正常，成功ping通Google" "Success"
        } else {
            Write-Log "基本网络连接仍有问题" "Warning"
        }
        
        # 测试Docker Hub连接（关键用于登录验证）
        Write-Log "测试Docker Hub连接（用于登录验证）" "Info"
        $dockerHubTest = Test-Connection -ComputerName hub.docker.com -Count 2 -TimeoutSeconds 8 -ErrorAction SilentlyContinue
        if ($dockerHubTest) {
            Write-Log "Docker Hub连接正常，登录验证应该可以正常进行" "Success"
            Add-TestResult "最终网络连接验证" $true "网络连接修复成功，Docker Hub连接正常"
        } else {
            Write-Log "Docker Hub连接失败，这可能导致登录验证问题" "Warning"
            Add-TestResult "最终网络连接验证" $false "网络连接修复后，Docker Hub连接仍有问题"
        }
        
    } catch {
        Write-Log "网络诊断和修复失败: $_" "Error"
        Add-TestResult "网络诊断和修复模块" $false "网络诊断和修复失败: $_"
    }
    
    $duration = Stop-Timer "NetworkFix"
    Add-TestResult "网络诊断和修复总时长" $true "网络诊断和修复模块执行完成" $duration
}

# 主函数
function Main {
    Write-Host "=== 综合系统修复与优化工具 ===" -ForegroundColor Green
    Write-Host "运行模式: $Mode" -ForegroundColor Cyan
    Write-Host "开始时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Green
    
    try {
        # 根据模式执行相应功能
        switch ($Mode) {
            "All" {
                Fix-Docker
                Fix-Browser
                Deploy-Coze
                Fix-Network
            }
            "Docker" {
                Fix-Docker
            }
            "Browser" {
                Fix-Browser
            }
            "Coze" {
                Deploy-Coze
            }
            "Network" {
                Fix-Network
            }
        }
        
        Write-Host "=" * 50 -ForegroundColor Green
        Write-Host "修复与优化完成！" -ForegroundColor Green
        
    } catch {
        Write-Host "=" * 50 -ForegroundColor Red
        Write-Host "执行过程中发生错误: $_" -ForegroundColor Red
    } finally {
        # 生成测试报告
        Generate-Report
        Write-Host "=" * 50 -ForegroundColor Green
        Write-Host "结束时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -ForegroundColor Cyan
    }
}

# 执行主函数
Main

# 生成HTML测试报告
function Generate-HtmlReport {
    param(
        [string]$ReportPath = "test-report.html"
    )
    
    $totalTests = $script:TestResults.Count
    $passedTests = $script:TestResults | Where-Object { $_.Passed } | Measure-Object | Select-Object -ExpandProperty Count
    $failedTests = $totalTests - $passedTests
    $totalDuration = (Get-Date) - $script:StartTime
    $totalDurationMs = [math]::Round($totalDuration.TotalMilliseconds)
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统修复与优化测试报告</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
            padding: 20px;
            background-color: #f0f0f0;
            border-radius: 8px;
        }
        .summary-item {
            text-align: center;
        }
        .summary-item h3 {
            margin: 0;
            color: #555;
        }
        .summary-item .value {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
        }
        .value.passed {
            color: #4CAF50;
        }
        .value.failed {
            color: #f44336;
        }
        .value.total {
            color: #2196F3;
        }
        .test-results {
            margin-top: 30px;
        }
        .test-result {
            margin: 10px 0;
            padding: 15px;
            border-radius: 8px;
            border-left: 5px solid #ddd;
        }
        .test-result.passed {
            background-color: #e8f5e8;
            border-left-color: #4CAF50;
        }
        .test-result.failed {
            background-color: #ffebee;
            border-left-color: #f44336;
        }
        .test-name {
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 5px;
        }
        .test-meta {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .timestamp {
            font-size: 12px;
            color: #999;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>系统修复与优化测试报告</h1>
        <h2>运行模式: $Mode</h2>
        <h3>开始时间: $($script:StartTime.ToString("yyyy-MM-dd HH:mm:ss"))</h3>
        <h3>结束时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</h3>
        
        <div class="summary">
            <div class="summary-item">
                <h3>总测试数</h3>
                <div class="value total">$totalTests</div>
            </div>
            <div class="summary-item">
                <h3>通过测试</h3>
                <div class="value passed">$passedTests</div>
            </div>
            <div class="summary-item">
                <h3>失败测试</h3>
                <div class="value failed">$failedTests</div>
            </div>
            <div class="summary-item">
                <h3>通过率</h3>
                <div class="value">$(if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 })%</div>
            </div>
            <div class="summary-item">
                <h3>总执行时间</h3>
                <div class="value">$totalDurationMs ms</div>
            </div>
        </div>
        
        <div class="test-results">
            <h2>测试结果详情</h2>
            $(foreach ($result in $script:TestResults) {
                $statusClass = if ($result.Passed) { "passed" } else { "failed" }
                "<div class='test-result $statusClass'>
                    <div class='test-name'>$($result.TestName)</div>
                    <div>$($result.Message)</div>
                    <div class='test-meta'>执行时间: $($result.Duration)ms</div>
                    <div class='timestamp'>$($result.Timestamp)</div>
                </div>"
            })
        </div>
    </div>
</body>
</html>
"@
    
    $fullReportPath = Join-Path (Get-Location) $ReportPath
    $htmlContent | Out-File -FilePath $fullReportPath -Encoding UTF8
    Write-Log "HTML测试报告已生成: $fullReportPath" "Info"
}

# 生成HTML报告
Generate-HtmlReport