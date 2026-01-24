<#
.SYNOPSIS
2345浏览器设置工具 - 帮助设置2345浏览器为默认浏览器
#>

Write-Host "=== 2345浏览器设置为默认浏览器 ===" -ForegroundColor Cyan
Write-Host ""

try {
    # 1. 定位2345浏览器可执行文件
    Write-Host "1. 定位2345浏览器可执行文件..." -ForegroundColor Cyan
    
    # 2345浏览器可能的安装路径
    $browserPaths = @(
        "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe",
        "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"
    )
    
    $browserFound = $false
    $browserPath = ""
    foreach ($path in $browserPaths) {
        if (Test-Path $path) {
            $browserFound = $true
            $browserPath = $path
            Write-Host "✅ 找到2345浏览器: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $browserFound) {
        Write-Host "❌ 未找到2345浏览器可执行文件" -ForegroundColor Red
        Write-Host "请先安装2345浏览器，然后再运行此脚本" -ForegroundColor Yellow
        Exit 1
    }
    
    # 2. 清除DNS缓存
    Write-Host ""
    Write-Host "2. 清除DNS缓存..." -ForegroundColor Cyan
    & "C:\Windows\System32\ipconfig.exe" /flushdns | Out-Null
    Write-Host "✅ DNS缓存清除成功" -ForegroundColor Green
    
    # 3. 打开系统设置的默认应用页面
    Write-Host ""
    Write-Host "3. 打开系统设置 - 默认应用页面..." -ForegroundColor Cyan
    
    # 打开Windows设置的默认应用页面
    Start-Process ms-settings:defaultapps
    Write-Host "✅ 已打开系统设置 - 默认应用页面" -ForegroundColor Green
    
    # 4. 提供设置指导
    Write-Host ""
    Write-Host "📋 设置步骤：" -ForegroundColor Yellow
    Write-Host "1. 在打开的"设置"窗口中，找到"Web浏览器"选项"
    Write-Host "2. 点击当前默认浏览器的名称（通常是Edge）"
    Write-Host "3. 在弹出的列表中，选择"2345浏览器""
    Write-Host "4. 关闭设置窗口"
    Write-Host ""
    
    # 5. 启动2345浏览器
    Write-Host "4. 启动2345浏览器..." -ForegroundColor Cyan
    
    try {
        # 先停止所有2345浏览器进程
        Get-Process -Name "*2345Explorer*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        # 启动浏览器
        Start-Process -FilePath $browserPath -NoNewWindow
        Write-Host "✅ 2345浏览器已启动" -ForegroundColor Green
    } catch {
        Write-Host "❌ 启动2345浏览器失败: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=== 设置完成 ===" -ForegroundColor Green
    Write-Host "请按照上述步骤在系统设置中手动将2345浏览器设置为默认浏览器" -ForegroundColor Cyan
    Write-Host ""    
} catch {
    Write-Host "❌ 设置过程中出现错误: $_" -ForegroundColor Red
    Exit 1
}

# 暂停脚本，让用户查看结果
Read-Host -Prompt "按Enter键退出"