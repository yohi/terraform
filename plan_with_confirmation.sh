#!/bin/bash

# Terraform Plan with AWS Account Confirmation Script
# This script displays AWS account information and asks for confirmation before running terraform plan

set -euo pipefail

echo ""
echo "=========================================="
echo "🔍 AWS Account Information Validation"
echo "=========================================="

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed or not in PATH"
    echo "   Please install jq to parse JSON responses"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ terraform is not installed or not in PATH"
    echo "   Please install terraform to proceed"
    exit 1
fi

# Get current AWS identity
echo "Getting current AWS identity..."
aws_identity=$(aws sts get-caller-identity 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Failed to get AWS identity. Please check your AWS credentials."
    echo "   Run 'aws configure' or set up your AWS credentials."
    exit 1
fi

# Extract information
account_id=$(echo "$aws_identity" | jq -r '.Account')
user_id=$(echo "$aws_identity" | jq -r '.UserId')
arn=$(echo "$aws_identity" | jq -r '.Arn')

echo ""
echo "Current AWS Identity Information:"
echo "  Account ID: $account_id"
echo "  User ID:    $user_id"
echo "  ARN:        $arn"

# Try to get account name (if part of organization)
account_name=$(aws organizations describe-account --account-id "$account_id" --query 'Account.Name' --output text 2>/dev/null || echo "N/A")
if [ "$account_name" != "N/A" ]; then
    echo "  Account Name: $account_name"
else
    echo "  Account Name: N/A (not part of organization or no permission)"
fi

echo "=========================================="
echo ""
echo "⚠️  Please verify this is the correct AWS account!"
echo ""

# Ask for confirmation
while true; do
    read -p "Do you want to proceed with terraform plan? (Y/N): " -n 1 -r
    echo ""
    case $REPLY in
        [Yy]* )
            echo ""
            echo "✅ AWS account confirmed. Proceeding with terraform plan..."
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

# Run terraform plan with all passed arguments
echo "Executing: terraform plan $@"
echo ""
terraform plan "$@"
