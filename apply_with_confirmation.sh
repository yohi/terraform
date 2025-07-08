#!/bin/bash

# AWS アカウント確認付き Terraform Apply スクリプト
# このスクリプトは、terraform apply を実行する前に AWS アカウント情報を表示し、確認を求めます

set -euo pipefail

echo ""
echo "=========================================="
echo "🔍 AWS Account Information Validation"
echo "=========================================="

# AWS CLI が設定されているかチェック
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
    exit 1
fi

# jq がインストールされているかチェック
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed or not in PATH"
    exit 1
fi

# terraform がインストールされているかチェック
if ! command -v terraform &> /dev/null; then
    echo "❌ terraform is not installed or not in PATH"
    exit 1
fi

# 現在の AWS アイデンティティを取得
echo "Getting current AWS identity..."
aws_identity=$(aws sts get-caller-identity 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Failed to get AWS identity. Please check your AWS credentials."
    echo "   Run 'aws configure' or set up your AWS credentials."
    exit 1
fi

# 情報を抽出
account_id=$(echo "$aws_identity" | jq -r '.Account')
user_id=$(echo "$aws_identity" | jq -r '.UserId')
arn=$(echo "$aws_identity" | jq -r '.Arn')

echo ""
echo "Current AWS Identity Information:"
echo "  Account ID: $account_id"
echo "  User ID:    $user_id"
echo "  ARN:        $arn"

# アカウント名を取得（組織の一部の場合）
account_name=$(aws organizations describe-account --account-id "$account_id" --query 'Account.Name' --output text 2>/dev/null || echo "N/A")
if [ "$account_name" != "N/A" ]; then
    echo "  Account Name: $account_name"
else
    echo "  Account Name: N/A (not part of organization or no permission)"
fi

echo "=========================================="
echo ""
echo "⚠️  Please verify this is the correct AWS account!"
echo "🚨 This will APPLY CHANGES to your AWS infrastructure!"
echo ""

# 確認を求める
while true; do
    read -p "Do you want to proceed with terraform apply? (Y/N): " -n 1 -r
    echo ""
    case $REPLY in
        [Yy]* )
            echo ""
            echo "✅ AWS account confirmed. Proceeding with terraform apply..."
            echo "=========================================="
            echo ""
            break
            ;;
        [Nn]* )
            echo ""
            echo "❌ Operation cancelled by user."
            echo "Please check your AWS credentials and try again."
            echo ""
            exit 1
            ;;
        * )
            echo "Please answer Y or N."
            ;;
    esac
done

# 渡されたすべての引数で terraform apply を実行
echo "Executing: terraform apply $@"
echo ""
terraform apply "$@"
