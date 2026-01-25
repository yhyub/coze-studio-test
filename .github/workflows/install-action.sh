#!/bin/bash

# GitHub Action 安装脚本
# 用于安全地安装和管理GitHub Actions

set -e

# 配置文件路径
CONFIG_FILE="actions.yaml"

# 显示帮助信息
show_help() {
    echo "GitHub Action 安装脚本"
    echo "用于安全地安装和管理GitHub Actions"
    echo ""
    echo "用法: ./install-action.sh [选项] <action-name> <version>"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -s, --source        指定Action来源（marketplace或github.com）"
    echo "  -u, --usage         指定Action用途"
    echo "  -w, --workflow      指定使用该Action的工作流文件"
    echo "  -f, --force         强制安装，覆盖现有配置"
    echo ""
    echo "示例:"
    echo "  ./install-action.sh -s marketplace -u '用于设置Rust开发环境' -w rust-ci.yml actions/setup-rust v3"
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -s|--source)
                SOURCE=$2
                shift 2
                ;;
            -u|--usage)
                USAGE=$2
                shift 2
                ;;
            -w|--workflow)
                WORKFLOW=$2
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift 1
                ;;
            *)
                if [[ -z $ACTION_NAME ]]; then
                    ACTION_NAME=$1
                elif [[ -z $VERSION ]]; then
                    VERSION=$1
                else
                    echo "错误: 未知参数 '$1'"
                    show_help
                fi
                shift 1
                ;;
        esac
    done

    # 检查必填参数
    if [[ -z $ACTION_NAME || -z $VERSION ]]; then
        echo "错误: 缺少必填参数"
        show_help
    fi

    # 设置默认值
    if [[ -z $SOURCE ]]; then
        SOURCE="marketplace"
    fi
    if [[ -z $USAGE ]]; then
        USAGE="未指定用途"
    fi
    if [[ -z $WORKFLOW ]]; then
        WORKFLOW=""
    fi
    if [[ -z $FORCE ]]; then
        FORCE=false
    fi
}

# 检查Action是否已存在
check_existing_action() {
    local action_name=$1
    if grep -q "name: $action_name" $CONFIG_FILE; then
        echo "警告: Action '$action_name' 已存在"
        if [[ $FORCE == false ]]; then
            echo "使用 -f 或 --force 选项强制覆盖"
            exit 1
        else
            echo "使用 -f 选项，将覆盖现有配置"
        fi
        return 0
    else
        return 1
    fi
}

# 安装Action
install_action() {
    local action_name=$1
    local version=$2
    local source=$3
    local usage=$4
    local workflow=$5
    local force=$6

    # 检查Action是否已存在
    if check_existing_action "$action_name"; then
        # 如果Action已存在且使用了--force选项，先删除现有配置
        if [[ $force == true ]]; then
            # 使用sed删除现有Action配置
            sed -i "/name: $action_name/,/^  - name:/d" $CONFIG_FILE
            # 处理最后一个Action的情况
            sed -i "/name: $action_name/,/^[^ ]/d" $CONFIG_FILE
        fi
    fi

    # 构建工作流数组
    local workflow_array
    if [[ -n $workflow ]]; then
        workflow_array="[$workflow]"
    else
        workflow_array="[]"
    fi

    # 添加新Action配置
    cat >> $CONFIG_FILE << EOF
  - name: $action_name
    version: $version
    source: $source
    usage: $usage
    security: 待审核
    workflows: $workflow_array

EOF

    echo "Action '$action_name@$version' 已成功添加到配置文件中"
    echo "请运行安全审核脚本: ./security-scan.sh"
}

# 主函数
main() {
    parse_args "$@"
    install_action "$ACTION_NAME" "$VERSION" "$SOURCE" "$USAGE" "$WORKFLOW" "$FORCE"
}

# 执行主函数
main "$@"
