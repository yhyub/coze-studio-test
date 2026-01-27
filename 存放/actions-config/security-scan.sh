#!/bin/bash

# GitHub Action 安全扫描脚本
# 用于检查GitHub Actions的安全状态

set -e

# 配置文件路径 - 支持本地和云端两种模式
# 本地模式: CONFIG_FILE="actions.yaml"
# 云端模式: CONFIG_FILE="https://github.com/yhyub/coze-studio-test/blob/main/%E5%AD%98%E6%94%BE/actions-config/actions.yaml"
CONFIG_FILE="https://github.com/yhyub/coze-studio-test/blob/main/%E5%AD%98%E6%94%BE/actions-config/actions.yaml"

# 日志文件路径
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/security-scan-$(date +%Y-%m-%d_%H-%M-%S).log"

# 显示帮助信息
show_help() {
    echo "GitHub Action 安全扫描脚本"
    echo "用于检查GitHub Actions的安全状态"
    echo ""
    echo "用法: ./security-scan.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -v, --verbose       显示详细输出"
    echo "  -a, --action        只扫描指定的Action"
    echo "  -l, --log           保存扫描结果到日志文件"
    echo ""
    echo "示例:"
    echo "  ./security-scan.sh                # 扫描所有Action"
    echo "  ./security-scan.sh -a actions/checkout # 只扫描指定Action"
    echo "  ./security-scan.sh -v -l          # 显示详细输出并保存日志"
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -v|--verbose)
                VERBOSE=true
                shift 1
                ;;
            -a|--action)
                TARGET_ACTION=$2
                shift 2
                ;;
            -l|--log)
                LOG=true
                shift 1
                ;;
            *)
                echo "错误: 未知参数 '$1'"
                show_help
                ;;
        esac
    done

    # 设置默认值
    if [[ -z $VERBOSE ]]; then
        VERBOSE=false
    fi
    if [[ -z $LOG ]]; then
        LOG=false
    fi
    if [[ -z $TARGET_ACTION ]]; then
        TARGET_ACTION=""
    fi

    # 创建日志目录
    if [[ $LOG == true && ! -d $LOG_DIR ]]; then
        mkdir -p $LOG_DIR
    fi
}

# 记录日志
log() {
    local message=$1
    local level=${2:-info}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # 输出到控制台
    if [[ $VERBOSE == true || $level == "error" || $level == "warn" ]]; then
        case $level in
            error)
                echo -e "\033[31m[$timestamp] ERROR: $message\033[0m"
                ;;
            warn)
                echo -e "\033[33m[$timestamp] WARN: $message\033[0m"
                ;;
            info)
                echo -e "\033[32m[$timestamp] INFO: $message\033[0m"
                ;;
            debug)
                if [[ $VERBOSE == true ]]; then
                    echo -e "\033[34m[$timestamp] DEBUG: $message\033[0m"
                fi
                ;;
        esac
    fi
    
    # 输出到日志文件
    if [[ $LOG == true ]]; then
        echo "[$timestamp] $level: $message" >> $LOG_FILE
    fi
}

# 检查Action是否使用固定版本
check_fixed_version() {
    local action_name=$1
    local version=$2
    
    if [[ $version == "master" || $version == "latest" || $version == "HEAD" ]]; then
        log "Action '$action_name' 使用动态版本 '$version'，建议使用固定版本" warn
        return 1
    else
        log "Action '$action_name' 使用固定版本 '$version'" debug
        return 0
    fi
}

# 检查Action来源是否合法
check_source() {
    local action_name=$1
    local source=$2
    
    # 从配置文件中获取允许的来源
    if [[ "$CONFIG_FILE" == http* ]]; then
        # 云端模式: 直接从云端获取允许的来源
        local allowed_sources=$(curl -s "$RAW_CONFIG_URL" | grep -A 10 "allowed_sources" | grep -v "allowed_sources" | grep -v "^")
    else
        # 本地模式: 从本地文件获取允许的来源
        local allowed_sources=$(grep -A 10 "allowed_sources" $CONFIG_FILE | grep -v "allowed_sources" | grep -v "^")
    fi
    
    if echo "$allowed_sources" | grep -q "$source"; then
        log "Action '$action_name' 来源 '$source' 合法" debug
        return 0
    else
        log "Action '$action_name' 来源 '$source' 不合法，不在允许列表中" error
        return 1
    fi
}

