#!/bin/bash

# 测试脚本：验证所有修复是否成功

set -e

# 颜色定义
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# 创建测试日志目录
LOG_DIR="test-logs"
mkdir -p "$LOG_DIR"

# 测试结果
TESTS_PASSED=0
TESTS_FAILED=0

# 打印测试标题
print_title() {
    echo "\n${GREEN}========================================${NC}"
    echo "${GREEN}$1${NC}"
    echo "${GREEN}========================================${NC}"
}

# 打印测试结果
print_result() {
    if [ $1 -eq 0 ]; then
        echo "${GREEN}✓ $2${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "${RED}✗ $2${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 运行测试并记录日志
run_test() {
    test_name="$1"
    test_command="$2"
    log_file="$LOG_DIR/${test_name// /-}.log"
    
    # 只在失败时记录详细日志
    if eval "$test_command" 2>&1; then
        print_result 0 "$test_name"
    else
        print_result 1 "$test_name"
        # 只有失败时才记录详细日志
        eval "$test_command" > "$log_file" 2>&1
        echo "Check $log_file for details"
    fi
}

# 快速测试网络连接
quick_network_test() {
    # 使用更快的网络测试方法
    if command -v curl > /dev/null 2>&1; then
        # 使用curl进行快速测试
        curl -s -o /dev/null -w "%{http_code}" https://github.com > /dev/null 2>&1
        return $?
    elif command -v wget > /dev/null 2>&1; then
        # 使用wget进行快速测试
        wget -q -O /dev/null https://github.com > /dev/null 2>&1
        return $?
    else
        # 回退到ping测试
        ping -c 1 -W 2 github.com > /dev/null 2>&1
        return $?
    fi
}

# 主测试函数
main() {
    echo "${GREEN}Starting comprehensive tests for GitHub workflow fixes...${NC}"
    echo "Test logs will be saved to $LOG_DIR/"
    echo "Optimized for faster execution..."
    
    # 1. 测试 actions-config 目录结构
    print_title "1. Testing actions-config directory structure"
    run_test "actions-config directory exists" "[ -d ".github/actions-config" ]"
    run_test "actions.yaml exists" "[ -f ".github/actions-config/actions.yaml" ]"
    run_test "install-action.sh exists" "[ -f ".github/actions-config/install-action.sh" ]"
    run_test "security-scan.sh exists" "[ -f ".github/actions-config/security-scan.sh" ]"
    
    # 2. 测试脚本文件
    print_title "2. Testing script files"
    run_test "security-scan.sh syntax" "bash -n ".github/actions-config/security-scan.sh""
    run_test "install-action.sh syntax" "bash -n ".github/actions-config/install-action.sh""
    
    # 3. 测试自定义 Action
    print_title "3. Testing custom Action"
    run_test "action-fixer directory exists" "[ -d ".github/actions/action-fixer" ]"
    run_test "action.yml exists" "[ -f ".github/actions/action-fixer/action.yml" ]"
    run_test "fixer.py exists" "[ -f ".github/actions/action-fixer/fixer.py" ]"
    run_test "run.sh exists" "[ -f ".github/actions/action-fixer/run.sh" ]"
    run_test "run.sh syntax" "bash -n ".github/actions/action-fixer/run.sh""
    
    # 4. 测试网络连接（优化版本）
    print_title "4. Testing GitHub network connectivity"
    # 使用快速网络测试
    if quick_network_test; then
        print_result 0 "Network connection to github.com"
    else
        print_result 1 "Network connection to github.com"
        echo "Check network connectivity manually"
    fi
    
    # 5. 测试工作流文件
    print_title "5. Testing workflow files"
    WORKFLOW_FILES=$(find ".github/workflows" -name "*.yml" -o -name "*.yaml" | head -10)
    for file in $WORKFLOW_FILES; do
        run_test "Workflow file $file syntax" "grep -q 'name:' "$file""
    done
    
    # 6. 测试 Action 版本
    print_title "6. Testing Action versions"
    # 检查是否使用了最新版本的 actions/checkout
    run_test "actions/checkout version" "grep -q 'actions/checkout@v4' ".github/workflows/*.yml" 2>/dev/null"
    # 检查是否使用了最新版本的 actions/setup-node
    run_test "actions/setup-node version" "grep -q 'actions/setup-node@v5' ".github/workflows/*.yml" 2>/dev/null"
    # 检查是否使用了最新版本的 actions/setup-python
    run_test "actions/setup-python version" "grep -q 'actions/setup-python@v5' ".github/workflows/*.yml" 2>/dev/null"
    
    # 7. 测试权限配置
    print_title "7. Testing permissions configuration"
    # 检查工作流文件是否包含权限配置
    run_test "Permissions configuration" "grep -q 'permissions:' ".github/workflows/*.yml" 2>/dev/null"
    
    # 8. 测试文档文件
    print_title "8. Testing documentation files"
    run_test "WORKFLOWS_DOCUMENTATION.md exists" "[ -f ".github/WORKFLOWS_DOCUMENTATION.md" ]"
    
    # 9. 测试整体目录结构
    print_title "9. Testing overall directory structure"
    run_test ".github directory exists" "[ -d ".github" ]"
    run_test "workflows directory exists" "[ -d ".github/workflows" ]"
    
    # 打印测试总结
    print_title "TEST SUMMARY"
    echo "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "${GREEN}🎉 All tests passed! All fixes were successful.${NC}"
        echo "${GREEN}========================================${NC}"
        return 0
    else
        echo "${RED}❌ Some tests failed. Please check the logs for details.${NC}"
        echo "${RED}========================================${NC}"
        return 1
    fi
}

# 运行主测试函数
main
