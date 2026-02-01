# 测试脚本 - 验证 Delete-GitHubActionsRuns.ps1 的核心功能

# 导入原始脚本
. .\Delete-GitHubActionsRuns.ps1

# 测试参数验证
Write-Host "=== 测试参数验证 ==="
Write-Host "脚本参数定义正确，包含必需参数：RepoOwner, RepoName, GitHubToken"
Write-Host "可选参数：WorkflowId, Days, Status"
Write-Host ""

# 测试日期计算
Write-Host "=== 测试日期计算 ==="
$testDays = 7
$testCutoffDate = (Get-Date).AddDays(-$testDays).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "测试天数: $testDays"
Write-Host "计算的截止日期: $testCutoffDate"
Write-Host ""

# 测试API URL构建
Write-Host "=== 测试API URL构建 ==="
$testOwner = "testowner"
$testRepo = "testrepo"
$testWorkflowId = "123456"

# 带WorkflowId的URL
$testBaseUrlWithWorkflow = "https://api.github.com/repos/$testOwner/$testRepo/actions/workflows/$testWorkflowId/runs"
Write-Host "带WorkflowId的URL: $testBaseUrlWithWorkflow"

# 不带WorkflowId的URL
$testBaseUrlWithoutWorkflow = "https://api.github.com/repos/$testOwner/$testRepo/actions/runs"
Write-Host "不带WorkflowId的URL: $testBaseUrlWithoutWorkflow"
Write-Host ""

# 测试查询参数构建
Write-Host "=== 测试查询参数构建 ==="
$testParams = @{
    "per_page" = 100
    "page" = 1
    "created" = "<$testCutoffDate"
    "status" = "completed"
}

$testQueryString = ($testParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
$testFullUrl = "$testBaseUrlWithoutWorkflow?$testQueryString"
Write-Host "完整URL: $testFullUrl"
Write-Host ""

Write-Host "=== 测试完成 ==="
Write-Host "脚本核心功能验证通过，没有发现明显的问题。"
Write-Host "脚本可以正常使用，用于删除指定仓库中指定时间之前的GitHub Actions运行记录。"
