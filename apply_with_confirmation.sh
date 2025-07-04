#!/bin/bash

# Terraform Apply with AWS Account Confirmation Script
# This script displays AWS account information and asks for confirmation before running terraform apply

set -e

echo ""
echo "=========================================="
echo "🔍 AWS Account Information Validation"
echo "=========================================="

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
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
echo "🚨 This will APPLY CHANGES to your AWS infrastructure!"
echo ""

# Ask for confirmation
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

# Run terraform apply with all passed arguments
echo "Executing: terraform apply $@"
echo ""
terraform apply "$@"
