<#
.SYNOPSIS
GitHub连接修复工具 - 自动修复hosts文件，解决ERR_CONNECTION_TIMED_OUT问题

.DESCRIPTION
此脚本会自动修复Windows系统的hosts文件，添加GitHub相关的IP地址，解决GitHub连接超时问题。

.EXAMPLE
.ix_github_hosts.ps1

.NOTES
需要以管理员身份运行此脚本
#>

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "需要以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "请右键点击脚本，选择'以管理员身份运行'"
    Read-Host -Prompt "按任意键退出"
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

Write-Log "=== GitHub连接修复工具 ===" "Info"

# GitHub相关IP地址映射
$githubHosts = @(
    "# GitHub访问优化（修复连接超时问题）",
    "140.82.114.3 github.com",
    "140.82.114.4 gist.github.com",
    "185.199.108.153 assets-cdn.github.com",
    "185.199.109.153 assets-cdn.github.com",
    "185.199.110.153 assets-cdn.github.com",
    "185.199.111.153 assets-cdn.github.com",
    "199.232.69.194 github.global.ssl.fastly.net",
    "140.82.114.9 codeload.github.com",
    "140.82.114.10 api.github.com",
    "185.199.111.133 raw.githubusercontent.com",
    "185.199.110.133 raw.githubusercontent.com",
    "185.199.109.133 raw.githubusercontent.com",
    "185.199.108.133 raw.githubusercontent.com",
    "140.82.112.18 graphql.github.com",
    "192.30.255.112 github.com",
    "140.82.113.4 github.com"
)

# hosts文件路径
$hostsPath = "C:\windows\System32\drivers\etc\hosts"

# 备份hosts文件
$backupPath = "$hostsPath.$(Get-Date -Format 'yyyyMMddHHmmss').bak"
Write-Log "备份hosts文件到: $backupPath" "Info"
try {
    Copy-Item -Path $hostsPath -Destination $backupPath -Force
    Write-Log "hosts文件备份成功" "Success"
} catch {
    Write-Log "hosts文件备份失败: $_" "Error"
    Read-Host -Prompt "按任意键退出"
    Exit 1
}

# 读取现有hosts文件内容
Write-Log "读取现有hosts文件内容" "Info"
try {
    $hostsContent = Get-Content $hostsPath -Raw
} catch {
    Write-Log "读取hosts文件失败: $_" "Error"
    Read-Host -Prompt "按任意键退出"
    Exit 1
}

# 检查是否已包含GitHub相关条目
Write-Log "检查hosts文件中是否已包含GitHub相关条目" "Info"
$hasGitHubEntries = $hostsContent.Contains("# GitHub访问优化")

if ($hasGitHubEntries) {
    Write-Log "检测到已有GitHub相关条目，将替换为最新内容" "Warning"
    
    # 删除旧的GitHub条目
    $lines = Get-Content $hostsPath
    $newLines = @()
    $inGithubSection = $false
    
    foreach ($line in $lines) {
        if ($line -like "# GitHub访问优化*") {
            $inGithubSection = $true
            continue
        }
        
        if ($inGithubSection) {
            if ($line -match "^\s*$") {
                $inGithubSection = $false
            } else {
                continue
            }
        }
        
        $newLines += $line
    }
    
    $hostsContent = $newLines -join "`r`n"
    $hostsContent += "`r`n`r`n"
} else {
    Write-Log "未检测到GitHub相关条目，将添加新内容" "Info"
    $hostsContent += "`r`n`r`n"
}

# 添加新的GitHub条目
Write-Log "添加新的GitHub IP映射条目" "Info"
try {
    $hostsContent += $githubHosts -join "`r`n"
    Set-Content -Path $hostsPath -Value $hostsContent -Force
    Write-Log "GitHub IP映射条目添加成功" "Success"
} catch {
    Write-Log "添加GitHub IP映射条目失败: $_" "Error"
    Read-Host -Prompt "按任意键退出"
    Exit 1
}

# 清除DNS缓存
Write-Log "清除DNS缓存" "Info"
try {
    & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
    Write-Log "DNS缓存清除成功" "Success"
} catch {
    Write-Log "DNS缓存清除失败: $_" "Warning"
}

# 重置Winsock
Write-Log "重置Winsock"
try {
    & "C:\Windows\System32\netsh.exe" winsock reset | Out-Null
    Write-Log "Winsock重置成功" "Success"
} catch {
    Write-Log "Winsock重置失败: $_" "Warning"
}

# 重置TCP/IP
Write-Log "重置TCP/IP"
try {
    & "C:\Windows\System32\netsh.exe" int ip reset | Out-Null
    Write-Log "TCP/IP重置成功" "Success"
} catch {
    Write-Log "TCP/IP重置失败: $_" "Warning"
}

# 测试GitHub连接
Write-Log "测试GitHub连接" "Info"
try {
    $githubTest = Test-Connection -ComputerName github.com -Count 2 -TimeoutSeconds 5 -ErrorAction SilentlyContinue
    if ($githubTest) {
        $avgResponse = [math]::Round($githubTest.Average)
        Write-Log "GitHub连接测试成功，平均响应时间: $avgResponse ms" "Success"
    } else {
        Write-Log "GitHub连接测试失败，可能需要重启网络或计算机" "Warning"
        Write-Log "请尝试重启网络适配器或计算机后再次测试" "Warning"
    }
} catch {
    Write-Log "GitHub连接测试异常: $_" "Error"
}

Write-Log "=== GitHub连接修复完成 ===" "Info"
Write-Log "修复内容：" "Info"
Write-Log "1. 备份了原始hosts文件到: $backupPath" "Info"
Write-Log "2. 添加了14个GitHub相关IP映射条目" "Info"
Write-Log "3. 清除了DNS缓存" "Info"
Write-Log "4. 重置了Winsock和TCP/IP" "Info"
Write-Log "5. 测试了GitHub连接" "Info"

Write-Log "" "Info"
Write-Log "建议：" "Info"
Write-Log "1. 重启浏览器以应用新的DNS设置" "Info"
Write-Log "2. 如果问题仍然存在，请重启计算机" "Info"
Write-Log "3. 结合浏览器插件使用，效果更佳" "Info"

Read-Host -Prompt "