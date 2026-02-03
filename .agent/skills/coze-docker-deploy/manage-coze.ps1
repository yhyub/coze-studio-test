#!/usr/bin/env pwsh

# Manage Coze Studio Docker Services
# Version: 1.0.0
# Author: trae-ai

# 以管理员权限运行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员权限运行此脚本" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit 1
}

# 检查参数
if ($args.Length -eq 0) {
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host "📋 Coze Studio 管理工具" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host "使用方法: .\manage-coze.ps1 <命令>" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Green
    Write-Host "命令列表:" -ForegroundColor Cyan
    Write-Host "  start       - 启动所有服务" -ForegroundColor Yellow
    Write-Host "  stop        - 停止所有服务" -ForegroundColor Yellow
    Write-Host "  restart     - 重启所有服务" -ForegroundColor Yellow
    Write-Host "  status      - 查看服务状态" -ForegroundColor Yellow
    Write-Host "  logs        - 查看服务日志" -ForegroundColor Yellow
    Write-Host "  check       - 检查环境配置" -ForegroundColor Yellow
    Write-Host "  backup      - 创建备份" -ForegroundColor Yellow
    Write-Host "  restore     - 恢复备份" -ForegroundColor Yellow
    Write-Host "  update      - 检查更新" -ForegroundColor Yellow
    Write-Host "  upgrade     - 升级服务" -ForegroundColor Yellow
    Write-Host "  cleanup     - 清理服务" -ForegroundColor Yellow
    Write-Host "  help        - 显示此帮助" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    exit 0
}

$command = $args[0].ToLower()
$deployDir = "$PSScriptRoot\deploy"

# 检查部署目录
if (-not (Test-Path $deployDir)) {
    Write-Host "部署目录不存在，请先运行 deploy-coze-docker.ps1" -ForegroundColor Red
    exit 1
}

Set-Location $deployDir

