param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# 配置信息
$repoOwner = "yhyub"
$repoName = "coze-studio-test"
$days = 30

# 设置HTTP请求头
$headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
}

# 计算截止日期
$cutoffDate = (Get-Date).AddDays(-$days).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# 基本URL
$baseUrl = "https://api.github.com/repos/$repoOwner/$repoName/actions/runs"

$runsDeleted = 0
$page = 1

Write-Host "开始删除GitHub Actions运行记录..."
Write-Host "仓库: $repoOwner/$repoName"
Write-Host "截止日期: $cutoffDate"
Write-Host ""

while ($true) {
    # 构建URL（简化版本）
    $url = "$baseUrl?per_page=100&page=$page&created=<$cutoffDate"
    
    try {
        # 发送请求获取运行记录
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        
        if ($response.workflow_runs.Count -eq 0) {
            Write-Host "没有更多运行记录需要删除。"
            break
        }
        
        # 遍历运行记录并删除
        foreach ($run in $response.workflow_runs) {
            $runId = $run.id
            $runName = $run.name
            $runStatus = $run.status
            $runCreated = $run.created_at
            $workflowName = $run.workflow_name
            
            Write-Host "删除运行记录: $runName (ID: $runId, 状态: $runStatus, 工作流: $workflowName, 创建时间: $runCreated)"
            
            # 删除运行记录
            $deleteUrl = "https://api.github.com/repos/$repoOwner/$repoName/actions/runs/$runId"
            
            try {
                $deleteResponse = Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete
                Write-Host "  ✅ 成功删除运行记录 $runId"
                $runsDeleted++
                
                # 避免API速率限制
                Start-Sleep -Milliseconds 500
            } catch {
                Write-Host "  ❌ 删除失败: $($_.Exception.Message)"
            }
        }
        
        $page++
    } catch {
        Write-Host "  ❌ 获取运行记录失败: $($_.Exception.Message)"
        break
    }
}

Write-Host ""
Write-Host "删除完成，共删除 $runsDeleted 条运行记录"