# 扫描单个Action
scan_action() {
    local action_name=$1
    local version=$2
    local source=$3
    local usage=$4
    local security=$5
    local workflows=$6
    
    log "开始扫描Action: $action_name@$version" info
    
    local scan_result=0
    
    # 检查是否使用固定版本
    if ! check_fixed_version "$action_name" "$version"; then
        scan_result=1
    fi
    
    # 检查来源是否合法
    if ! check_source "$action_name" "$source"; then
        scan_result=1
    fi
    
    # 检查安全状态
    if [[ $security == "待审核" ]]; then
        log "Action '$action_name' 安全状态为 '待审核'，建议尽快审核" warn
        scan_result=1
    elif [[ $security == "已审核" ]]; then
        log "Action '$action_name' 安全状态为 '已审核'" debug
    else
        log "Action '$action_name' 安全状态 '$security' 未知" error
        scan_result=1
    fi
    
    # 检查工作流使用情况
    if [[ $workflows == "[]" ]]; then
        log "Action '$action_name' 未在任何工作流中使用" warn
    else
        log "Action '$action_name' 在工作流中使用: $workflows" debug
    fi
    
    if [[ $scan_result == 0 ]]; then
        log "Action '$action_name@$version' 扫描通过" info
    else
        log "Action '$action_name@$version' 扫描失败，存在安全问题" error
    fi
    
    return $scan_result
}

# 从配置文件中读取Actions并扫描
scan_from_config() {
    log "从配置文件中读取Actions..." info
    
    # 检查配置文件是本地文件还是云端URL
    if [[ "$CONFIG_FILE" == http* ]]; then
        # 云端模式: 下载配置文件到临时文件
        log "使用云端配置文件: $CONFIG_FILE" debug
        RAW_CONFIG_URL=$(echo "$CONFIG_FILE" | sed 's|github.com|raw.githubusercontent.com|; s|/blob||')
        TEMP_CONFIG=$(mktemp)
        if ! curl -s "$RAW_CONFIG_URL" -o "$TEMP_CONFIG"; then
            log "无法下载配置文件: $RAW_CONFIG_URL" error
            exit 1
        fi
        WORKING_CONFIG="$TEMP_CONFIG"
    else
        # 本地模式: 直接使用本地文件
        log "使用本地配置文件: $CONFIG_FILE" debug
        if [[ ! -f "$CONFIG_FILE" ]]; then
            log "配置文件不存在: $CONFIG_FILE" error
            exit 1
        fi
        WORKING_CONFIG="$CONFIG_FILE"
    fi
    
    # 使用yq工具解析YAML文件（如果可用）
    if command -v yq &> /dev/null; then
        scan_with_yq "$WORKING_CONFIG"
    else
        log "yq工具未安装，使用grep/sed解析YAML文件" warn
        scan_with_grep_sed "$WORKING_CONFIG"
    fi
    
    # 清理临时文件（如果是云端模式）
    if [[ "$CONFIG_FILE" == http* ]]; then
        rm -f "$TEMP_CONFIG"
    fi
}

# 使用yq工具扫描Actions
scan_with_yq() {
    local temp_config=$1
    local actions_count=$(yq eval '.installed_actions | length' $temp_config)
    log "找到 $actions_count 个已安装的Actions" info
    
    local failed_count=0
    
    for ((i=0; i<$actions_count; i++)); do
        local action_name=$(yq eval ".installed_actions[$i].name" $temp_config)
        local version=$(yq eval ".installed_actions[$i].version" $temp_config)
        local source=$(yq eval ".installed_actions[$i].source" $temp_config)
        local usage=$(yq eval ".installed_actions[$i].usage" $temp_config)
        local security=$(yq eval ".installed_actions[$i].security" $temp_config)
        local workflows=$(yq eval ".installed_actions[$i].workflows" $temp_config)
        
        # 如果指定了目标Action，只扫描该Action
        if [[ -n $TARGET_ACTION && $action_name != $TARGET_ACTION ]]; then
            continue
        fi
        
        if ! scan_action "$action_name" "$version" "$source" "$usage" "$security" "$workflows"; then
            failed_count=$((failed_count+1))
        fi
    done
    
    log "扫描完成，共 $actions_count 个Actions，其中 $failed_count 个存在安全问题" info
    
    if [[ $failed_count -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 使用grep/sed工具扫描Actions
scan_with_grep_sed() {
    local temp_config=$1
    # 读取配置文件中的installed_actions部分
    local actions_content=$(grep -A 100 "installed_actions:" $temp_config | grep -v "installed_actions:" | grep -B 100 "custom_actions:" | grep -v "custom_actions:")
    
    # 将Actions内容分割成单个Action
    local IFS=$'\n'
    local action_lines=($actions_content)
    local current_action=""
    local action_count=0
    local failed_count=0
    
    for line in "${action_lines[@]}"; do
        if [[ $line =~ ^\s*-\s*name: ]]; then
            # 如果已经有当前Action，先扫描它
            if [[ -n $current_action ]]; then
                action_count=$((action_count+1))
                # 解析Action配置
                local action_name=$(echo "$current_action" | grep "name:" | awk '{print $2}')
                local version=$(echo "$current_action" | grep "version:" | awk '{print $2}')
                local source=$(echo "$current_action" | grep "source:" | awk '{print $2}')
                local usage=$(echo "$current_action" | grep "usage:" | cut -d ' ' -f 2-)
                local security=$(echo "$current_action" | grep "security:" | awk '{print $2}')
                local workflows=$(echo "$current_action" | grep "workflows:" | cut -d ' ' -f 2-)
                
                # 如果指定了目标Action，只扫描该Action
                if [[ -z $TARGET_ACTION || $action_name == $TARGET_ACTION ]]; then
                    if ! scan_action "$action_name" "$version" "$source" "$usage" "$security" "$workflows"; then
                        failed_count=$((failed_count+1))
                    fi
                fi
            fi
            # 开始新的Action
            current_action="$line"
        elif [[ -n $current_action ]]; then
            # 添加到当前Action
            current_action="$current_action\n$line"
        fi
    done
    
    # 扫描最后一个Action
    if [[ -n $current_action ]]; then
        action_count=$((action_count+1))
        # 解析Action配置
        local action_name=$(echo "$current_action" | grep "name:" | awk '{print $2}')
        local version=$(echo "$current_action" | grep "version:" | awk '{print $2}')
        local source=$(echo "$current_action" | grep "source:" | awk '{print $2}')
        local usage=$(echo "$current_action" | grep "usage:" | cut -d ' ' -f 2-)
        local security=$(echo "$current_action" | grep "security:" | awk '{print $2}')
        local workflows=$(echo "$current_action" | grep "workflows:" | cut -d ' ' -f 2-)
        
        # 如果指定了目标Action，只扫描该Action
        if [[ -z $TARGET_ACTION || $action_name == $TARGET_ACTION ]]; then
            if ! scan_action "$action_name" "$version" "$source" "$usage" "$security" "$workflows"; then
                failed_count=$((failed_count+1))
            fi
        fi
    fi
    
    log "扫描完成，共 $action_count 个Actions，其中 $failed_count 个存在安全问题" info
    
    if [[ $failed_count -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 主函数
main() {
    parse_args "$@"
    log "开始GitHub Action安全扫描" info
    
    scan_from_config
    local scan_result=$?
    
    if [[ $scan_result == 0 ]]; then
        log "所有Action扫描通过，安全状态良好" info
    else
        log "部分Action扫描失败，存在安全问题，请查看日志或详细输出" error
    fi
    
    log "GitHub Action安全扫描结束" info
    
    exit $scan_result
}

# 执行主函数
main "$@"