switch ($command) {
    "start" {
        Write-Host "[命令] 启动Coze Studio服务..." -ForegroundColor Green
        try {
            docker-compose up -d
            Write-Host "服务启动中，请等待3分钟让所有服务完全启动..." -ForegroundColor Cyan
            Start-Sleep -Seconds 180
            docker-compose ps
            Write-Host "✅ 服务启动完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 服务启动失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "stop" {
        Write-Host "[命令] 停止Coze Studio服务..." -ForegroundColor Green
        try {
            docker-compose down
            Write-Host "✅ 服务已停止" -ForegroundColor Green
        } catch {
            Write-Host "❌ 服务停止失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "restart" {
        Write-Host "[命令] 重启Coze Studio服务..." -ForegroundColor Green
        try {
            docker-compose down
            Start-Sleep -Seconds 10
            docker-compose up -d
            Write-Host "服务重启中，请等待3分钟..." -ForegroundColor Cyan
            Start-Sleep -Seconds 180
            docker-compose ps
            Write-Host "✅ 服务重启完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 服务重启失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "status" {
        Write-Host "[命令] 查看服务状态..." -ForegroundColor Green
        try {
            $status = docker-compose ps
            Write-Host $status
            
            # 检查每个服务的状态
            $services = @("coze-web", "coze-server", "mysql", "redis", "elasticsearch", "minio", "milvus")
            Write-Host "" -ForegroundColor Green
            Write-Host "📋 详细状态:" -ForegroundColor Cyan
            foreach ($service in $services) {
                $containerStatus = docker inspect --format '{{.State.Status}}' $service 2>$null
                if ($containerStatus -eq "running") {
                    Write-Host "✅ $service: 运行中" -ForegroundColor Green
                } elseif ($containerStatus -eq "exited") {
                    Write-Host "❌ $service: 已停止" -ForegroundColor Red
                } else {
                    Write-Host "⚠️  $service: 未启动" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "❌ 状态检查失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "logs" {
        Write-Host "[命令] 查看服务日志..." -ForegroundColor Green
        try {
            Write-Host "选择要查看的服务日志:" -ForegroundColor Cyan
            Write-Host "1. 所有服务"
            Write-Host "2. coze-web (Web界面)"
            Write-Host "3. coze-server (API服务)"
            Write-Host "4. mysql (数据库)"
            Write-Host "5. redis (缓存)"
            Write-Host "6. elasticsearch (搜索)"
            Write-Host "7. minio (存储)"
            Write-Host "8. milvus (向量库)"
            
            $choice = Read-Host "请输入选项 (1-8)"
            
            switch ($choice) {
                "1" { docker-compose logs --tail=100 }
                "2" { docker-compose logs --tail=100 coze-web }
                "3" { docker-compose logs --tail=100 coze-server }
                "4" { docker-compose logs --tail=100 mysql }
                "5" { docker-compose logs --tail=100 redis }
                "6" { docker-compose logs --tail=100 elasticsearch }
                "7" { docker-compose logs --tail=100 minio }
                "8" { docker-compose logs --tail=100 milvus }
                default { Write-Host "无效选项" -ForegroundColor Red }
            }
        } catch {
            Write-Host "❌ 日志查看失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "check" {
        Write-Host "[命令] 检查环境配置..." -ForegroundColor Green
        
        Write-Host "[1/6] 检查Docker状态..." -ForegroundColor Cyan
        try {
            docker --version
            docker info | Select-String "Server Version", "Kernel Version", "Operating System"
        } catch {
            Write-Host "❌ Docker未运行" -ForegroundColor Red
        }
        
        Write-Host "[2/6] 检查Docker Compose状态..." -ForegroundColor Cyan
        try {
            docker-compose --version
        } catch {
            Write-Host "❌ Docker Compose未安装" -ForegroundColor Red
        }
        
        Write-Host "[3/6] 检查服务状态..." -ForegroundColor Cyan
        try {
            docker-compose ps
        } catch {
            Write-Host "❌ 服务未部署" -ForegroundColor Red
        }
        
        Write-Host "[4/6] 检查端口占用..." -ForegroundColor Cyan
        try {
            netstat -ano | Select-String ":8888"
        } catch {
            Write-Host "❌ 端口检查失败" -ForegroundColor Red
        }
        
        Write-Host "[5/6] 检查环境变量..." -ForegroundColor Cyan
        if (Test-Path ".env") {
            Write-Host "✅ 环境变量文件存在" -ForegroundColor Green
        } else {
            Write-Host "❌ 环境变量文件不存在" -ForegroundColor Red
        }
        
        Write-Host "[6/6] 检查配置文件..." -ForegroundColor Cyan
        $configFiles = @("docker-compose.yml", "nginx/nginx.conf", "nginx/conf.d/default.conf")
        foreach ($file in $configFiles) {
            if (Test-Path $file) {
                Write-Host "✅ $file 存在" -ForegroundColor Green
            } else {
                Write-Host "❌ $file 不存在" -ForegroundColor Red
            }
        }
    }
    
    "backup" {
        Write-Host "[命令] 创建备份..." -ForegroundColor Green
        try {
            $backupDir = "$deployDir\backups"
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            
            $backupName = "coze-backup-$(Get-Date -Format "yyyyMMddHHmmss")"
            $backupFile = "$backupDir\$backupName.zip"
            
            Write-Host "停止服务以创建备份..." -ForegroundColor Cyan
            docker-compose down
            
            Write-Host "创建配置文件备份..." -ForegroundColor Cyan
            Compress-Archive -Path ".env", "docker-compose.yml", "nginx", "volumes" -DestinationPath $backupFile -Force
            
            Write-Host "启动服务..." -ForegroundColor Cyan
            docker-compose up -d
            
            Write-Host "✅ 备份创建成功: $backupFile" -ForegroundColor Green
        } catch {
            Write-Host "❌ 备份失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "restore" {
        Write-Host "[命令] 恢复备份..." -ForegroundColor Green
        try {
            $backupDir = "$deployDir\backups"
            if (-not (Test-Path $backupDir)) {
                Write-Host "❌ 备份目录不存在" -ForegroundColor Red
                exit 1
            }
            
            $backups = Get-ChildItem -Path $backupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
            if ($backups.Count -eq 0) {
                Write-Host "❌ 没有找到备份文件" -ForegroundColor Red
                exit 1
            }
            
            Write-Host "可用备份:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $backups.Count; $i++) {
                Write-Host "$($i+1). $($backups[$i].Name)"
            }
            
            $choice = Read-Host "请选择要恢复的备份编号"
            $backupIndex = [int]$choice - 1
            if ($backupIndex -ge 0 -and $backupIndex -lt $backups.Count) {
                $backupFile = $backups[$backupIndex].FullName
                
                Write-Host "停止服务..." -ForegroundColor Cyan
                docker-compose down
                
                Write-Host "恢复备份..." -ForegroundColor Cyan
                Expand-Archive -Path $backupFile -DestinationPath $deployDir -Force
                
                Write-Host "启动服务..." -ForegroundColor Cyan
                docker-compose up -d
                
                Write-Host "✅ 备份恢复成功: $($backups[$backupIndex].Name)" -ForegroundColor Green
            } else {
                Write-Host "无效选择" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ 恢复失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "update" {
        Write-Host "[命令] 检查更新..." -ForegroundColor Green
        try {
            Write-Host "检查Docker镜像更新..." -ForegroundColor Cyan
            docker-compose pull
            Write-Host "✅ 更新检查完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 更新检查失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "upgrade" {
        Write-Host "[命令] 升级服务..." -ForegroundColor Green
        try {
            Write-Host "停止服务..." -ForegroundColor Cyan
            docker-compose down
            
            Write-Host "拉取最新镜像..." -ForegroundColor Cyan
            docker-compose pull
            
            Write-Host "启动服务..." -ForegroundColor Cyan
            docker-compose up -d
            
            Write-Host "✅ 服务升级完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 升级失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "cleanup" {
        Write-Host "[命令] 清理服务..." -ForegroundColor Green
        try {
            Write-Host "停止并删除服务..." -ForegroundColor Cyan
            docker-compose down -v
            
            Write-Host "清理Docker缓存..." -ForegroundColor Cyan
            docker system prune -f
            docker volume prune -f
            
            Write-Host "✅ 服务清理完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 清理失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "help" {
        Write-Host "=====================================================" -ForegroundColor Green
        Write-Host "📋 Coze Studio 管理工具" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Green
        Write-Host "使用方法: .\manage-coze.ps1 <命令>" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Green
        Write-Host "命令列表:" -ForegroundColor Cyan
        Write-Host "  start       - 启动所有服务" -ForegroundColor Yellow
        Write-Host "  stop        - 停止所有服务" -ForegroundColor Yellow
        Write-Host "  restart     - 重启所有服务" -ForegroundColor Yellow
        Write-Host "  status      - 查看服务状态" -ForegroundColor Yellow
        Write-Host "  logs        - 查看服务日志" -ForegroundColor Yellow
        Write-Host "  check       - 检查环境配置" -ForegroundColor Yellow
        Write-Host "  backup      - 创建备份" -ForegroundColor Yellow
        Write-Host "  restore     - 恢复备份" -ForegroundColor Yellow
        Write-Host "  update      - 检查更新" -ForegroundColor Yellow
        Write-Host "  upgrade     - 升级服务" -ForegroundColor Yellow
        Write-Host "  cleanup     - 清理服务" -ForegroundColor Yellow
        Write-Host "  help        - 显示此帮助" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Green
    }
    
    default {
        Write-Host "无效命令: $command" -ForegroundColor Red
        Write-Host "使用 help 查看可用命令" -ForegroundColor Yellow
    }
}

Set-Location $PSScriptRoot
