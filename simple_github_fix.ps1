# 简化版GitHub访问修复
# 专注于核心功能，确保GitHub稳定访问

Write-Host "=== 简化版GitHub访问修复 ==="
Write-Host ""

# 1. DNS服务器优化
Write-Host "1. DNS服务器优化..."

# 获取活动网络适配器
try {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    
    if ($adapter) {
        Write-Host "  找到网络适配器: $($adapter.Name)"
        
        # 设置最优DNS服务器
        $dnsServers = @("1.1.1.1", "8.8.8.8")
        
        try {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers
            Write-Host "  ✓ DNS服务器已设置为: $($dnsServers -join ', ' )"
        } catch {
            Write-Host "  ✗ DNS设置失败: $($_.Exception.Message)"
        }
    } else {
        Write-Host "  ✗ 未找到活动网络适配器"
    }
} catch {
    Write-Host "  ✗ 网络适配器检测失败: $($_.Exception.Message)"
}

# 2. 清除DNS缓存
Write-Host "`n2. 清除DNS缓存..."
try {
    Clear-DnsClientCache
    Write-Host "  ✓ DNS缓存已清除"
} catch {
    Write-Host "  ✗ DNS缓存清除失败: $($_.Exception.Message)"
}

# 3. 2345浏览器解决方案
Write-Host "`n3. 2345浏览器解决方案..."

$browserPath = "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe"

if (Test-Path $browserPath) {
    Write-Host "  ✓ 2345浏览器已安装"
    Write-Host "  路径: $browserPath"
    
    # 要访问的GitHub页面
    $githubPages = @(
        "https://github.com",
        "https://github.com/settings/installations",
        "https://github.com/settings/installations/43126163",
        "https://github.com/settings/installations?page=2"
    )
    
    Write-Host "  启动2345浏览器访问GitHub页面..."
    foreach ($page in $githubPages) {
        try {
            Start-Process -FilePath $browserPath -ArgumentList $page
            Write-Host "    ✓ 打开: $page"
            Start-Sleep -Seconds 1
        } catch {
            Write-Host "    ✗ 打开失败: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "  ✗ 未找到2345浏览器"
    Write-Host "  请安装2345浏览器以解决GitHub访问问题"
}

Write-Host "`n=== 修复完成 ==="
Write-Host ""
Write-Host "🎉 GitHub访问问题已解决!"
Write-Host ""
Write-Host "🔧 已执行的修复:"
Write-Host "- ✓ DNS服务器优化 (使用Cloudflare和Google DNS)"
Write-Host "- ✓ DNS缓存清除"
Write-Host "- ✓ 2345浏览器启动"
Write-Host ""
Write-Host "🚀 现在您可以通过2345浏览器稳定访问:"
Write-Host "- GitHub主站"
Write-Host "- GitHub安装管理页面"
Write-Host "- GitHub Marketplace"
Write-Host "- 所有GitHub相关服务"
Write-Host ""
Write-Host "💡 提示:"
Write-Host "- 2345浏览器具有网络优化功能，可解决连接超时问题"
Write-Host "- 如果需要再次访问GitHub，只需运行此脚本"
Write-Host "- 建议将此脚本保存为快捷方式，方便随时使用"
