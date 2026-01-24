# Docker 修复与 Coze Studio 启动脚本
# 版本: 2.0.0
# 功能: 确保 Docker 服务运行，修复配置问题，启动 Coze Studio

Write-Host "开始执行 Docker 修复与 Coze Studio 启动脚本" -ForegroundColor Cyan
Write-Host "=" * 80

# 1. 确保 Docker Desktop 正在运行
Write-Host "1. 确保 Docker Desktop 正在运行..." -ForegroundColor White
$dockerDesktopPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktopPath) {
    # 检查 Docker Desktop 进程是否正在运行
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Host "启动 Docker Desktop..." -ForegroundColor Yellow
        Start-Process -Path $dockerDesktopPath -ErrorAction SilentlyContinue
        Write-Host "等待 Docker Desktop 完全启动 (90秒)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 90
    } else {
        Write-Host "Docker Desktop 已在运行" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Docker Desktop 未安装，请先安装 Docker Desktop" -ForegroundColor Red
    exit 1
}

# 2. 验证 Docker 服务是否运行
try {
    $dockerInfo = docker info 2>&1
    if ($dockerInfo -like "*Server Version*") {
        Write-Host "✅ Docker 服务已成功运行" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker 服务未运行，请确保 Docker Desktop 已完全启动" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Docker 服务未运行，请确保 Docker Desktop 已完全启动" -ForegroundColor Red
    exit 1
}

# 3. 修复 Docker 配置文件中的 features 字段
Write-Host "3. 修复 Docker 配置文件..." -ForegroundColor White
$dockerConfigPath = "$env:USERPROFILE\.docker\config.json"
if (Test-Path $dockerConfigPath) {
    # 读取并修复配置文件
    $configContent = Get-Content -Path $dockerConfigPath -Raw
    
    # 检查并修复 features 字段
    if ($configContent -match '"features":\s*"') {
        Write-Host "修复 features 字段类型错误..." -ForegroundColor Yellow
        $fixedConfig = $configContent -replace '"features":\s*"[^"]*"', '"features": {}'
        $fixedConfig | Out-File -FilePath $dockerConfigPath -Force -Encoding UTF8
        Write-Host "✅ Docker 配置文件已修复" -ForegroundColor Green
    } else {
        Write-Host "✅ Docker 配置文件已正常" -ForegroundColor Green
    }
} else {
    Write-Host "Docker 配置文件不存在，创建默认配置..." -ForegroundColor Yellow
    $defaultConfig = '{"features": {}}'
    $defaultConfig | Out-File -FilePath $dockerConfigPath -Force -Encoding UTF8
    Write-Host "✅ 已创建默认 Docker 配置文件" -ForegroundColor Green
}

# 4. 进入 Coze Studio docker 目录
Write-Host "4. 进入 Coze Studio docker 目录..." -ForegroundColor White
$cozeDockerDir = "c:\Users\Administrator\Desktop\fcjgfycrteas\coze-studio-0.5.0\docker"
if (Test-Path $cozeDockerDir) {
    Set-Location -Path $cozeDockerDir
    Write-Host "✅ 已进入目录: $cozeDockerDir" -ForegroundColor Green
} else {
    Write-Host "❌ Coze Studio docker 目录不存在" -ForegroundColor Red
    exit 1
}

# 5. 确保 .env 文件存在
Write-Host "5. 检查 .env 文件..." -ForegroundColor White
if (-not (Test-Path ".env")) {
    Write-Host "创建 .env 文件..." -ForegroundColor Yellow
    Copy-Item -Path ".env.debug.example" -Destination ".env" -Force
    Write-Host "✅ .env 文件创建成功" -ForegroundColor Green
} else {
    Write-Host "✅ .env 文件已存在" -ForegroundColor Green
}

# 6. 清理旧的容器和网络
Write-Host "6. 清理旧的容器和网络..." -ForegroundColor White
try {
    docker compose down --remove-orphans -v 2>&1 | Out-Null
    Write-Host "✅ 已清理旧的容器和网络" -ForegroundColor Green
} catch {
    Write-Host "清理旧容器时出错，可能是第一次运行" -ForegroundColor Yellow
}

# 7. 启动 Coze Studio 服务
Write-Host "7. 启动 Coze Studio 服务..." -ForegroundColor White
Write-Host "⚠️  这可能需要 5-10 分钟时间，请耐心等待..." -ForegroundColor Yellow
docker compose --profile '*' up -d

# 8. 等待服务启动
Write-Host "8. 等待服务启动 (120秒)..." -ForegroundColor White
Start-Sleep -Seconds 120

# 9. 检查服务状态
Write-Host "9. 检查服务状态..." -ForegroundColor White
try {
    $services = docker compose ps
    Write-Host "服务状态: " -ForegroundColor White
    Write-Host $services -ForegroundColor White
    
    # 检查是否有正在运行的服务
    if ($services -like "*running*") {
        Write-Host "✅ 部分服务已成功启动" -ForegroundColor Green
    } else {
        Write-Host "❌ 没有服务在运行，请查看日志获取更多信息" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 检查服务状态失败" -ForegroundColor Red
}

# 10. 验证访问
Write-Host "10. 验证 Coze Studio 访问..." -ForegroundColor White
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8888" -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "🎉 Coze Studio 访问成功！" -ForegroundColor Green
        Write-Host "🌐 访问地址: http://localhost:8888" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor White
        Write-Host "✅ 部署完成！您可以通过浏览器访问上述地址开始使用 Coze Studio。" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Coze Studio 访问返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
        Write-Host "请等待几分钟后再次尝试访问 http://localhost:8888" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️ Coze Studio 可能需要更多启动时间" -ForegroundColor Yellow
    Write-Host "请等待几分钟后手动访问: http://localhost:8888" -ForegroundColor White
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    Write-Host "📋 您可以通过以下命令查看服务日志: " -ForegroundColor White
    Write-Host "   docker compose logs -f" -ForegroundColor Cyan
}

Write-Host "" -ForegroundColor White
Write-Host "=" * 80
Write-Host "脚本执行完成" -ForegroundColor Cyan