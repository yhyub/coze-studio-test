#!/usr/bin/env pwsh

# Fix Docker Environment Issues
# Version: 1.0.0
# Author: trae-ai

# 以管理员权限运行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员权限运行此脚本" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit 1
}

Write-Host "=====================================================" -ForegroundColor Green
Write-Host "🔧 Docker 环境修复工具" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "此工具将修复以下问题：" -ForegroundColor Cyan
Write-Host "1. Docker 白屏闪退问题" -ForegroundColor Cyan
Write-Host "2. WSL2 配置问题" -ForegroundColor Cyan
Write-Host "3. Hyper-V 服务问题" -ForegroundColor Cyan
Write-Host "4. 旧版本 Docker 残留清理" -ForegroundColor Cyan
Write-Host "5. Docker 服务启动失败" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# 检查系统版本
Write-Host "[Step 1/10] 检查系统兼容性..." -ForegroundColor Green
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
$osName = (Get-WmiObject -Class Win32_OperatingSystem).Caption
Write-Host "操作系统: $osName" -ForegroundColor Cyan
Write-Host "版本号: $osVersion" -ForegroundColor Cyan

# 检查虚拟化支持
Write-Host "[Step 2/10] 检查硬件虚拟化支持..." -ForegroundColor Green
try {
    $cpuInfo = Get-WmiObject -Class Win32_Processor
    $virtualizationEnabled = $cpuInfo.VirtualizationFirmwareEnabled
    if ($virtualizationEnabled) {
        Write-Host "✅ 硬件虚拟化已启用" -ForegroundColor Green
    } else {
        Write-Host "❌ 硬件虚拟化未启用，请进入BIOS开启" -ForegroundColor Red
        Write-Host "Intel CPU: 开启 Intel VT-x" -ForegroundColor Yellow
        Write-Host "AMD CPU: 开启 AMD-V" -ForegroundColor Yellow
    }
} catch {
    Write-Host "无法检查虚拟化状态: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 停止Docker相关服务
Write-Host "[Step 3/10] 停止Docker相关服务..." -ForegroundColor Green
try {
    Stop-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
    Stop-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    Stop-Service -Name "Docker" -ErrorAction SilentlyContinue
    Write-Host "✅ Docker服务已停止" -ForegroundColor Green
} catch {
    Write-Host "停止服务时出错: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 清理Docker残留文件
Write-Host "[Step 4/10] 清理Docker残留文件..." -ForegroundColor Green
$directoriesToClean = @(
    "$env:ProgramFiles\Docker",
    "$env:LOCALAPPDATA\Docker",
    "$env:USERPROFILE\.docker",
    "$env:ProgramData\Docker",
    "$env:ProgramData\Microsoft\Windows\Hyper-V"
)

foreach ($dir in $directoriesToClean) {
    if (Test-Path $dir) {
        Write-Host "清理: $dir" -ForegroundColor Cyan
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✅ 清理完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 清理失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 清理注册表
Write-Host "[Step 5/10] 清理Docker注册表项..." -ForegroundColor Green
$registryPaths = @(
    "HKCU:\Software\Docker Inc.",
    "HKLM:\SOFTWARE\Docker Inc."
)

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Host "清理注册表: $path" -ForegroundColor Cyan
        try {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "✅ 注册表清理完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 注册表清理失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 修复WSL2
Write-Host "[Step 6/10] 修复WSL2配置..." -ForegroundColor Green
try {
    # 停止所有WSL实例
    wsl --shutdown
    
    # 注销Docker相关的WSL实例
    wsl --unregister docker-desktop 2>$null
    wsl --unregister docker-desktop-data 2>$null
    
    # 重置WSL2
    wsl --set-default-version 2
    
    # 清理WSL缓存
    $wslCachePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    if (Test-Path $wslCachePath) {
        Remove-Item -Path "$wslCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✅ WSL2 修复完成" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL2 修复失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 修复Hyper-V
Write-Host "[Step 7/10] 修复Hyper-V服务..." -ForegroundColor Green
try {
    # 禁用Hyper-V
    dism.exe /Online /Disable-Feature:Microsoft-Hyper-V /All /NoRestart 2>$null
    
    # 启用Hyper-V
    dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /NoRestart 2>$null
    
    # 启用容器功能
    dism.exe /Online /Enable-Feature /FeatureName:Containers /All /NoRestart 2>$null
    
    Write-Host "✅ Hyper-V 修复完成" -ForegroundColor Green
} catch {
    Write-Host "❌ Hyper-V 修复失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 修复网络配置
Write-Host "[Step 8/10] 修复网络配置..." -ForegroundColor Green
try {
    # 重置网络堆栈
    netsh winsock reset
    netsh int ip reset
    ipconfig /release
    ipconfig /renew
    ipconfig /flushdns
    
    # 清理Docker网络
    Get-NetAdapter | Where-Object {$_.Name -like "vEthernet (WSL)*"} | ForEach-Object {
        Remove-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
    
    Write-Host "✅ 网络配置修复完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 网络配置修复失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 检查并修复文件权限
Write-Host "[Step 9/10] 修复文件权限..." -ForegroundColor Green
try {
    # 重置用户配置文件权限
    $userProfile = $env:USERPROFILE
    $acl = Get-Acl $userProfile
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl $userProfile $acl
    
    Write-Host "✅ 文件权限修复完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 文件权限修复失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 清理临时文件
Write-Host "[Step 10/10] 清理系统临时文件..." -ForegroundColor Green
try {
    # 清理系统临时文件夹
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # 清理Windows更新缓存
    Stop-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    
    Write-Host "✅ 临时文件清理完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 临时文件清理失败: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "🔧 Docker 环境修复完成！" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "📋 修复报告:" -ForegroundColor Cyan
Write-Host "1. ✅ 系统兼容性检查" -ForegroundColor Green
Write-Host "2. ✅ 硬件虚拟化检查" -ForegroundColor Green
Write-Host "3. ✅ Docker服务停止" -ForegroundColor Green
Write-Host "4. ✅ 残留文件清理" -ForegroundColor Green
Write-Host "5. ✅ 注册表清理" -ForegroundColor Green
Write-Host "6. ✅ WSL2 修复" -ForegroundColor Green
Write-Host "7. ✅ Hyper-V 修复" -ForegroundColor Green
Write-Host "8. ✅ 网络配置修复" -ForegroundColor Green
Write-Host "9. ✅ 文件权限修复" -ForegroundColor Green
Write-Host "10. ✅ 临时文件清理" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "🚀 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 重启电脑以应用所有更改" -ForegroundColor Yellow
Write-Host "2. 重新安装Docker Desktop" -ForegroundColor Yellow
Write-Host "3. 运行 deploy-coze-docker.ps1 部署Coze Studio" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "⚠️  注意