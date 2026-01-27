# Read the test workflow file
$filePath = ".github/workflows/test-error-workflow.yml"
$content = Get-Content -Path $filePath -Raw

Write-Host "Original content:
$content"
Write-Host "\n" + "="*50 + "\n"

# Fix the environment expression
$fixedContent = $content -replace 'environment: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*\|\|\s*[^\}]+)\s*\}\}', 'environment: ${{ github.event_name == "workflow_dispatch" && \1 }}'

# Fix the if expression
$fixedContent = $fixedContent -replace 'if: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*(==|!=|<=|>=|<|>|&&|\|\|)[^\}]+)\s*\}\}', 'if: ${{ github.event_name == "workflow_dispatch" && \1 }}'

Write-Host "Fixed content:
$fixedContent"
Write-Host "\n" + "="*50 + "\n"

# Write back the fixed content
if ($fixedContent -ne $content) {
    Set-Content -Path $filePath -Value $fixedContent -NoNewline
    Write-Host "✅ Successfully fixed the workflow file"
} else {
    Write-Host "ℹ No changes needed"
}
