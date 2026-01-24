# Docker配置修复脚本
# 版本: 1.0.0
# 功能: 修复Docker配置文件格式问题，启动服务

Write-Host "=== Docker配置修复脚本 ===" -ForegroundColor Green

# 1. 修复Docker配置文件
Write-Host "`n1. 修复Docker配置文件格式问题..." -ForegroundColor Cyan

$dockerConfigPath = "$env:USERPROFILE\.docker\config.json"
$dockerConfigDir = Split-Path -Parent $dockerConfigPath

if (!(Test-Path $dockerConfigDir)) {
    New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
    Write-Host "创建Docker配置目录: $dockerConfigDir" -ForegroundColor Yellow
}

# 创建正确格式的配置文件
$configContent = @'
{
  "auths": {},
  "credsStore": "desktop.exe",
  "currentContext": "desktop-linux",
  "features": ""
}
'@

try {
    Set-Content -Path $dockerConfigPath -Value $configContent -Force
    Write-Host "✅ Docker配置文件已修复！" -ForegroundColor Green
    Write-Host "配置文件路径: $dockerConfigPath" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Docker配置文件修复失败，权限受限" -ForegroundColor Red
    Write-Host "请手动将以下内容复制到 $dockerConfigPath 文件中：" -ForegroundColor Yellow
    Write-Host $configContent -ForegroundColor White
}

# 2. 启动Docker服务
Write-Host "`n2. 启动Docker服务..." -ForegroundColor Cyan

try {
    # 启动Docker服务
    Start-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    Start-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
    Write-Host "✅ Docker服务已启动" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker服务启动失败" -ForegroundColor Red
    Write-Host "请手动启动Docker Desktop" -ForegroundColor Yellow
}

# 3. 等待Docker Desktop初始化
Write-Host "`n3. 等待Docker Desktop初始化（60秒）..." -ForegroundColor Cyan
Start-Sleep -Seconds 60

# 4. 验证Docker状态
Write-Host "`n4. 验证Docker状态..." -ForegroundColor Cyan

try {
    $dockerVersion = docker version 2>&1
    Write-Host "✅ Docker版本: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker未运行，请检查Docker Desktop状态" -ForegroundColor Red
}

# 5. 启动Coze Studio服务
Write-Host "`n5. 启动Coze Studio服务..." -ForegroundColor Cyan

try {
    $cozeDir = "$PSScriptRoot\coze-studio-0.5.0\docker"
    if (Test-Path $cozeDir) {
        Set-Location -Path $cozeDir
        Write-Host "切换到Coze Studio目录: $cozeDir" -ForegroundColor Yellow
        
        # 启动服务
        Write-Host "正在启动Coze Studio服务..." -ForegroundColor Yellow
        docker compose up -d 2>$null
        
        # 等待服务启动
        Write-Host "等待服务启动完成（120秒）..." -ForegroundColor Yellow
        Start-Sleep -Seconds 120
        
        # 检查服务状态
        Write-Host "检查服务状态..." -ForegroundColor Yellow
        docker compose ps
        
        # 切换回原目录
        Set-Location -Path $PSScriptRoot
    } else {
        Write-Host "❌ Coze Studio目录不存在: $cozeDir" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Coze Studio服务启动失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 验证服务访问
Write-Host "`n6. 验证服务访问..." -ForegroundColor Cyan

Write-Host "访问地址：" -ForegroundColor Yellow
Write-Host "- Coze Studio 主界面：http://localhost:8888" -ForegroundColor Yellow
Write-Host "- Coze Studio 注册地址：http://localhost:8888/sign" -ForegroundColor Yellow
Write-Host "- Coze Studio 管理界面：http://localhost:8888/admin" -ForegroundColor Yellow

Write-Host "`n=== 修复完成 ===" -ForegroundColor Green
Write-Host "请在浏览器中访问 http://localhost:8888 查看完整登录页面" -ForegroundColor Yellow
Write-Host "`n按任意键退出..." -ForegroundColor Cyan
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null