# 2345浏览器自动化脚本
# 功能: 使用2345浏览器打开目标网站，处理SSL证书验证

$browserPath = "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe"

# 目标网站列表
$urls = @(
    "https://github.com/settings/installations/43126163",
    "https://github.com/settings/installations?page=2",
    "https://docs.debricked.com/overview/getting-started",
    "https://github.com/yhyub/coze-studio-test/tree/main"
)

Write-Host "=== 2345浏览器自动化脚本 ==="
Write-Host "浏览器路径: $browserPath"

# 检查浏览器是否存在
if (Test-Path $browserPath) {
    Write-Host "✓ 找到2345浏览器"
    
    # 打开每个网站
    foreach ($url in $urls) {
        Write-Host "`n正在打开: $url"
        Start-Process -FilePath $browserPath -ArgumentList $url
        Start-Sleep -Seconds 3
    }
    
    Write-Host "`n=== 所有网站已打开 ==="
    Write-Host "提示: 如果遇到SSL证书验证问题，请手动接受证书或检查系统时间设置"
} else {
    Write-Host "✗ 未找到2345浏览器"
    Write-Host "请确认浏览器安装路径是否正确"
}