# 启动Docker服务并验证
Write-Host "=== 启动Docker服务 ==="

# 启动Docker服务
Write-Host "1. 启动Docker服务..."
try {
    Start-Service "Docker Desktop Service" -ErrorAction SilentlyContinue
    Start-Service "Docker" -ErrorAction SilentlyContinue
    Write-Host "Docker服务启动命令已执行"
} catch {
    Write-Host "启动服务时出错: $_"
}

# 启动Docker Desktop应用
Write-Host "2. 启动Docker Desktop应用..."
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktopPath) {
    try {
        Start-Process -FilePath $dockerDesktopPath -WindowStyle Normal
        Write-Host "Docker Desktop已启动: $dockerDesktopPath"
    } catch {
        Write-Host "启动Docker Desktop时出错: $_"
    }
} else {
    Write-Host "Docker Desktop未找到: $dockerDesktopPath"
}

# 等待Docker初始化
Write-Host "3. 等待Docker初始化..."
Write-Host "请确保Docker Desktop完全启动，这可能需要1-2分钟..."
Start-Sleep -Seconds 60

# 验证Docker状态
Write-Host "4. 验证Docker状态..."
try {
    $dockerInfo = docker info
    Write-Host "✅ Docker守护进程正在运行!"
    Write-Host "Docker版本:"
    docker --version
} catch {
    Write-Host "❌ Docker守护进程未运行"
    Write-Host "错误信息: $_"
    Write-Host "请手动启动Docker Desktop并确保它正常运行"
    Read-Host "按Enter键退出"
    exit 1
}

# 检查Docker网络
Write-Host "5. 检查Docker网络..."
try {
    docker network ls
} catch {
    Write-Host "检查网络时出错: $_"
}

Write-Host "=== Docker服务启动完成 ==="
Write-Host "Docker状态: 已运行"
Write-Host "现在可以运行Coze Studio启动脚本了"
Read-Host "按Enter键退出"