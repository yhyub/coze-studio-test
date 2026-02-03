#!/bin/bash

echo "Fixing empty permissions configurations..."

# 修复所有工作流文件中的空权限配置
workflow_files=$(find .github/workflows -name "*.yml")

for file in $workflow_files; do
    if [ -f "$file" ]; then
        content=$(cat "$file")
        if echo "$content" | grep -q "permissions:\s*{}"; then
            echo "Fixing empty permissions in $file..."
            new_content=$(echo "$content" | sed 's/permissions:\s*{}/permissions:\\n  contents: read\\n  actions: read\\n  pull-requests: read\\n  checks: read\\n  deployments: read\\n  issues: read\\n  packages: read\\n  repository-projects: read\\n  security-events: read\\n  statuses: read\\n  workflows: read/')
            echo "$new_content" > "$file"
            echo "✓ Fixed empty permissions in $file"
        fi
    fi
done

echo "\nAll empty permissions configurations fixed!"
