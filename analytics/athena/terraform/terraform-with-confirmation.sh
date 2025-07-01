#!/bin/bash

# Terraform wrapper script with AWS account confirmation
# Usage: ./terraform-with-confirmation.sh plan [additional_args...]
#        ./terraform-with-confirmation.sh apply [additional_args...]

set -e

# Function to display AWS account information and get confirmation
aws_account_confirmation() {
    echo ""
    echo "=========================================="
    echo "🚨 AWS Account Confirmation Required! 🚨"
    echo "=========================================="
    echo ""
    echo "Current AWS Account Information:"

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed or not in PATH"
        exit 1
    fi

    # Get AWS account information
    aws sts get-caller-identity --query '{AccountId:Account,UserId:UserId,Arn:Arn}' --output table

    echo ""
    echo "⚠️  Please verify this is the correct AWS account!"
    echo ""

    # Get Y/N confirmation
    while true; do
        read -p "Do you want to proceed with this AWS account? (Y/N): " -n 1 -r
        echo ""
        case $REPLY in
            [Yy]* )
                echo "✅ AWS account confirmed. Proceeding with terraform $1..."
                echo ""
                break
                ;;
            [Nn]* )
                echo "❌ Operation cancelled by user."
                echo "Please configure the correct AWS credentials and try again."
                exit 1
                ;;
            * )
                echo "Please answer Y or N."
                ;;
        esac
    done
}

# Check if terraform command is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <terraform_command> [additional_args...]"
    echo "Example: $0 plan"
    echo "Example: $0 apply"
    exit 1
fi

# Get the terraform command
terraform_command="$1"
shift

# Only show confirmation for plan and apply commands
case "$terraform_command" in
    "plan"|"apply")
        aws_account_confirmation "$terraform_command"
        ;;
    *)
        echo "Running terraform $terraform_command without confirmation..."
        ;;
esac

# Execute terraform command with all remaining arguments
exec terraform "$terraform_command" "$@"
