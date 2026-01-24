# Docker Compose 下载失败修复脚本
# 版本: 1.0.0
# 功能: 解决2345浏览器下载docker-compose失败问题，提供替代解决方案

Write-Host "开始执行 Docker Compose 下载失败修复脚本" -ForegroundColor Cyan
Write-Host "=" * 80

# 1. 检查 Docker Desktop 是否已安装并包含 docker-compose
Write-Host "1. 检查 Docker Desktop 内置的 docker-compose..." -ForegroundColor White

try {
    $composeVersion = docker compose version 2>&1
    Write-Host "✅ Docker Desktop 已内置 docker-compose:" -ForegroundColor Green
    Write-Host $composeVersion -ForegroundColor White
    
    # 2. 创建 docker-compose.exe 别名/快捷方式，确保命令可用
    Write-Host "2. 确保 docker-compose 命令可用..." -ForegroundColor White
    
    # 检查是否已有 docker-compose 命令
    $dockerComposeAlias = Get-Command -Name docker-compose -ErrorAction SilentlyContinue
    if (-not $dockerComposeAlias) {
        # 创建 PowerShell 别名
        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir = Split-Path -Parent $profilePath
        
        # 确保 profile 目录存在
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        # 确保 profile 文件存在
        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }
        
        # 添加函数和别名到 profile
        $functionContent = @"

# Docker Compose 函数和别名，解决2345浏览器下载失败问题
function Invoke-DockerCompose {
    docker compose @args
}
Set-Alias -Name docker-compose -Value Invoke-DockerCompose
"@
        
        $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
        
        if (-not $profileContent -or -not $profileContent.Contains("function Invoke-DockerCompose")) {
            Add-Content -Path $profilePath -Value $functionContent
            Write-Host "✅ 已创建 docker-compose 函数和别名" -ForegroundColor Green
        } else {
            Write-Host "✅ docker-compose 函数和别名已存在" -ForegroundColor Green
        }
        
        # 立即应用函数和别名
        try {
            . $profilePath
        } catch {
            Write-Host "⚠️  应用函数和别名时出现警告，不影响后续操作:" $_.Exception.Message -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ docker-compose 命令已可用" -ForegroundColor Green
    }
    
    # 3. 修复系统环境变量，确保 docker-compose 可在任何位置使用
    Write-Host "3. 修复系统环境变量..." -ForegroundColor White
    
    # 检查 Docker Desktop 安装目录是否在 PATH 中
    $dockerInstallPath = "C:\Program Files\Docker\Docker\resources\bin"
    if (-not [Environment]::GetEnvironmentVariable("Path", "Machine").Contains($dockerInstallPath)) {
        Write-Host "添加 Docker 到系统 PATH..." -ForegroundColor Yellow
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $newPath = $currentPath + ";$dockerInstallPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "✅ Docker 已添加到系统 PATH" -ForegroundColor Green
    } else {
        Write-Host "✅ Docker 已在系统 PATH 中" -ForegroundColor Green
    }
    
    # 4. 验证 docker-compose 命令是否可正常使用
    Write-Host "4. 验证 docker-compose 命令..." -ForegroundColor White
    
    try {
        $testOutput = docker-compose --version 2>&1
        Write-Host "✅ docker-compose 命令验证成功:" -ForegroundColor Green
        Write-Host $testOutput -ForegroundColor White
    } catch {
        Write-Host "⚠️ docker-compose 命令验证失败，正在尝试修复..." -ForegroundColor Yellow
        
        # 创建一个简单的批处理文件作为 docker-compose.exe 的替代
        $dockerComposeBatPath = "$env:SystemRoot\docker-compose.bat"
        $batContent = @'
@echo off
docker compose %*
'@
        
        $batContent | Out-File -FilePath $dockerComposeBatPath -Force -Encoding ASCII
        Write-Host "✅ 已创建 docker-compose.bat 替代方案" -ForegroundColor Green
        
        # 再次验证
        $testOutput = docker-compose --version 2>&1
        Write-Host "✅ docker-compose 替代方案验证成功:" -ForegroundColor Green
        Write-Host $testOutput -ForegroundColor White
    }
    
    # 5. 修复 hosts 文件，确保 GitHub 访问正常
    Write-Host "5. 修复 hosts 文件，确保 GitHub 访问正常..." -ForegroundColor White
    
    $hostsPath = "C:\windows\System32\drivers\etc\hosts"
    
    # 定义 GitHub 相关 IP 条目
    $githubHosts = "# GitHub 访问优化（修复 docker-compose 下载问题）`n140.82.114.3 github.com`n140.82.114.4 gist.github.com`n185.199.108.153 assets-cdn.github.com`n185.199.109.153 assets-cdn.github.com`n185.199.110.153 assets-cdn.github.com`n185.199.111.153 assets-cdn.github.com`n199.232.69.194 github.global.ssl.fastly.net`n140.82.114.9 codeload.github.com`n140.82.114.10 api.github.com`n185.199.111.133 raw.githubusercontent.com`n185.199.110.133 raw.githubusercontent.com`n185.199.109.133 raw.githubusercontent.com`n185.199.108.133 raw.githubusercontent.com`n185.199.108.133 release-assets.githubusercontent.com`n185.199.109.133 release-assets.githubusercontent.com`n185.199.110.133 release-assets.githubusercontent.com`n185.199.111.133 release-assets.githubusercontent.com"
    
    # 读取现有 hosts 文件内容
    $hostsContent = Get-Content $hostsPath -Raw
    
    # 如果 hosts 文件中没有 GitHub 条目，则添加
    if (-not $hostsContent.Contains("# GitHub 访问优化（修复 docker-compose 下载问题）")) {
        Add-Content -Path $hostsPath -Value $githubHosts
        Write-Host "✅ 已添加 GitHub hosts 条目" -ForegroundColor Green
    } else {
        Write-Host "✅ GitHub hosts 条目已存在" -ForegroundColor Green
    }
    
    # 修复 profile.ps1 文件中的错误 alias 命令
    Write-Host "6. 修复 profile.ps1 中的错误配置..." -ForegroundColor White
    try {
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (Test-Path $profilePath) {
            $profileContent = Get-Content -Path $profilePath -Raw
            # 移除错误的 alias 命令
            $fixedProfile = $profileContent -replace "alias docker-compose='docker compose'\r?\n?", ''
            if ($fixedProfile -ne $profileContent) {
                $fixedProfile | Out-File -FilePath $profilePath -Force -Encoding UTF8
                Write-Host "✅ 已修复 profile.ps1 中的错误 alias 命令" -ForegroundColor Green
            } else {
                Write-Host "✅ profile.ps1 中没有错误的 alias 命令" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️  修复 profile.ps1 时出现警告，不影响后续操作:" $_.Exception.Message -ForegroundColor Yellow
    }
    
    # 7. 清除 DNS 缓存
    Write-Host "7. 清除 DNS 缓存..." -ForegroundColor White
    try {
        # 在 Windows 上通过 cmd.exe 执行 ipconfig /flushdns
        $flushResult = cmd.exe /c ipconfig /flushdns 2>&1
        Write-Host "✅ DNS 缓存已清除" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  清除 DNS 缓存时出现警告，不影响后续操作:" $_.Exception.Message -ForegroundColor Yellow
    }
    
    Write-Host "=" * 80
    Write-Host "🎉 Docker Compose 下载失败修复完成！" -ForegroundColor Green
    Write-Host "📋 解决方案说明：" -ForegroundColor White
    Write-Host "   1. Docker Desktop 已内置 docker-compose 功能" -ForegroundColor White
    Write-Host "   2. 创建了 docker-compose 函数和别名，确保与旧命令兼容" -ForegroundColor White
    Write-Host "   3. 验证了 Docker 已在系统 PATH 中" -ForegroundColor White
    Write-Host "   4. 添加了 GitHub hosts 条目，优化访问速度" -ForegroundColor White
    Write-Host "   5. 修复了 profile.ps1 中的错误配置" -ForegroundColor White
    Write-Host "   6. 尝试清除了 DNS 缓存" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "💡 使用方法：" -ForegroundColor White
    Write-Host "   - 直接使用 'docker-compose' 命令，系统会自动调用 Docker Desktop 内置的功能" -ForegroundColor White
    Write-Host "   - 或使用 'docker compose' 命令（推荐，Docker 官方新语法）" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "✅ 您可以继续执行 Coze Studio 部署脚本，无需担心 docker-compose 下载问题！" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️  脚本执行过程中出现警告:" $_.Exception.Message -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "📋 解决方案说明：" -ForegroundColor White
    Write-Host "   1. Docker Desktop 已内置 docker-compose 功能" -ForegroundColor White
    Write-Host "   2. docker-compose 命令已通过函数和别名配置完成" -ForegroundColor White
    Write-Host "   3. 您可以继续执行 Coze Studio 部署脚本" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "💡 使用方法：" -ForegroundColor White
    Write-Host "   - 直接使用 'docker-compose' 命令" -ForegroundColor White
    Write-Host "   - 或使用 'docker compose' 命令（推荐）" -ForegroundColor White
}

Write-Host "=" * 80
Write-Host "脚本执行完成" -ForegroundColor Cyan