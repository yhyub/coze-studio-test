# PowerShell脚本：验证YAML文件语法

function Validate-YamlFile {
    param(
        [string]$FilePath
    )
    
    try {
        # 使用PowerShell内置的ConvertFrom-Yaml cmdlet
        $content = Get-Content -Path $FilePath -Raw
        $null = ConvertFrom-Yaml -InputObject $content -AllDocuments
        return $true, $null
    } catch {
        return $false, $_.Exception.Message
    }
}

# 检查是否安装了YAML模块
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "⚠ 未安装powershell-yaml模块，尝试安装..."
    try {
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force -SkipPublisherCheck
        Import-Module powershell-yaml
        Write-Host "✅ powershell-yaml模块安装成功！"
    } catch {
        Write-Host "❌ 无法安装powershell-yaml模块，请手动安装或检查网络连接"
        exit 1
    }
}

# 验证所有工作流文件
$workflowsDir = ".github/workflows"
Write-Host "开始验证 $workflowsDir 目录下的所有YAML文件...\n"

$allValid = $true
$filesChecked = 0
$validFiles = 0
$invalidFiles = 0

# 获取所有YAML文件
Get-ChildItem -Path $workflowsDir -Filter "*.yml" -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $filesChecked++
    
    Write-Host "🔍 检查文件: $filePath"
    $isValid, $errorMsg = Validate-YamlFile -FilePath $filePath
    
    if ($isValid) {
        Write-Host "✅ 文件 $($_.Name) 语法正确\n"
        $validFiles++
    } else {
        Write-Host "❌ 文件 $($_.Name) 语法错误: $errorMsg\n"
        $invalidFiles++
        $allValid = $false
    }
}

Get-ChildItem -Path $workflowsDir -Filter "*.yaml" -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $filesChecked++
    
    Write-Host "🔍 检查文件: $filePath"
    $isValid, $errorMsg = Validate-YamlFile -FilePath $filePath
    
    if ($isValid) {
        Write-Host "✅ 文件 $($_.Name) 语法正确\n"
        $validFiles++
    } else {
        Write-Host "❌ 文件 $($_.Name) 语法错误: $errorMsg\n"
        $invalidFiles++
        $allValid = $false
    }
}

# 输出总结
Write-Host "="*60
Write-Host "验证结果总结:" -ForegroundColor Cyan
Write-Host "总检查文件数: $filesChecked" -ForegroundColor Green
Write-Host "✅ 语法正确: $validFiles" -ForegroundColor Green
Write-Host "❌ 语法错误: $invalidFiles" -ForegroundColor Red

if ($allValid) {
    Write-Host "\n🎉 所有工作流YAML文件语法正确！" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "\n❌ 存在语法错误的文件，请修复后再运行！" -ForegroundColor Red
    exit 1
}
