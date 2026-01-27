# GitHub 访问优化脚本
# 版本：1.0
# 日期：2026-01-27

Write-Host "GitHub 访问优化脚本" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# 1. 清除 DNS 缓存
Write-Host "`n1. 清除 DNS 缓存..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host "✅ DNS 缓存已清除" -ForegroundColor Green

# 2. 测试多个 GitHub IP 地址
Write-Host "`n2. 测试多个 GitHub IP 地址..." -ForegroundColor Yellow

$githubIps = @(
    "140.82.114.3",
    "140.82.112.3",
    "140.82.113.3",
    "140.82.115.3",
    "20.205.243.166"
)

$bestIp = $null
$bestResponseTime = [int]::MaxValue

foreach ($ip in $githubIps) {
    $result = Test-Connection $ip -Count 1 -ErrorAction SilentlyContinue
    if ($result) {
        Write-Host "   $ip - $($result.ResponseTime)ms" -ForegroundColor Gray
        if ($result.ResponseTime -lt $bestResponseTime) {
            $bestResponseTime = $result.ResponseTime
            $bestIp = $ip
        }
    } else {
        Write-Host "   $ip - 无法连接" -ForegroundColor Red
    }
}

if ($bestIp) {
    Write-Host "`n✅ 最佳 IP 地址：$bestIp（响应时间：$bestResponseTime ms）" -ForegroundColor Green
    Write-Host "`n建议：将此 IP 添加到 Hosts 文件以提升访问速度" -ForegroundColor Yellow
    Write-Host "   $bestIp github.com" -ForegroundColor Gray
} else {
    Write-Host "`n❌ 无法连接到任何 GitHub IP 地址" -ForegroundColor Red
}

# 3. 提供优化建议
Write-Host "`n3. 优化建议" -ForegroundColor Yellow
Write-Host "   1. 使用更快的 DNS 服务器（Cloudflare 1.1.1.1 或 Google 8.8.8.8）" -ForegroundColor Gray
Write-Host "   2. 配置 Hosts 文件，使用最佳 IP 地址" -ForegroundColor Gray
Write-Host "   3. 尝试使用代理服务器或 VPN" -ForegroundColor Gray
Write-Host "   4. 重启路由器和调制解调器" -ForegroundColor Gray

Write-Host "`n优化完成！" -ForegroundColor Cyan