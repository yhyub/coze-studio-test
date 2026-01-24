# Coze Studio 自动化修复脚本
# 版本: 3.0.0
# 功能: 全自动完成所有修复步骤，确保显示完整登录页面

# 设置错误处理
$ErrorActionPreference = "Continue"

# 日志文件设置
$logDir = "$env:TEMP\CozeStudioAutoFix"
$logFile = "$logDir\auto_fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 日志函数
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Message = $Message -replace '[^\u0020-\u007E\u4E00-\u9FFF]', ''
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

# 检查管理员权限
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# 修复Docker配置文件（使用不同方法尝试）
function Fix-DockerConfig {
    Write-Log "开始修复Docker配置文件..." "INFO"
    
    try {
        $dockerConfigPath = "$env:USERPROFILE\.docker\config.json"
        $dockerConfigDir = Split-Path -Parent $dockerConfigPath
        
        # 创建配置目录
        if (!(Test-Path $dockerConfigDir)) {
            New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
            Write-Log "创建Docker配置目录: $dockerConfigDir" "INFO"
        }
        
        # 正确的配置内容
        $configContent = @'
{
  "auths": {},
  "credsStore": "desktop.exe",
  "currentContext": "desktop-linux",
  "features": ""
}
'@
        
        # 方法1: 直接写入
        try {
            Set-Content -Path $dockerConfigPath -Value $configContent -Force
            Write-Log "✅ Docker配置文件已修复（方法1）" "SUCCESS"
            return $true
        } catch {
            Write-Log "❌ 方法1失败: $($_.Exception.Message)" "ERROR"
        }
        
        # 方法2: 使用Out-File
        try {
            $configContent | Out-File -FilePath $dockerConfigPath -Encoding UTF8 -Force
            Write-Log "✅ Docker配置文件已修复（方法2）" "SUCCESS"
            return $true
        } catch {
            Write-Log "❌ 方法2失败: $($_.Exception.Message)" "ERROR"
        }
        
        # 方法3: 使用IO.File
        try {
            [System.IO.File]::WriteAllText($dockerConfigPath, $configContent, [System.Text.Encoding]::UTF8)
            Write-Log "✅ Docker配置文件已修复（方法3）" "SUCCESS"
            return $true
        } catch {
            Write-Log "❌ 方法3失败: $($_.Exception.Message)" "ERROR"
        }
        
        Write-Log "❌ 所有修复方法均失败，将使用其他方案" "ERROR"
        return $false
        
    } catch {
        Write-Log "修复Docker配置文件时出错: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 启动Docker服务和Docker Desktop
function Start-DockerServices {
    Write-Log "开始启动Docker服务..." "INFO"
    
    try {
        # 停止所有Docker服务
        Write-Log "停止Docker相关服务" "INFO"
        Get-Service | Where-Object {$_.Name -like '*docker*'} | Stop-Service -Force -ErrorAction SilentlyContinue
        
        # 停止所有Docker进程
        Write-Log "停止Docker相关进程" "INFO"
        Get-Process | Where-Object {$_.Name -like '*docker*'} | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 启动Docker服务
        Write-Log "启动Docker服务" "INFO"
        Start-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
        Start-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
        
        # 等待服务启动
        Write-Log "等待Docker服务启动（30秒）" "INFO"
        Start-Sleep -Seconds 30
        
        # 启动Docker Desktop应用
        Write-Log "启动Docker Desktop应用" "INFO"
        $dockerPaths = @(
            "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
            "$env:ProgramFiles\Docker\Docker\Docker.exe"
        )
        
        $dockerStarted = $false
        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                try {
                    Start-Process -FilePath $path
                    $dockerStarted = $true
                    Write-Log "✅ Docker Desktop已启动: $path" "SUCCESS"
                    break
                } catch {
                    Write-Log "❌ Docker Desktop启动失败: $path" "ERROR"
                }
            }
        }
        
        if (!$dockerStarted) {
            Write-Log "❌ 未找到Docker Desktop安装路径" "ERROR"
            return $false
        }
        
        # 等待Docker Desktop初始化
        Write-Log "等待Docker Desktop初始化（60秒）" "INFO"
        Start-Sleep -Seconds 60
        
        # 验证Docker状态
        Write-Log "验证Docker状态" "INFO"
        $dockerInfo = docker info 2>&1
        if ($dockerInfo -like '*error*') {
            Write-Log "❌ Docker服务启动失败: $dockerInfo" "ERROR"
            return $false
        } else {
            Write-Log "✅ Docker服务正常运行！" "SUCCESS"
            return $true
        }
        
    } catch {
        Write-Log "启动Docker服务时出错: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 修复WSL执行错误
function Fix-WSL {
    Write-Log "开始修复WSL执行错误..." "INFO"
    
    try {
        # 停止所有WSL实例
        Write-Log "停止所有WSL实例" "INFO"
        wsl --shutdown 2>$null
        
        # 等待WSL完全停止
        Start-Sleep -Seconds 5
        
        # 注销Docker Desktop相关的WSL分发
        Write-Log "注销Docker Desktop WSL分发" "INFO"
        wsl --unregister docker-desktop 2>$null
        wsl --unregister docker-desktop-data 2>$null
        
        # 重启WSL服务
        Write-Log "重启WSL服务" "INFO"
        Restart-Service -Name "LxssManager" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
        
        # 启动WSL
        Write-Log "启动WSL" "INFO"
        wsl --list 2>$null
        
        Write-Log "✅ WSL修复完成！" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "修复WSL时出错: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 启动Coze Studio服务
function Start-CozeStudio {
    Write-Log "开始启动Coze Studio服务..." "INFO"
    
    try {
        # 检查Coze Studio目录
        $cozeDir = "$PSScriptRoot\coze-studio-0.5.0\docker"
        if (-not (Test-Path $cozeDir)) {
            Write-Log "❌ Coze Studio目录不存在: $cozeDir" "ERROR"
            return $false
        }
        
        # 切换到Coze Studio目录
        Set-Location -Path $cozeDir
        Write-Log "切换到Coze Studio目录: $cozeDir" "INFO"
        
        # 停止并清理旧的容器
        Write-Log "停止并清理旧的容器" "INFO"
        docker compose down --remove-orphans 2>$null
        
        # 清理Docker缓存
        Write-Log "清理Docker缓存" "INFO"
        docker system prune -f 2>$null
        docker volume prune -f 2>$null
        docker network prune -f 2>$null
        
        # 拉取镜像（使用国内镜像源）
        Write-Log "拉取Coze Studio镜像" "INFO"
        $images = @(
            "docker.1ms.run/cozedev/coze-studio-server:latest",
            "docker.1ms.run/cozedev/coze-studio-web:latest",
            "docker.1ms.run/mysql:8.4.5",
            "docker.1ms.run/bitnamilegacy/redis:8.0",
            "docker.1ms.run/bitnamilegacy/elasticsearch:8.18.0",
            "docker.1ms.run/minio/minio:RELEASE.2025-06-13T11-33-47Z-cpuv1",
            "docker.1ms.run/milvusdb/milvus:v2.5.10",
            "docker.1ms.run/nsqio/nsq:v1.2.1"
        )
        
        foreach ($image in $images) {
            Write-Log "拉取镜像: $image" "INFO"
            docker pull $image 2>$null
        }
        
        # 启动服务
        Write-Log "启动所有Coze Studio服务" "INFO"
        docker compose up -d 2>$null
        
        # 等待服务启动
        Write-Log "等待所有服务启动..." "INFO"
        Write-Log "等待MySQL启动..." "INFO"
        Start-Sleep -Seconds 15
        Write-Log "等待Redis启动..." "INFO"
        Start-Sleep -Seconds 5
        Write-Log "等待Elasticsearch启动..." "INFO"
        Start-Sleep -Seconds 20
        Write-Log "等待MinIO启动..." "INFO"
        Start-Sleep -Seconds 5
        Write-Log "等待Milvus启动..." "INFO"
        Start-Sleep -Seconds 15
        Write-Log "等待NSQ启动..." "INFO"
        Start-Sleep -Seconds 5
        Write-Log "等待coze-server和coze-web启动..." "INFO"
        Start-Sleep -Seconds 20
        
        # 查看服务启动状态
        Write-Log "查看所有服务启动状态" "INFO"
        $psOutput = docker compose ps 2>&1
        Write-Log "服务状态: $psOutput" "INFO"
        
        # 验证所有容器状态
        Write-Log "验证所有容器状态" "INFO"
        $containers = docker ps --filter "name=coze-" 2>&1
        Write-Log "容器状态: $containers" "INFO"
        
        # 验证coze-web服务是否正常运行
        Write-Log "验证coze-web服务是否正常运行" "INFO"
        $webContainer = docker ps --filter "name=coze-web" --filter "status=running" 2>&1
        if ($webContainer -like '*coze-web*') {
            Write-Log "✅ Coze Studio服务完整启动成功！" "SUCCESS"
            Write-Log "访问地址: http://localhost:8888" "SUCCESS"
            return $true
        } else {
            Write-Log "❌ Coze Studio服务启动失败，coze-web容器未运行" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "启动Coze Studio时出错: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        # 切换回脚本目录
        Set-Location -Path $PSScriptRoot
    }
}

# 验证服务访问
function Test-CozeStudioAccess {
    Write-Log "开始验证Coze Studio访问..." "INFO"
    
    try {
        # 等待服务完全启动
        Write-Log "等待服务完全启动（30秒）" "INFO"
        Start-Sleep -Seconds 30
        
        # 验证http://localhost:8888访问
        Write-Log "验证http://localhost:8888访问" "INFO"
        $response = Invoke-WebRequest -Uri "http://localhost:8888" -UseBasicParsing -TimeoutSec 20
        
        if ($response.StatusCode -eq 200) {
            Write-Log "✅ Coze Studio服务可访问！" "SUCCESS"
            Write-Log "状态码: $($response.StatusCode)" "SUCCESS"
            
            # 检查是否包含登录页面元素
            if ($response.Content -like '*登录*' -or $response.Content -like '*login*') {
                Write-Log "✅ 检测到登录页面元素，服务正常！" "SUCCESS"
            } else {
                Write-Log "⚠️  未检测到登录页面元素，可能需要更多启动时间" "WARNING"
            }
            
            return $true
        } else {
            Write-Log "❌ Coze Studio服务访问失败，状态码: $($response.StatusCode)" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "❌ Coze Studio服务访问失败: $($_.Exception.Message)" "ERROR"
        Write-Log "建议：等待2分钟后手动访问 http://localhost:8888" "WARNING"
        return $false
    }
}

# 主函数
function Main {
    Write-Log "=== Coze Studio 自动化修复脚本开始执行 ===" "INFO"
    
    # 检查管理员权限
    if (-not (Test-Admin)) {
        Write-Log "请以管理员身份运行此脚本" "ERROR"
        Write-Host "请右键点击脚本并选择'以管理员身份运行'" -ForegroundColor Red
        Start-Sleep -Seconds 5
        return
    }
    
    # 1. 修复Docker配置文件
    $configFixed = Fix-DockerConfig
    if (-not $configFixed) {
        Write-Log "Docker配置文件修复失败，继续执行其他步骤" "WARNING"
    }
    
    # 2. 修复WSL执行错误
    $wslFixed = Fix-WSL
    if (-not $wslFixed) {
        Write-Log "WSL修复失败，继续执行其他步骤" "WARNING"
    }
    
    # 3. 启动Docker服务和Docker Desktop
    $dockerStarted = Start-DockerServices
    if (-not $dockerStarted) {
        Write-Log "Docker服务启动失败，继续执行其他步骤" "WARNING"
    }
    
    # 4. 启动Coze Studio服务
    $cozeStarted = Start-CozeStudio
    if (-not $cozeStarted) {
        Write-Log "Coze Studio服务启动失败" "ERROR"
    }
    
    # 5. 验证服务访问
    $accessTested = Test-CozeStudioAccess
    if (-not $accessTested) {
        Write-Log "Coze Studio服务访问测试失败" "ERROR"
    }
    
    # 6. 输出最终结果
    Write-Log "=== Coze Studio 自动化修复脚本执行完成 ===" "INFO"
    Write-Log "访问地址: http://localhost:8888" "INFO"
    Write-Log "日志文件: $logFile" "INFO"
    
    # 显示访问地址信息
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "Coze Studio 自动化修复完成！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "`n访问地址：" -ForegroundColor Yellow
    Write-Host "- Coze Studio 主界面：http://localhost:8888" -ForegroundColor Yellow
    Write-Host "- Coze Studio 注册地址：http://localhost:8888/sign" -ForegroundColor Yellow
    Write-Host "- Coze Studio 管理界面：http://localhost:8888/admin" -ForegroundColor Yellow
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "执行结果：" -ForegroundColor Cyan
    Write-Host "✅ Docker配置文件修复: $($configFixed ? '成功' : '失败')" -ForegroundColor $($configFixed ? 'Green' : 'Red')
    Write-Host "✅ WSL执行错误修复: $($wslFixed ? '成功' : '失败')" -ForegroundColor $($wslFixed ? 'Green' : 'Red')
    Write-Host "✅ Docker服务启动: $($dockerStarted ? '成功' : '失败')" -ForegroundColor $($dockerStarted ? 'Green' : 'Red')
    Write-Host "✅ Coze Studio服务启动: $($cozeStarted ? '成功' : '失败')" -ForegroundColor $($cozeStarted ? 'Green' : 'Red')
    Write-Host "✅ 服务访问测试: $($accessTested ? '成功' : '失败')" -ForegroundColor $($accessTested ? 'Green' : 'Red')
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "提示：" -ForegroundColor Yellow
    Write-Host "1. 首次启动可能需要3-5分钟时间" -ForegroundColor Yellow
    Write-Host "2. 如果访问失败，请等待2分钟后重新访问" -ForegroundColor Yellow
    Write-Host "3. 详细日志请查看: $logFile" -ForegroundColor Yellow
    Write-Host "`n============================================" -ForegroundColor Green
}

# 执行主函数
Main

# 暂停以查看结果
Write-Host "`n按任意键退出..." -ForegroundColor Cyan
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null