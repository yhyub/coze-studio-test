# PowerShell脚本：修复所有工作流文件

function Fix-WorkflowFile {
    param(
        [string]$FilePath
    )
    
    try {
        Write-Host "正在修复文件: $FilePath"
        
        # 读取文件内容
        $content = Get-Content -Path $FilePath -Raw
        
        # 修复1: 修复environment表达式
        $fixedContent = [regex]::Replace($content, 
            'environment: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*\|\|\s*[^\}]+)\s*\}\}', 
            'environment: ${{ github.event_name == "workflow_dispatch" && $1 }}')
        
        # 修复2: 修复if表达式
        $fixedContent = [regex]::Replace($fixedContent, 
            'if: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*(==|!=|<=|>=|<|>|&&|\|\|)[^\}]+)\s*\}\}', 
            'if: ${{ github.event_name == "workflow_dispatch" && $1 }}')
        
        # 修复3: 修复env表达式
        $fixedContent = [regex]::Replace($fixedContent, 
            'env:\s+([^#]+):\s*\$\{\{\s*(github\.event\.inputs\.[^\}]+)\s*\}\}', 
            'env:\n        $1: ${{ github.event_name == "workflow_dispatch" && $2 }}')
        
        # 检查是否有未修复的github.event.inputs引用
        $unfixedInputs = [regex]::Matches($fixedContent, 'github\.event\.inputs\.[^\{\}]+') | ForEach-Object { $_.Value }
        if ($unfixedInputs) {
            Write-Host "  ⚠ 发现未修复的github.event.inputs引用: $($unfixedInputs | Select-Object -Unique)"
            
            # 尝试进一步修复
            foreach ($inputRef in ($unfixedInputs | Select-Object -Unique)) {
                # 修复独立的github.event.inputs引用
                $fixedContent = $fixedContent -replace "\$\{\{$inputRef\}", "${{ github.event_name == \"workflow_dispatch\" && $inputRef }}"
            }
        }
        
        # 保存修复后的文件
        if ($fixedContent -ne $content) {
            # 创建备份
            $backupPath = "$FilePath.bak"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Host "  ✅ 创建了备份文件: $backupPath"
            
            # 写入修复后的内容
            Set-Content -Path $FilePath -Value $fixedContent -NoNewline
            Write-Host "  ✅ 成功修复了文件: $FilePath"
            return $true
        } else {
            Write-Host "  ℹ 文件无需修复: $FilePath"
            return $false
        }
            
    } catch {
        Write-Host "  ❌ 修复文件时出错: $($_.Exception.Message)"
        return $false
    }
}

# 修复所有工作流文件
Write-Host "开始修复所有工作流文件...\n"

$workflowsDir = ".github/workflows"
if (-not (Test-Path $workflowsDir)) {
    Write-Host "❌ 工作流目录 $workflowsDir 不存在"
    exit 1
}

$fixedCount = 0
$totalCount = 0

# 获取所有YAML文件
Get-ChildItem -Path $workflowsDir -Filter "*.yml" -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $totalCount++
    
    if (Fix-WorkflowFile -FilePath $filePath) {
        $fixedCount++
    }
    
    Write-Host
}

# 输出总结
Write-Host "="*60
Write-Host "修复完成！"
Write-Host "总文件数: $totalCount"
Write-Host "修复的文件数: $fixedCount"
Write-Host "无需修复的文件数: $($totalCount - $fixedCount)"
Write-Host "="*60
