#!/bin/bash

# AWS Account Check Script for Terraform external data source
# This script displays AWS account information and asks for user confirmation

set -e

# Function to display AWS account information and get confirmation
aws_account_confirmation() {
    echo "" >&2
    echo "===========================================" >&2
    echo "🚨 AWS Account Confirmation Required! 🚨" >&2
    echo "===========================================" >&2
    echo "" >&2
    echo "Current AWS Account Information:" >&2

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed or not in PATH" >&2
        exit 1
    fi

    # Get and display AWS account information
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
    USER_ID=$(aws sts get-caller-identity --query 'UserId' --output text 2>/dev/null)
    ARN=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$ACCOUNT_ID" ]; then
        echo "❌ Failed to get AWS identity. Please check your AWS credentials." >&2
        exit 1
    fi

    echo "-----------------------------------------------------------" >&2
    echo "Account ID: $ACCOUNT_ID" >&2
    echo "User ID:    $USER_ID" >&2
    echo "ARN:        $ARN" >&2
    echo "-----------------------------------------------------------" >&2
    echo "" >&2
    echo "⚠️  Please verify this is the correct AWS account!" >&2
    echo "" >&2

    # Check if confirmation is skipped via environment variable
    if [ "$TERRAFORM_AWS_ACCOUNT_CONFIRMED" = "true" ]; then
        echo "✅ AWS account confirmation skipped (TERRAFORM_AWS_ACCOUNT_CONFIRMED=true)" >&2
        return 0
    fi

    # Try to get user confirmation - multiple approaches
    local confirmation=""
    local interactive_mode=false

    # Check if we can access /dev/tty and it's available
    if [ -c /dev/tty ] && [ -w /dev/tty ]; then
        # Try to read from TTY with timeout
        echo "Do you want to proceed with this AWS account? (Y/N): " >&2
        if timeout 3s bash -c 'read -r confirmation < /dev/tty; echo $confirmation' 2>/dev/null; then
            confirmation=$(timeout 3s bash -c 'read -r confirmation < /dev/tty; echo $confirmation' 2>/dev/null)
            interactive_mode=true
        fi
    fi

    # If TTY didn't work, try standard input
    if [ "$interactive_mode" = false ] && [ -t 0 ]; then
        echo "Do you want to proceed with this AWS account? (Y/N): " >&2
        if read -r -t 3 confirmation 2>/dev/null; then
            interactive_mode=true
        fi
    fi

    # If neither worked, use countdown mode
    if [ "$interactive_mode" = false ]; then
        echo "⚠️  Running in non-interactive mode (from Terraform)" >&2
        echo "" >&2
        echo "To skip this confirmation, set: export TERRAFORM_AWS_ACCOUNT_CONFIRMED=true" >&2
        echo "" >&2
        echo "For security, waiting 5 seconds before proceeding..." >&2
        echo "Press Ctrl+C to cancel if this is the wrong account!" >&2
        echo "" >&2

        # Countdown with clear messaging
        for i in {5..1}; do
            echo "⏰ Proceeding in $i seconds..." >&2
            sleep 1
        done

        echo "" >&2
        echo "✅ Proceeding with AWS account: $ACCOUNT_ID" >&2
        return 0
    fi

    # Process the interactive confirmation response
    case $confirmation in
        [Yy]|[Yy][Ee][Ss])
            echo "✅ AWS account confirmed. Proceeding..." >&2
            return 0
            ;;
        [Nn]|[Nn][Oo])
            echo "❌ AWS account confirmation denied. Aborting..." >&2
            exit 1
            ;;
        *)
            echo "❌ Invalid input '$confirmation'. Please enter Y or N. Aborting..." >&2
            exit 1
            ;;
    esac
}

# Main execution
main() {
    # Show confirmation prompt
    aws_account_confirmation

    # Get account info for output (already retrieved above)
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    USER_ID=$(aws sts get-caller-identity --query 'UserId' --output text)
    ARN=$(aws sts get-caller-identity --query 'Arn' --output text)

    # Output JSON for Terraform external data source
    cat <<EOF
{
    "account_id": "$ACCOUNT_ID",
    "user_id": "$USER_ID",
    "arn": "$ARN",
    "confirmed": "true",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Call main function
main
