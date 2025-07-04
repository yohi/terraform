#!/bin/bash

# Terraform Plan with AWS Account Confirmation Script
# This script displays AWS account information and asks for confirmation before running terraform plan

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

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed or not in PATH"
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

# Collect variables in the desired order
echo "📝 Please provide the following variables in order:"
echo ""

# 1. Project
while true; do
    read -p "1. Project name (e.g., rcs, myapp): " project
    if [ -n "$project" ]; then
        break
    else
        echo "   ❌ Project name cannot be empty. Please enter a valid project name."
    fi
done

# 2. Environment
while true; do
    read -p "2. Environment name (e.g., prd, stg, dev): " env
    if [ -n "$env" ]; then
        break
    else
        echo "   ❌ Environment name cannot be empty. Please enter a valid environment name."
    fi
done

# 3. S3 Logs Prefix
while true; do
    read -p "3. S3 logs prefix (e.g., firelens/firelens/fluent-bit-logs): " logs_s3_prefix
    if [ -n "$logs_s3_prefix" ]; then
        break
    else
        echo "   ❌ S3 logs prefix cannot be empty. Please enter a valid S3 prefix."
    fi
done

echo ""
echo "✅ Variables collected:"
echo "   Project: $project"
echo "   Environment: $env"
echo "   S3 Logs Prefix: $logs_s3_prefix"
echo ""

# Run terraform plan with collected variables
echo "Executing: terraform plan -var=\"project=$project\" -var=\"env=$env\" -var=\"logs_s3_prefix=$logs_s3_prefix\" $@"
echo ""
terraform plan -var="project=$project" -var="env=$env" -var="logs_s3_prefix=$logs_s3_prefix" "$@"
