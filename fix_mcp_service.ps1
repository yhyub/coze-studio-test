# McpManagementService服务权限修复脚本
# 创建时间: 2026-01-23
# 功能: 修复服务权限拒绝错误，确保服务正常运行

Write-Host '=== McpManagementService服务权限修复 ===' -ForegroundColor Green
Write-Host '开始修复服务权限错误...' -ForegroundColor White

# 检查当前权限
Write-Host '\n=== 系统权限检查 ===' -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Write-Host '✅ 当前会话具有管理员权限' -ForegroundColor Green
} else {
    Write-Host '❌ 当前会话缺少管理员权限' -ForegroundColor Red
    Write-Host '请以管理员身份运行此脚本' -ForegroundColor Yellow
    Exit 1
}

# 修复步骤1: 停止服务（如果运行）
Write-Host '\n=== 步骤1: 停止服务 ===' -ForegroundColor Yellow