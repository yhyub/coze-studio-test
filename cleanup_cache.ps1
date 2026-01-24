<#
系统缓存和无用文件清理脚本
目标：删除所有Docker相关缓存、日志文件、备份文件等无用数据
#>

# 颜色常量
$COLOR_TITLE = 'Green'
$COLOR_SUCCESS = 'Green'
$COLOR_ERROR = 'Red'
$COLOR_WARNING = 'Yellow'
$COLOR_INFO = 'White'

Write-Host "`n=== 系统缓存和无用文件清理 ===" -ForegroundColor $COLOR_TITLE
Write-Host "开始清理所有无用的缓存和记录文件" -ForegroundColor $COLOR_INFO

# 日志记录函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logPath = "$PSScriptRoot\cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    $logEntry = "[$timestamp] [$Type] $Message"
    $logEntry | Out-File -FilePath $logPath -Append
    
    # 根据类型选择颜色
    switch ($Type) {
        "Success" { $color = $COLOR_SUCCESS }
        "Error" { $color = $COLOR_ERROR }
        "Warning" { $color = $COLOR_WARNING }
        "Info" { $color = $COLOR_INFO }
        default { $color = $COLOR_INFO }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# 1. 清理Docker相关缓存和临时文件
Write-Log "清理Docker相关缓存和临时文件" "Info"
try {
    # Docker临时目录
    $dockerTempDirs = @(
        "$env:TEMP\docker",
        "$env:LOCALAPPDATA\Docker",
        "$env:APPDATA\Docker",
        "$env:ProgramData\Docker\tmp",
        "$env:ProgramData\Docker\logs"
    )
    
    foreach ($dir in $dockerTempDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "清理Docker临时目录: $dir" "Success"
        }
    }
    
    # Docker备份文件
    $dockerBackups = @(
        "$env:ProgramData\Docker.bak*",
        "$env:USERPROFILE\.docker.bak*"
    )
    
    foreach ($backupPattern in $dockerBackups) {
        Get-Item -Path $backupPattern -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction