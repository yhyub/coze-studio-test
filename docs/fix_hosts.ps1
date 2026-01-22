# GitHub访问修复脚本 - 修复hosts文件中的重复条目
# 以管理员身份运行此脚本

Write-Host "正在修复Windows hosts文件中的GitHub重复条目..."

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$tempPath = "$env:TEMP\hosts.tmp"

# 读取当前hosts文件内容
$hostsContent = Get-Content -Path $hostsPath -Raw

# 移除重复的github.com条目
$fixedContent = $hostsContent -replace '20\.205\.243\.166\s+github\.com', ''
# 添加单个正确的github.com条目
$fixedContent = $fixedContent + "`n# GitHub entry for reliable access`n20.205.243.166 github.com"

# 写入临时文件
Set-Content -Path $tempPath -Value $fixedContent

# 复制到系统hosts文件（需要管理员权限）
Copy-Item -Path $tempPath -Destination $hostsPath -Force

Write-Host "hosts文件修复完成！"
Write-Host "正在刷新DNS缓存..."
Clear-DnsClientCache
Write-Host "DNS缓存刷新完成！"

# 重启2345浏览器
Write-Host "正在重启2345浏览器..."
Stop-Process -Name "2345Explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
# 这里假设2345浏览器的路径是默认安装路径
& "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe" -url "https://github.com/yhyub/fsegrdtfghvjbn/actions/new?category=continuous-integration"

# 添加防火墙出站允许规则
Write-Host "正在为2345浏览器添加防火墙出站允许规则..."
$browserPath = "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"
if (Test-Path $browserPath) {
    # 检查规则是否已存在
    $ruleExists = Get-NetFirewallApplicationFilter -Program $browserPath -ErrorAction SilentlyContinue
    if (-not $ruleExists) {
        # 创建出站允许规则
        New-NetFirewallRule -DisplayName "Allow 2345 Explorer Outbound" -Direction Outbound -Program $browserPath -Action Allow -Protocol TCP -RemotePort 80,443
        Write-Host "防火墙规则创建成功！"
    } else {
        Write-Host "防火墙规则已存在，跳过创建。"
    }
} else {
    Write-Host "警告：未找到2345浏览器默认安装路径，请手动检查安装位置。"
}

Write-Host "所有修复操作完成！请检查2345浏览器是否能正常访问GitHub Actions页面。"