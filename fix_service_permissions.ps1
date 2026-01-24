# 服务权限修复脚本
# 修复McpManagementService服务权限拒绝错误
# 确保Docker服务正常运行

Write-Host '=============================================' -ForegroundColor Green
Write-Host '         服务权限修复脚本 v1.0              ' -ForegroundColor Green
Write-Host '=============================================' -ForegroundColor Green

# 检查管理员权限
Write-Host '\n=== 权限检查 ===' -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host '❌ 错误: 请以管理员身份运行此脚本' -ForegroundColor Red
    Read-Host '按任意键退出...'
    exit 1
}
Write-Host '✅