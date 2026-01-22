<#
WSL错误修复脚本

此脚本专门用于解决以下错误：
DockerDesktop/Wsl/ExecError: c:\windows\system32\wsl.exe --unmount docker_data.vhdx: exit status 0xffffffff

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
$logFile = "$PSScriptRoot\wsl_fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# 步骤1：停止所有WSL相关服务和进程
function Stop-WSLServices {
    Write-Host "`n=== 步骤1：停止所有WSL相关服务和进程 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始停止WSL相关服务和进程" "Info"
    
    try {
        # 停止Docker服务
        Write-Log "停止Docker服务" "Info"
        Stop-Service -Name 'com.docker.service' -Force -ErrorAction SilentlyContinue
        
        # 停止Docker进程
        Write-Log "停止Docker进程" "Info"
        Get-Process -Name *docker* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 停止WSL进程
        Write-Log "停止WSL进程" "Info"
        Get-Process -Name *wsl* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 执行wsl --shutdown
        Write-Log "执行wsl --shutdown" "Info"
        wsl --shutdown
        
        Write-Log "WSL相关服务和进程已成功停止" "Success"
    } catch {
        Write-Log "停止WSL相关服务和进程失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤2：清理WSL分发版
function Cleanup-WSLDistros {
    Write-Host "`n=== 步骤2：清理WSL分发版 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始清理WSL分发版" "Info"
    
    try {
        # 列出当前WSL分发版
        Write-Log "列出当前WSL分发版" "Info"
        $distros = wsl -l -v 2>&1
        Write-Log "当前WSL分发版: $distros" "Info"
        Write-Host $distros -ForegroundColor $COLOR_INFO
        
        # 注销Docker相关的WSL分发版
        Write-Log "注销Docker相关的WSL分发版" "Info"
        wsl --unregister docker-desktop 2>$null
        wsl --shutdown
        Start-Sleep -Seconds 5
        wsl --unregister docker-desktop-data 2>$null
        wsl --shutdown
        Start-Sleep -Seconds 5
        
        # 再次列出WSL分发版
        $distrosAfter = wsl -l -v 2>&1
        Write-Log "清理后WSL分发版: $distrosAfter" "Info"
        Write-Host $distrosAfter -ForegroundColor $COLOR_INFO
        
        Write-Log "WSL分发版清理完成" "Success"
    } catch {
        Write-Log "清理WSL分发版失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤3：清理Docker配置和数据
function Cleanup-DockerData {
    Write-Host "`n=== 步骤3：清理Docker配置和数据 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始清理Docker配置和数据" "Info"
    
    try {
        # 清理Docker程序数据
        Write-Log "清理Docker程序数据" "Info"
        $dockerProgramData = "$env:ProgramData\Docker"
        if (Test-Path $dockerProgramData) {
            Remove-Item -Path $dockerProgramData -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Docker程序数据清理成功" "Success"
        } else {
            Write-Log "Docker程序数据不存在，跳过清理" "Info"
        }
        
        # 清理用户Docker配置
        Write-Log "清理用户Docker配置" "Info"
        $dockerUserConfig = "$env:USERPROFILE\.docker"
        if (Test-Path $dockerUserConfig) {
            Remove-Item -Path $dockerUserConfig -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "用户Docker配置清理成功" "Success"
        } else {
            Write-Log "用户Docker配置不存在，跳过清理" "Info"
        }
        
        # 清理WSL Docker数据文件
        Write-Log "清理WSL Docker数据文件" "Info"
        $wslDataPath = "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState"
        if (Test-Path $wslDataPath) {
            # 只清理Docker相关的文件，不删除整个WSL数据
            Get-ChildItem -Path $wslDataPath -Recurse -Include "*docker*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "WSL Docker数据文件清理成功" "Success"
        } else {
            Write-Log "WSL数据目录不存在，跳过清理" "Info"
        }
        
        Write-Log "Docker配置和数据清理完成" "Success"
    } catch {
        Write-Log "清理Docker配置和数据失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤4：重置WSL网络和服务
function Reset-WSLNetwork {
    Write-Host "`n=== 步骤4：重置WSL网络和服务 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始重置WSL网络和服务" "Info"
    
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
        
        # 重启WSL服务
        Write-Log "重启WSL服务" "Info"
        Get-Service -Name 'LxssManager' -ErrorAction SilentlyContinue | Restart-Service -Force -ErrorAction SilentlyContinue
        Get-Service -Name 'WslService' -ErrorAction SilentlyContinue | Restart-Service -Force -ErrorAction SilentlyContinue
        Write-Log "WSL服务重启成功" "Success"
        
        Write-Log "WSL网络和服务重置完成" "Success"
    } catch {
        Write-Log "重置WSL网络和服务失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤5：修复系统文件和权限
function Repair-SystemFiles {
    Write-Host "`n=== 步骤5：修复系统文件和权限 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始修复系统文件和权限" "Info"
    
    try {
        # 检查系统文件完整性
        Write-Log "检查系统文件完整性" "Info"
        Write-Host "正在检查系统文件完整性，这可能需要一些时间..." -ForegroundColor $COLOR_INFO
        sfc /scannow | Out-File -FilePath "$env:TEMP\sfc_scan.log" -Encoding UTF8
        Write-Log "系统文件完整性检查完成" "Success"
        
        # 修复WSL执行权限
        Write-Log "修复WSL执行权限" "Info"
        $wslPath = "$env:SystemRoot\System32\wsl.exe"
        if (Test-Path $wslPath) {
            # 获取当前权限
            $acl = Get-Acl $wslPath
            # 添加执行权限
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ExecuteFile", "Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $wslPath $acl
            Write-Log "WSL执行权限修复成功" "Success"
        } else {
            Write-Log "WSL可执行文件不存在，跳过权限修复" "Warning"
        }
        
        # 修复Docker执行权限
        Write-Log "修复Docker执行权限" "Info"
        $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            # 获取当前权限
            $acl = Get-Acl $dockerPath
            # 添加执行权限
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ExecuteFile", "Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $dockerPath $acl
            Write-Log "Docker执行权限修复成功" "Success"
        } else {
            Write-Log "Docker可执行文件不存在，跳过权限修复" "Warning"
        }
        
        Write-Log "系统文件和权限修复完成" "Success"
    } catch {
        Write-Log "修复系统文件和权限失败: $($_.Exception.Message)" "Error"
    }
    
    Start-Sleep -Seconds 10
}

# 步骤6：重新启动系统
function Restart-System {
    Write-Host "`n=== 步骤6：重新启动系统 ===" -ForegroundColor $COLOR_TITLE
    Write-Log "开始重新启动系统" "Info"
    
    try {
        Write-Host "所有修复步骤已执行完成，需要重启系统以应用更改" -ForegroundColor $COLOR_WARNING
        Write-Host "系统将在30秒后重启，请保存所有工作..." -ForegroundColor $COLOR_WARNING
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
    } catch {
        Write-Log "重启系统失败: $($_.Exception.Message)" "Error"
        Write-Host "请手动重启计算机以应用更改" -ForegroundColor $COLOR_WARNING
    }
}

# 主函数
function Main {
    # 检查管理员权限
    Check-Admin
    
    # 显示欢迎信息
    Write-Host "`n=== WSL错误修复脚本 ===" -ForegroundColor $COLOR_TITLE
    Write-Host "版本: 1.0"
    Write-Host "用途: 解决DockerDesktop/Wsl/ExecError错误"
    Write-Host "日志文件: $logFile"
    Write-Host "`n错误信息: DockerDesktop/Wsl/ExecError: c:\windows\system32\wsl.exe --unmount docker_data.vhdx: exit status 0xffffffff"
    Write-Host "`n注意：此脚本会执行系统级操作，请确保您了解其影响" -ForegroundColor $COLOR_WARNING
    Write-Host "按任意键开始执行，或按Ctrl+C取消..." -ForegroundColor $COLOR_MENU
    
    # 等待用户输入
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # 执行修复步骤
    Stop-WSLServices
    Cleanup-WSLDistros
    Cleanup-DockerData
    Reset-WSLNetwork
    Repair-SystemFiles
    Restart-System
    
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
