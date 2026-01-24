#!/usr/bin/env powershell
# 终端错误修复脚本 - 64位系统专用
# 修复McpManagementService服务权限错误和Docker相关问题

# 设置脚本参数
param(
    [switch]$Verbose = $false
)

# 颜色定义
$ColorSuccess = 'Green'
$ColorError = 'Red'
$ColorWarning = 'Yellow'
$ColorInfo = 'Cyan'
$ColorHeader = 'White'

# 日志文件
$LogFile = "$PSScriptRoot\fix_terminal_error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 函数：写入日志
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    if ($Verbose -or $Level -eq 'ERROR') {
        Write-Host $logEntry
    }
}

# 函数：检查管理员权限
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([