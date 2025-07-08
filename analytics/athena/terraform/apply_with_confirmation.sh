#!/bin/bash

# AWS アカウント確認付き Terraform Apply スクリプト
# このスクリプトは、terraform apply を実行する前に AWS アカウント情報を表示し、確認を求めます

set -euo pipefail

# 設定
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 出力用の色
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # カラーなし

# 関数
print_colored() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "🚀 AWS Account Validation & Terraform Apply"
    echo "=========================================="
}

show_help() {
    cat << EOF
使用法: $SCRIPT_NAME [OPTIONS]

AWSアカウント確認とガイド付き変数入力を伴うTerraform apply。

OPTIONS:
    -h, --help          このヘルプメッセージを表示
    -y, --yes           AWS確認をスキップ（注意して使用）
    -a, --auto-approve  terraform apply確認をスキップ（注意して使用）
    -q, --quiet         重要でない出力を抑制
    --                  残りの引数をterraform applyに渡す

EXAMPLES:
    $SCRIPT_NAME                    # 確認付きインタラクティブモード
    $SCRIPT_NAME --yes              # AWS確認をスキップ
    $SCRIPT_NAME --auto-approve     # terraform apply確認をスキップ
    $SCRIPT_NAME -- plan.out        # 保存された計画ファイルから適用

ENVIRONMENT VARIABLES:
    TERRAFORM_AWS_ACCOUNT_CONFIRMED=true   AWS確認をスキップ

WARNING:
    このスクリプトは、あなたのAWSインフラストラクチャに変更を加えます。
    常に変更を確認するため、最初に 'terraform plan' を実行してください。

EOF
}

check_dependencies() {
    local missing_deps=()

    for cmd in aws jq terraform; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_colored "$RED" "❌ Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies before running this script."
        exit 1
    fi
}

validate_aws_credentials() {
    print_colored "$BLUE" "Getting current AWS identity..."

    local aws_identity
    if ! aws_identity=$(aws sts get-caller-identity 2>/dev/null); then
        print_colored "$RED" "❌ Failed to get AWS identity. Please check your AWS credentials."
        echo "   Run 'aws configure' or set up your AWS credentials."
        exit 1
    fi

    echo "$aws_identity"
}

display_aws_info() {
    local aws_identity=$1

    # jqで情報を安全に抽出
    local account_id user_id arn
    account_id=$(echo "$aws_identity" | jq -r '.Account // "N/A"')
    user_id=$(echo "$aws_identity" | jq -r '.UserId // "N/A"')
    arn=$(echo "$aws_identity" | jq -r '.Arn // "N/A"')

    echo ""
    echo "Current AWS Identity Information:"
    echo "  Account ID: $account_id"
    echo "  User ID:    $user_id"
    echo "  ARN:        $arn"

    # アカウント名を取得
    local account_name
    if account_name=$(aws organizations describe-account --account-id "$account_id" --query 'Account.Name' --output text 2>/dev/null) && [ "$account_name" != "None" ]; then
        echo "  Account Name: $account_name"
    else
        echo "  Account Name: N/A (not part of organization or no permission)"
    fi

    echo "=========================================="
}

get_user_confirmation() {
    local skip_confirmation=${1:-false}

    # 環境変数をチェック
    if [ "${TERRAFORM_AWS_ACCOUNT_CONFIRMED:-}" = "true" ] || [ "$skip_confirmation" = true ]; then
        print_colored "$GREEN" "✅ AWS account confirmation skipped"
        return 0
    fi

    echo ""
    print_colored "$YELLOW" "⚠️  Please verify this is the correct AWS account!"
    print_colored "$RED" "🚨 WARNING: This will make changes to your AWS infrastructure!"
    echo ""

    while true; do
        read -p "Do you want to proceed with terraform apply? (Y/N): " -n 1 -r
        echo ""
        case $REPLY in
            [Yy]* )
                echo ""
                print_colored "$GREEN" "✅ AWS account confirmed. Proceeding with terraform apply..."
                echo "=========================================="
                echo ""
                break
                ;;
            [Nn]* )
                echo ""
                print_colored "$RED" "❌ Operation cancelled by user."
                echo "Please check your AWS credentials and try again."
                echo ""
                exit 1
                ;;
            * )
                echo "Please answer Y or N."
                ;;
        esac
    done
}

