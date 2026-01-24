# Direct Docker Config Fix
# Version: 1.0.0

Write-Host "=== Direct Docker Config Fix ===" -ForegroundColor Green

# 1. Remove existing config file
$dockerConfigPath = "$env:USERPROFILE\.docker\config.json"
Write-Host "1. Removing existing config file: $dockerConfigPath" -ForegroundColor Cyan
if (Test-Path $dockerConfigPath) {
    Remove-Item -Path $dockerConfigPath -Force
    Write-Host "✅ Config file removed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Config file not found" -ForegroundColor Yellow
}

# 2. Create new config file with correct format
Write-Host "`n2. Creating new config file with correct format" -ForegroundColor Cyan
$newConfig = @'
{
  "auths": {},
  "credsStore": "desktop.exe",
  "currentContext": "desktop-linux",
  "features": ""
}
'@

try {
    Set-Content -Path $dockerConfigPath -Value $newConfig -Force
    Write-Host "✅ New config file created successfully" -ForegroundColor Green
    Write-Host "Config content:" -ForegroundColor Yellow
    Write-Host $newConfig -ForegroundColor White
} catch {
    Write-Host "❌ Failed to create config file: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Start Docker services
Write-Host "`n3. Starting Docker services" -ForegroundColor Cyan
try {
    # Start Docker Desktop Service
    Start-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
    Write-Host "✅ Docker Desktop Service started" -ForegroundColor Green
    
    # Start Docker service
    Start-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    Write-Host "✅ Docker service started" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to start Docker services: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Start Docker Desktop application
Write-Host "`n4. Starting Docker Desktop application" -ForegroundColor Cyan
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
            Write-Host "✅ Docker Desktop started: $path" -ForegroundColor Green
            break
        } catch {
            Write-Host "❌ Failed to start Docker Desktop: $path" -ForegroundColor Red
        }
    }
}

if (!$dockerStarted) {
    Write-Host "❌ Docker Desktop not found" -ForegroundColor Red
}

# 5. Wait for Docker initialization
Write-Host "`n5. Waiting for Docker initialization (60 seconds)" -ForegroundColor Cyan
Start-Sleep -Seconds 60

# 6. Verify Docker status
Write-Host "`n6. Verifying Docker status" -ForegroundColor Cyan
try {
    $dockerVersion = docker version 2>&1
    if ($dockerVersion -notlike '*error*') {
        Write-Host "✅ Docker is running!" -ForegroundColor Green
        Write-Host "Docker version info:" -ForegroundColor Yellow
        Write-Host $dockerVersion -ForegroundColor White
    } else {
        Write-Host "❌ Docker is not running: $dockerVersion" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to check Docker status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Direct Docker Config Fix Completed ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run Coze Studio startup script" -ForegroundColor Yellow
Write-Host "2. Access http://localhost:8888" -ForegroundColor Yellow

Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null