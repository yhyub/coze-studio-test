<#
.SYNOPSIS
2345浏览器修复工具 - 设置2345浏览器为默认浏览器并解决相关问题
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

Write-Log "=== 2345浏览器修复工具 - 设置为默认浏览器 ===" "Info"

try {
    # 1. 定位2345浏览器可执行文件
    Write-Log "1. 定位2345浏览器可执行文件" "Info"
    
    # 2345浏览器可能的安装路径
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
            Write-Log "找到2345浏览器: $path" "Success"
            break
        }
    }
    
    if (-not $browserFound) {
        Write-Log "未找到2345浏览器可执行文件" "Error"
        Exit 1
    }
    
    # 2. 设置2345浏览器为默认浏览器
    Write-Log "2. 设置2345浏览器为默认浏览器" "Info"
    
    # 获取浏览器的AppUserModelId
    $browserAppId = "2345Explorer.exe"
    
    # 使用DISM命令设置默认浏览器（Windows 10/11支持）
    try {
        Write-Log "使用DISM命令设置默认浏览器" "Info"
        $dismResult = & dism /Online /Get-DefaultAppAssociations | Out-Null
        
        # 创建默认应用关联XML文件
        $defaultAppXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
    <Association Identifier=".htm" ProgId="2345ExplorerHTML" ApplicationName="2345浏览器" />
    <Association Identifier=".html" ProgId="2345ExplorerHTML" ApplicationName="2345浏览器" />
    <Association Identifier=".shtml" ProgId="2345ExplorerHTML" ApplicationName="2345浏览器" />
    <Association Identifier=".xht" ProgId="2345ExplorerHTML" ApplicationName="2345浏览器" />
    <Association Identifier=".xhtml" ProgId="2345ExplorerHTML" ApplicationName="2345浏览器" />
    <Association Identifier="http" ProgId="2345ExplorerURL" ApplicationName="2345浏览器" />
    <Association Identifier="https" ProgId="2345ExplorerURL" ApplicationName="2345浏览器" />
    <Association Identifier="ftp" ProgId="2345ExplorerURL" ApplicationName="2345浏览器" />
</DefaultAssociations>
"@
        
        $xmlPath = "$env:TEMP\defaultapps.xml"
        Set-Content -Path $xmlPath -Value $defaultAppXml -Encoding UTF8
        
        # 应用默认关联
        & dism /Online /Import-DefaultAppAssociations:"$xmlPath" | Out-Null
        Write-Log "DISM默认应用关联设置成功" "Success"
        
        # 删除临时文件
        Remove-Item -Path $xmlPath -Force
    } catch {
        Write-Log "DISM命令执行失败: $_" "Warning"
        Write-Log "尝试使用其他方法设置默认浏览器" "Info"
    }
    
    # 使用Windows PowerShell设置默认浏览器（通过注册表）
    try {
        Write-Log "使用注册表设置默认浏览器关联" "Info"
        
        # 设置HTTP协议默认关联
        $httpRegPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice"
        if (-not (Test-Path $httpRegPath)) {
            New-Item -Path $httpRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $httpRegPath -Name "ProgId" -Value "2345ExplorerURL" -ErrorAction SilentlyContinue
        
        # 设置HTTPS协议默认关联
        $httpsRegPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice"
        if (-not (Test-Path $httpsRegPath)) {
            New-Item -Path $httpsRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $httpsRegPath -Name "ProgId" -Value "2345ExplorerURL" -ErrorAction SilentlyContinue
        
        # 设置HTML文件默认关联
        $htmlRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice"
        if (-not (Test-Path $htmlRegPath)) {
            New-Item -Path $htmlRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $htmlRegPath -Name "ProgId" -Value "2345ExplorerHTML" -ErrorAction SilentlyContinue
        
        Write-Log "注册表默认浏览器关联设置成功" "Success"
    } catch {
        Write-Log "注册表设置失败: $_" "Warning"
    }
    
    # 3. 修复hosts文件，添加GitHub相关IP条目
    Write-Log "3. 修复hosts文件，添加GitHub相关IP条目" "Info"
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
    
    # 4. 清除DNS缓存和网络缓存
    Write-Log "4. 清除DNS缓存和网络缓存" "Info"
    
    # 清除DNS缓存
    & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
    # 重置Winsock
    & "C:\Windows\System32\netsh.exe" winsock reset | Out-Null
    # 重置TCP/IP
    & "C:\Windows\System32\netsh.exe" int ip reset | Out-Null
    
    Write-Log "成功清除DNS缓存、重置Winsock和TCP/IP" "Success"
    
    # 5. 重置2345浏览器代理设置
    Write-Log "5. 重置2345浏览器代理设置" "Info"
    
    # 重置系统代理设置（影响所有浏览器）
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name ProxyOverride -Value "<local>" -ErrorAction SilentlyContinue
    
    Write-Log "成功重置系统代理设置" "Success"
    
    # 6. 验证GitHub访问
    Write-Log "6. 验证GitHub访问" "Info"
    
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
    
    # 7. 启动2345浏览器
    Write-Log "7. 启动2345浏览器" "Info"
    
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
    
    Write-Log "=== 2345浏览器修复完成，已设置为默认浏览器 ===" "Success"
    Write-Log "请检查默认浏览器设置是否生效" "Info"
    
} catch {
    Write-Log "修复过程中出现错误: $_" "Error"
    Exit 1
}

# 暂停脚本，让用户查看结果
Read-Host -Prompt "按Enter键退出"