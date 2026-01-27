# GitHub 访问修复脚本
# 版本：1.0
# 日期：2026-01-27

Write-Host "GitHub 访问修复脚本" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# 1. 清除 DNS 缓存
Write-Host "`n1. 清除 DNS 缓存..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host "✅ DNS 缓存已清除" -ForegroundColor Green

# 2. 测试网络连接
Write-Host "`n2. 测试网络连接..." -ForegroundColor Yellow
$pingResult = Test-Connection github.com -Count 1 -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "✅ 网络连接正常" -ForegroundColor Green
    Write-Host "   响应时间：$($pingResult.ResponseTime)ms" -ForegroundColor Gray
} else {
    Write-Host "❌ 网络连接失败" -ForegroundColor Red
}

# 3. 测试 HTTPS 连接
Write-Host "`n3. 测试 HTTPS 连接..." -ForegroundColor Yellow
$httpsResult = Test-NetConnection github.com -Port 443 -ErrorAction SilentlyContinue
if ($httpsResult.TcpTestSucceeded) {
    Write-Host "✅ HTTPS 连接正常" -ForegroundColor Green
    Write-Host "   IP 地址：$($httpsResult.RemoteAddress)" -ForegroundColor Gray
} else {
    Write-Host "❌ HTTPS 连接失败" -ForegroundColor Red
    Write-Host "   可能原因：防火墙限制、DNS 解析问题或 ISP 限制" -ForegroundColor Gray
}

# 4. 提供手动修复方案
Write-Host "`n4. 手动修复方案" -ForegroundColor Yellow
Write-Host "   请按照以下步骤手动修复：" -ForegroundColor Gray
Write-Host "   1. 以管理员身份打开记事本" -ForegroundColor Gray
Write-Host "   2. 打开文件：C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
Write-Host "   3. 添加以下内容：" -ForegroundColor Gray
Write-Host "      140.82.114.3 github.com" -ForegroundColor Gray
Write-Host "      140.82.114.4 api.github.com" -ForegroundColor Gray
Write-Host "   4. 保存文件并重启浏览器" -ForegroundColor Gray

# 5. 验证修复结果
Write-Host "`n5. 验证修复结果" -ForegroundColor Yellow
Write-Host "   执行以下命令验证：" -ForegroundColor Gray
Write-Host "   Test-NetConnection github.com -Port 443" -ForegroundColor Gray

Write-Host "`n修复完成！" -ForegroundColor Cyan
Write-Host "如果问题仍然存在，请尝试：" -ForegroundColor Gray
Write-Host "   - 更换 DNS 服务器为 1.1.1.1 或 8.8.8.8" -ForegroundColor Gray
Write-Host "   - 使用代理服务器或 VPN" -ForegroundColor Gray
Write-Host "   - 联系 ISP 确认是否有访问限制" -ForegroundColor Gray