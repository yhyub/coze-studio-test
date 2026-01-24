<#
.SYNOPSIS
2345浏览器修复工具 - 解决浏览器打开和GitHub访问问题
#>

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "需要以管理员身份运行此脚本！" -ForegroundColor Red
    Exit 1
}

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

Write-Log "=== 2345浏览器修复工具 ===" "Info"

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
        Write-Log "成功添加GitHub hosts条目" "Success"
    } else {
        Write-Log "GitHub hosts条目已存在" "Info"
    }
    
    # 2. 清除DNS缓存和网络缓存
    Write-Log "2. 清除DNS缓存和网络缓存" "Info"
    
    # 清除DNS缓存
    & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
    # 重置Winsock
    & "C:\Windows\System32\netsh.exe" winsock reset | Out-Null
    # 重置TCP/IP
    & "C:\Windows\System32\netsh.exe" int ip reset | Out-Null
    
    Write-Log "成功清除DNS缓存、重置Winsock和TCP/IP" "Success"
    
    # 3. 重置2345浏览器代理设置
    Write-Log "3. 重置2345浏览器代理设置" "Info"
    
    # 2345浏览器路径
    $browserPaths = @(
        "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe",
        "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"
    )
    
    $browserFound = $false
    $browserPath = ""
    foreach ($path in $browserPaths) {
        if (Test-Path $path) {
            $browserFound = $true
            $browserPath = $path
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
        Write-Log "成功重置2345浏览器代理设置" "Success"
    } else {
        Write-Log "未找到2345浏览器，成功重置系统代理设置" "Info"
    }
    
    # 4. 验证GitHub访问
    Write-Log "4. 验证GitHub访问" "Info"
    
    try {
        $githubTest = Test-Connection -ComputerName github.com -Count 2 -TimeoutSeconds 5 -ErrorAction SilentlyContinue
        if ($githubTest) {
            $avgResponse = [math]::Round($githubTest.Average)
            Write-Log "GitHub连接正常，平均响应时间: $avgResponse ms" "Success"
        } else {
            Write-Log "GitHub连接失败" "Warning"
        }
    } catch {
        Write-Log "GitHub连接测试异常: $_" "Error"
    }
    
    # 5. 尝试启动2345浏览器
    Write-Log "5. 尝试启动2345浏览器" "Info"
    
    if ($browserFound) {
        try {
            # 先停止所有2345浏览器进程
            Get-Process -Name "*2345Explorer*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            # 启动浏览器
            Start-Process -FilePath $browserPath -NoNewWindow
            Write-Log "2345浏览器已启动" "Success"
        } catch {
            Write-Log "启动2345浏览器失败: $_" "Error"
        }
    } else {
        Write-Log "未找到2345浏览器可执行文件" "Warning"
    }
    
    Write-Log "=== 2345浏览器修复完成 ===" "Info"
    
} catch {
    Write-Log "修复过程中出现错误: $_" "Error"
    Exit 1
}