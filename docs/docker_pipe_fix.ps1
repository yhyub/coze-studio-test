# Docker Desktop Named Pipe Fix

# Stop all Docker processes
$processes = @("Docker Desktop", "com.docker.backend", "dockerd", "docker")
foreach ($p in $processes) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Stop Docker service
Stop-Service com.docker.service -Force -ErrorAction SilentlyContinue

# Wait 5 seconds
Start-Sleep -Seconds 5

# Start Docker service
Start-Service com.docker.service

# Wait 10 seconds
Start-Sleep -Seconds 10

# Start Docker Desktop
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Start-Process -FilePath $dockerPath
}