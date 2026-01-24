# Script to fix invalid repository name "coze-studio测试" to "coze-studio"

Write-Host "Starting repository name fix..."

# Define the invalid and valid repository names
$invalidName = "coze-studio测试"
$validName = "coze-studio"

# Get the current directory
$currentDir = Get-Location

# Step