# GitHub访问测试脚本
Write-Host "=== GitHub访问测试 ==="

# 测试基本网络连接
Write-Host "\n1. 测试GitHub基本网络连接："
Test-Connection -ComputerName github.com -Count 2

# 测试DNS解析
Write-Host "\n2. 测试GitHub DNS解析："
Resolve-DnsName github.com | Select-Object Name, IP4Address

# 测试HTTP访问（使用PowerShell的Invoke-WebRequest）
Write-Host "\n3. 测试GitHub HTTP访问："
try {
    $response = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ HTTP访问成功！状态码：" $response.StatusCode
} catch {
    Write-Host "✗ HTTP访问失败：" $_.Exception.Message
}
<#
GitHub网络访问修复脚本
此脚本用于解决GitHub访问超时(ERR_CONNECTION_TIMED_OUT)问题
包含持久化的网络配置优化
#>

param(
    [switch]$TestOnly = $false
)

Write-Host "GitHub网络访问修复脚本 v1.0" -ForegroundColor Green
Write-Host "=" * 50

# 1. 检查当前网络状态
Write-Host "\n1. 检查网络连接状态..." -ForegroundColor Cyan
Get-NetAdapter | Select-Object Name, Status, LinkSpeed | Format-Table

# 2. 测试GitHub连接
Write-Host "\n2. 测试GitHub连接..." -ForegroundColor Cyan
$tcpTest = Test-NetConnection -ComputerName github.com -Port 443 -InformationLevel Detailed
$tcpTest | Select-Object ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded

if ($TestOnly) {
    Write-Host "\n测试模式完成，未进行任何配置更改。" -ForegroundColor Yellow
    return
}

# 3. 优化DNS设置
Write-Host "\n3. 优化DNS设置..." -ForegroundColor Cyan
$dnsServers = @("1.1.1.1", "8.8.8.8", "9.9.9.9", "114.114.114.114")
Set-DnsClientServerAddress -InterfaceAlias "WLAN" -ServerAddresses $dnsServers -ErrorAction SilentlyContinue
Get-DnsClientServerAddress -InterfaceAlias "WLAN" -AddressFamily IPv4 | Select-Object ServerAddresses

# 4. 清除DNS缓存
Write-Host "\n4. 清除DNS缓存..." -ForegroundColor Cyan
Clear-DnsClientCache

# 5. 配置防火墙规则
Write-Host "\n5. 配置防火墙规则..." -ForegroundColor Cyan

# GitHub IP地址列表（持续更新）
$githubIPs = @("20.205.243.166", "20.205.243.175", "140.82.112.4", "140.82.113.4")

# 允许GitHub HTTPS访问
if (-not (Get-NetFirewallRule -DisplayName "Allow GitHub HTTPS" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow GitHub HTTPS" -Direction Outbound -LocalPort 443 -Protocol TCP -RemoteAddress $githubIPs -Action Allow -Enabled True
    Write-Host "已创建GitHub HTTPS防火墙规则" -ForegroundColor Green
} else {
    Write-Host "GitHub HTTPS防火墙规则已存在" -ForegroundColor Yellow
}

# 允许GitHub HTTP访问
if (-not (Get-NetFirewallRule -DisplayName "Allow GitHub HTTP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow GitHub HTTP" -Direction Outbound -LocalPort 80 -Protocol TCP -RemoteAddress $githubIPs -Action Allow -Enabled True
    Write-Host "已创建GitHub HTTP防火墙规则" -ForegroundColor Green
} else {
    Write-Host "GitHub HTTP防火墙规则已存在" -ForegroundColor Yellow
}

# 6. 优化Windows网络参数
Write-Host "\n6. 优化Windows网络参数..." -ForegroundColor Cyan

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

# 优化TCP窗口大小
Set-ItemProperty -Path $regPath -Name "TcpWindowSize" -Value 65536 -Type DWord -ErrorAction SilentlyContinue

# 减少TIME_WAIT延迟
Set-ItemProperty -Path $regPath -Name "TcpTimedWaitDelay" -Value 30 -Type DWord -ErrorAction SilentlyContinue

# 增加重传次数
Set-ItemProperty -Path $regPath -Name "TcpMaxDataRetransmissions" -Value 10 -Type DWord -ErrorAction SilentlyContinue

# 增加最大连接数
Set-ItemProperty -Path $regPath -Name "TcpNumConnections" -Value 16777214 -Type DWord -ErrorAction SilentlyContinue

# 优化ACK频率
Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value 2 -Type DWord -ErrorAction SilentlyContinue

Write-Host "网络参数优化完成" -ForegroundColor Green

# 7. 配置SSL/TLS协议
Write-Host "\n7. 配置SSL/TLS协议..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
Write-Host "已启用TLS 1.2和TLS 13协议" -ForegroundColor Green

# 8. 验证修复效果
Write-Host "\n8. 验证修复效果..." -ForegroundColor Cyan

# 测试DNS解析
Write-Host "\n测试DNS解析："
Measure-Command { Resolve-DnsName -Name github.com -Server "1.1.1.1" } | Select-Object TotalMilliseconds

# 测试TCP连接
Write-Host "\n测试TCP连接："
Test-NetConnection -ComputerName github.com -Port 443 | Select-Object TcpTestSucceeded

# 测试HTTPS访问
Write-Host "\n测试HTTPS访问："
try {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    $client.DefaultRequestHeaders.UserAgent.TryParseAdd('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
    
    $response = $client.GetAsync('https://github.com/marketplace?type=apps').Result
    Write-Host "GitHub Marketplace访问状态: $($response.StatusCode)" -ForegroundColor Green
    
    $client.Dispose()
} catch {
    Write-Host "GitHub访问错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "\n" -ForegroundColor Green
Write-Host "=" * 50
Write-Host "修复完成！" -ForegroundColor Green
Write-Host "建议：重启电脑以确保所有网络参数生效" -ForegroundColor Yellow
Write-Host "可以使用 -TestOnly 参数运行脚本进行测试" -ForegroundColor Yellow

# 测试目标页面访问
Write-Host "\n4. 测试目标GitHub Actions页面访问："
try {
    $targetUrl = "https://github.com/yhyub/fsegrdtfghvjbn/actions/new?category=continuous-integration"
    $response = Invoke-WebRequest -Uri $targetUrl -UseBasicParsing -TimeoutSec 15
    Write-Host "✓ 目标页面访问成功！状态码：" $response.StatusCode
    Write-Host "建议：以管理员身份运行 fix_hosts.ps1 脚本完成最终修复。"
} catch {
    Write-Host "✗ 目标页面访问失败：" $_.Exception.Message
    Write-Host "请以管理员身份运行 fix_hosts.ps1 脚本进行修复。"
}

Write-Host "\n=== 测试完成 ==="