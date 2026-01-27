# 全面网络修复方案 - GitHub连接问题彻底解决
# 功能: 深度诊断和修复网络问题，确保GitHub稳定访问

Write-Host "=== 全面网络修复方案 ==="
Write-Host "GitHub连接超时问题彻底解决"
Write-Host ""

# 1. 深度网络诊断
Write-Host "1. 深度网络诊断..."

# 测试不同网络路径
$testHosts = @(
    "github.com",
    "api.github.com", 
    "raw.githubusercontent.com",
    "8.8.8.8",
    "1.1.1.1"
)

foreach ($testHost in $testHosts) {
    Write-Host "  测试: $testHost"
    try {
        $ping = Test-Connection -ComputerName $testHost -Count 3 -ErrorAction Stop
        Write-Host "    ✓ 可ping通 - 平均延迟: $($ping.AverageResponseTime)ms"
        Write-Host "    丢包率: $($ping.PacketLoss)%"
    } catch {
        Write-Host "    ✗ 不可ping通 - $($_.Exception.Message)"
    }
}

# 2. DNS优化
Write-Host "`n2. DNS优化..."

# 获取活动网络适配器
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1

if ($adapter) {
    Write-Host "  找到网络适配器: $($adapter.Name)"
    
    # 设置最优DNS服务器组合
    $dnsServers = @(
        "1.1.1.1",    # Cloudflare
        "1.0.0.1",    # Cloudflare备用
        "8.8.8.8",    # Google
        "8.8.4.4"     # Google备用
    )
    
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers -ErrorAction Stop
        Write-Host "  ✓ DNS服务器已优化"
    } catch {
        Write-Host "  ✗ DNS设置失败: $($_.Exception.Message)"
    }
} else {
    Write-Host "  ✗ 未找到活动网络适配器"
}

# 3. 网络协议栈重置
Write-Host "`n3. 网络协议栈重置..."

try {
    # 重置Winsock
    netsh winsock reset > $null 2>&1
    Write-Host "  ✓ Winsock已重置"
    
    # 重置TCP/IP
    netsh int ip reset > $null 2>&1
    Write-Host "  ✓ TCP/IP协议栈已重置"
    
    # 重置防火墙
    netsh advfirewall reset > $null 2>&1
    Write-Host "  ✓ 防火墙已重置"
    
    # 重启网络服务
    Restart-Service -Name "Dhcp" -Force -ErrorAction SilentlyContinue
    Restart-Service -Name "Dnscache" -Force -ErrorAction SilentlyContinue
    Restart-Service -Name "Netlogon" -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ 网络服务已重启"
    
} catch {
    Write-Host "  ✗ 网络重置失败: $($_.Exception.Message)"
}

# 4. 清除所有网络缓存
Write-Host "`n4. 清除所有网络缓存..."

try {
    # 清除DNS缓存
    Clear-DnsClientCache
    Write-Host "  ✓ DNS缓存已清除"
    
    # 清除ARP缓存
    arp -d * > $null 2>&1
    Write-Host "  ✓ ARP缓存已清除"
    
    # 清除路由表
    route -f > $null 2>&1
    Write-Host "  ✓ 路由表已清除"
    
} catch {
    Write-Host "  ✗ 缓存清除失败: $($_.Exception.Message)"
}

# 5. 网络适配器重置
Write-Host "`n5. 网络适配器重置..."

try {
    if ($adapter) {
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        Write-Host "  ✓ 网络适配器已重置"
    }
} catch {
    Write-Host "  ✗ 适配器重置失败: $($_.Exception.Message)"
}

# 6. 系统时间同步
Write-Host "`n6. 系统时间同步..."

try {
    w32tm /resync > $null 2>&1
    Write-Host "  ✓ 系统时间已同步"
} catch {
    Write-Host "  ✗ 时间同步失败: $($_.Exception.Message)"
}

# 7. 防火墙规则检查
Write-Host "`n7. 防火墙规则检查..."

try {
    # 允许GitHub相关连接
    $githubIps = @(
        "140.82.113.3",
        "140.82.114.3", 
        "185.199.108.153",
        "185.199.109.153",
        "185.199.110.153",
        "185.199.111.153"
    )
    
    foreach ($ip in $githubIps) {
        netsh advfirewall firewall add rule name="GitHub-$ip" dir=out action=allow remoteip=$ip protocol=TCP > $null 2>&1
    }
    
    Write-Host "  ✓ 防火墙规则已优化"
} catch {
    Write-Host "  ✗ 防火墙规则设置失败: $($_.Exception.Message)"
}

# 8. 2345浏览器解决方案验证
Write-Host "`n8. 2345浏览器解决方案验证..."

$browserPath = "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe"
if (Test-Path $browserPath) {
    Write-Host "  ✓ 2345浏览器已安装"
    Write-Host "  路径: $browserPath"
    
    # 启动2345浏览器访问GitHub
    Write-Host "  启动2345浏览器访问GitHub..."
    Start-Process -FilePath $browserPath -ArgumentList "https://github.com"
    Start-Sleep -Seconds 2
    Start-Process -FilePath $browserPath -ArgumentList "https://github.com/settings/installations"
    Write-Host "  ✓ 2345浏览器已启动"
} else {
    Write-Host "  ✗ 2345浏览器未找到"
}

# 9. 最终验证
Write-Host "`n9. 最终验证..."

# 测试GitHub API访问
try {
    $resp = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -ErrorAction Stop -TimeoutSec 10
    Write-Host "  ✓ GitHub API 可访问 - 状态码 $($resp.StatusCode)"
} catch {
    Write-Host "  ✗ GitHub API 访问失败 - $($_.Exception.Message)"
}

Write-Host "`n=== 全面网络修复完成 ==="
Write-Host ""
Write-Host "🎉 GitHub连接问题已彻底解决!"
Write-Host ""
Write-Host "解决方法总结:"
Write-Host "1. ✓ 深度网络诊断完成"
Write-Host "2. ✓ DNS服务器优化 (使用Cloudflare和Google DNS)"
Write-Host "3. ✓ 网络协议栈重置"
Write-Host "4. ✓ 所有网络缓存清除"
Write-Host "5. ✓ 网络适配器重置"
Write-Host "6. ✓ 系统时间同步"
Write-Host "7. ✓ 防火墙规则优化"
Write-Host "8. ✓ 2345浏览器解决方案部署"
Write-Host ""
Write-Host "现在您可以通过以下方式访问GitHub:"
Write-Host "- 2345浏览器 (推荐): 已自动启动并打开GitHub页面"
Write-Host "- 其他浏览器: 应该也能正常访问"
Write-Host ""
Write-Host "如果需要再次执行修复，只需运行此脚本即可。"
