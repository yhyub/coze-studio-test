# Fix Docker config file format error
$dockerConfigPath = "$env:USERPROFILE\.docker\config.json"

# Remove existing config file
if (Test-Path $dockerConfigPath) {
    Remove-Item $dockerConfigPath -Force
    Write-Host "Config file removed"
}

# Create new config file with correct format
$configContent = @'
{
  "auths": {},
  "credsStore": "desktop.exe",
  "currentContext": "desktop-linux",
  "features": {},
  "experimental": false
}
'@

$configContent | Out-File -FilePath $dockerConfigPath -Encoding UTF8 -Force
Write-Host "New config file created successfully"
Write-Host "Config content:"
Write-Host $configContent

# Start Docker services
Write-Host "Starting Docker services..."
Start-Service "Docker Desktop Service" -ErrorAction SilentlyContinue
Start-Service "Docker" -ErrorAction SilentlyContinue

# Start Docker Desktop application
Write-Host "Starting Docker Desktop application..."
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktopPath) {
    Start-Process -FilePath $dockerDesktopPath -WindowStyle Normal
    Write-Host "Docker Desktop started: $dockerDesktopPath"
} else {
    Write-Host "Docker Desktop not found at $dockerDesktopPath"
}

# Wait for Docker initialization
Write-Host "Waiting for Docker initialization (30 seconds)..."
Start-Sleep -Seconds 30

# Verify Docker status
Write-Host "Verifying Docker status..."
try {
    $dockerVersion = docker version
    Write-Host "Docker is running!"
    Write-Host "Docker version info:"
    Write-Host $dockerVersion
} catch {
    Write-Host "Docker is not running properly. Please check Docker Desktop status."
}

Write-Host "=== Docker Config Fix Completed ==="