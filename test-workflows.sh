#!/bin/bash

# 测试脚本：验证工作流文件的关键步骤

echo "========================================"
echo "Testing GitHub Workflows..."
echo "========================================"

# 创建测试日志目录
mkdir -p test-logs

# 测试 1: 验证 actions-config 目录结构
echo "\n1. Testing actions-config directory structure..."
if [ -d ".github/actions-config" ]; then
    echo "✓ .github/actions-config directory exists"
    
    if [ -f ".github/actions-config/actions.yaml" ]; then
        echo "✓ .github/actions-config/actions.yaml exists"
    else
        echo "✗ .github/actions-config/actions.yaml missing"
    fi
    
    if [ -f ".github/actions-config/install-action.sh" ]; then
        echo "✓ .github/actions-config/install-action.sh exists"
    else
        echo "✗ .github/actions-config/install-action.sh missing"
    fi
    
    if [ -f ".github/actions-config/security-scan.sh" ]; then
        echo "✓ .github/actions-config/security-scan.sh exists"
    else
        echo "✗ .github/actions-config/security-scan.sh missing"
    fi
else
    echo "✗ .github/actions-config directory missing"
fi

# 测试 2: 验证安全扫描脚本
echo "\n2. Testing security scan script..."
if [ -f ".github/actions-config/security-scan.sh" ]; then
    echo "Testing security-scan.sh script..."
    cd .github/actions-config
    # 创建日志目录
    mkdir -p logs
    # 测试脚本语法
    if bash -n security-scan.sh; then
        echo "✓ security-scan.sh syntax is valid"
    else
        echo "✗ security-scan.sh syntax error"
    fi
    # 测试脚本运行
    CONFIG_FILE="actions.yaml" bash security-scan.sh -v -l > ../../test-logs/security-scan-test.log 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ security-scan.sh runs successfully"
    else
        echo "⚠ security-scan.sh ran with errors (check test-logs/security-scan-test.log)"
    fi
    cd ../..
else
    echo "✗ security-scan.sh not found"
fi

# 测试 3: 验证安装脚本
echo "\n3. Testing install-action script..."
if [ -f ".github/actions-config/install-action.sh" ]; then
    echo "Testing install-action.sh script..."
    cd .github/actions-config
    # 测试脚本语法
    if bash -n install-action.sh; then
        echo "✓ install-action.sh syntax is valid"
    else
        echo "✗ install-action.sh syntax error"
    fi
    cd ../..
else
    echo "✗ install-action.sh not found"
fi

# 测试 4: 验证配置文件格式
echo "\n4. Testing configuration file format..."
if [ -f ".github/actions-config/actions.yaml" ]; then
    echo "Testing actions.yaml format..."
    # 测试 YAML 格式
    if python -c "import yaml; yaml.safe_load(open('.github/actions-config/actions.yaml'))"; then
        echo "✓ actions.yaml is valid YAML"
    else
        echo "✗ actions.yaml is invalid YAML"
    fi
else
    echo "✗ actions.yaml not found"
fi

# 测试 5: 验证工作流文件格式
echo "\n5. Testing workflow files format..."
workflow_files=".github/workflows/*.yml"
for file in $workflow_files; do
    if [ -f "$file" ]; then
        echo "Testing $file..."
        # 测试 YAML 格式
        if python -c "import yaml; yaml.safe_load(open('$file'))"; then
            echo "  ✓ $file is valid YAML"
        else
            echo "  ✗ $file is invalid YAML"
        fi
    fi
done

echo "\n========================================"
echo "Test completed!"
echo "Check test-logs directory for detailed logs."
echo "========================================"
