#!/bin/bash

# AWS アカウント情報確認スクリプト
# このスクリプトは、Terraform を実行する前にどの AWS アカウントを使用しているかを確認するのに役立ちます

set -euo pipefail  # より厳格なエラーハンドリング

# 出力をより見やすくするための色
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # 色なし

# 色付き出力を行う関数
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo "========================================"
    echo "AWS Account Information Check"
    echo "========================================"
    echo ""
}

check_dependencies() {
    local missing_deps=()

    if ! command -v aws &> /dev/null; then
        missing_deps+=("aws")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "$RED" "❌ Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                aws)
                    echo "  - AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
                    ;;
                jq)
                    echo "  - jq: https://stedolan.github.io/jq/download/"
                    ;;
            esac
        done
        exit 1
    fi
}

get_aws_identity() {
    print_status "$BLUE" "🔍 Checking current AWS identity..."

    local aws_identity
    if ! aws_identity=$(aws sts get-caller-identity 2>/dev/null); then
        print_status "$RED" "❌ Failed to get AWS identity. Please check your AWS credentials."
        echo "   Run 'aws configure' or set up your AWS credentials."
        exit 1
    fi

    echo "$aws_identity"
}

display_account_info() {
    local aws_identity=$1

    # 情報を安全に抽出
    local account_id user_id arn
    account_id=$(echo "$aws_identity" | jq -r '.Account // "N/A"')
    user_id=$(echo "$aws_identity" | jq -r '.UserId // "N/A"')
    arn=$(echo "$aws_identity" | jq -r '.Arn // "N/A"')

    print_status "$GREEN" "✅ AWS Identity Information:"
    echo "   Account ID: $account_id"
    echo "   User ID:    $user_id"
    echo "   ARN:        $arn"
    echo ""

    # アカウント名を取得（組織の一部の場合）
    print_status "$BLUE" "🔍 Checking AWS account name..."
    local account_name
    if account_name=$(aws organizations describe-account --account-id "$account_id" --query 'Account.Name' --output text 2>/dev/null) && [ "$account_name" != "None" ]; then
        print_status "$GREEN" "✅ Account Name: $account_name"
    else
        print_status "$YELLOW" "ℹ️  Account Name: N/A (not part of organization or no permission)"
    fi
}

show_terraform_commands() {
    echo ""
    echo "========================================"
    echo "Terraform Commands:"
    echo "========================================"
    echo "After confirming the above information is correct:"
    echo ""
    echo "1. Initialize Terraform:"
    echo "   cd analytics/athena/terraform"
    echo "   terraform init"
    echo ""
    echo "2. Plan changes (with AWS confirmation):"
    echo "   ./plan_with_confirmation.sh"
    echo ""
    echo "3. Apply changes (with AWS confirmation):"
    echo "   ./apply_with_confirmation.sh"
    echo ""
    echo "Alternative (direct commands):"
    echo "   terraform plan"
    echo "   terraform apply"
    echo ""
    print_status "$RED" "🚨 Please verify the account information above before proceeding!"
    echo "========================================"
}

main() {
    print_header
    check_dependencies

    local aws_identity
    aws_identity=$(get_aws_identity)

    display_account_info "$aws_identity"
    show_terraform_commands
}

# メイン関数を実行
main "$@"