validate_input() {
    local var_name=$1
    local var_value=$2

    if [ -z "$var_value" ]; then
        return 1
    fi

    # 追加の検証パターン
    case $var_name in
        "project"|"env")
            if [[ ! $var_value =~ ^[a-zA-Z0-9_-]+$ ]]; then
                echo "   ❌ $var_name must contain only alphanumeric characters, hyphens, and underscores"
                return 1
            fi
            ;;
        "logs_s3_prefix")
            if [[ $var_value != "${var_value%/}" ]]; then
                echo "   ❌ S3 prefix should not end with '/'"
                return 1
            fi
            ;;
    esac

    return 0
}

collect_terraform_variables() {
    print_colored "$BLUE" "📝 Please provide the following variables in order:"
    echo ""

    # 1. Project
    while true; do
        read -p "1. Project name (e.g., rcs, myapp): " project
        if validate_input "project" "$project"; then
            break
        else
            echo "   Please enter a valid project name."
        fi
    done

    # 2. Environment
    while true; do
        read -p "2. Environment name (e.g., prd, stg, dev): " environment
        if validate_input "environment" "$environment"; then
            break
        else
            echo "   Please enter a valid environment name."
        fi
    done

    # 3. S3 Logs Prefix
    while true; do
        read -p "3. S3 logs prefix (e.g., firelens/firelens/fluent-bit-logs): " logs_s3_prefix
        if validate_input "logs_s3_prefix" "$logs_s3_prefix"; then
            break
        else
            echo "   Please enter a valid S3 prefix."
        fi
    done

    echo ""
    print_colored "$GREEN" "✅ Variables collected:"
    echo "   Project: $project"
    echo "   Environment: $environment"
    echo "   S3 Logs Prefix: $logs_s3_prefix"
    echo ""
}

run_terraform_apply() {
    local auto_approve=${1:-false}
    shift
    local additional_args=("$@")

    local terraform_cmd=(
        terraform apply
    )

    # 要求された場合はauto-approveを追加
    if [ "$auto_approve" = true ]; then
        terraform_cmd+=(-auto-approve)
    fi

    # 計画ファイルを使用していない場合は変数を追加
    local has_plan_file=false
    for arg in "${additional_args[@]}"; do
        if [[ -f "$arg" ]]; then
            has_plan_file=true
            break
        fi
    done

    if [ "$has_plan_file" = false ]; then
        terraform_cmd+=(
            -var="project=$project"
            -var="environment=$environment"
            -var="logs_s3_prefix=$logs_s3_prefix"
        )
    fi

    terraform_cmd+=("${additional_args[@]}")

    echo "Executing: ${terraform_cmd[*]}"
    echo ""

    # 破壊的な操作に対する追加の警告
    if [ "$auto_approve" = false ] && [ "$has_plan_file" = false ]; then
        print_colored "$YELLOW" "⚠️  Terraform will prompt for final confirmation before applying changes."
        echo ""
    fi

    "${terraform_cmd[@]}"
}

main() {
    local skip_confirmation=false
    local auto_approve=false
    local quiet_mode=false
    local terraform_args=()

    # コマンドライン引数を解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                skip_confirmation=true
                shift
                ;;
            -a|--auto-approve)
                auto_approve=true
                shift
                ;;
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            --)
                shift
                terraform_args=("$@")
                break
                ;;
            *)
                # terraformの引数と仮定
                terraform_args+=("$1")
                shift
                ;;
        esac
    done

    # メイン実行フロー
    if [ "$quiet_mode" = false ]; then
        print_header
    fi

    check_dependencies

    local aws_identity
    aws_identity=$(validate_aws_credentials)

    if [ "$quiet_mode" = false ]; then
        display_aws_info "$aws_identity"
    fi

    get_user_confirmation "$skip_confirmation"

    # 計画ファイルを使用していない場合のみ変数を収集
    local has_plan_file=false
    for arg in "${terraform_args[@]}"; do
        if [[ -f "$arg" ]]; then
            has_plan_file=true
            break
        fi
    done

    if [ "$has_plan_file" = false ]; then
        collect_terraform_variables
    else
        print_colored "$BLUE" "📋 Using plan file: ${terraform_args[*]}"
        echo ""
    fi

    run_terraform_apply "$auto_approve" "${terraform_args[@]}"
}

# エラーハンドリング
handle_error() {
    local exit_code=$?
    local line_number=$1
    print_colored "$RED" "❌ Script failed at line $line_number with exit code $exit_code"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# メイン関数を実行
main "$@"
