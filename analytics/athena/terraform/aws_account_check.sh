#!/bin/bash

# AWS Account Check Script for Terraform external data source
# This script displays AWS account information and asks for user confirmation

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/aws_account_check.log"
readonly TIMEOUT_SECONDS=60

# Logging function
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to display AWS account information and get confirmation
aws_account_confirmation() {
    log_message "INFO" "Starting AWS account confirmation process"

    echo "" >&2
    echo "==========================================" >&2
    echo "🚨 AWS Account Confirmation Required! 🚨" >&2
    echo "==========================================" >&2
    echo "" >&2
    echo "Current AWS Account Information:" >&2

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log_message "ERROR" "AWS CLI not found"
        echo "❌ AWS CLI is not installed or not in PATH" >&2
        exit 1
    fi

    # Get and display AWS account information with timeout
    local account_id user_id arn
    if ! account_id=$(timeout "$TIMEOUT_SECONDS" aws sts get-caller-identity --query 'Account' --output text 2>/dev/null); then
        log_message "ERROR" "Failed to get AWS account ID"
        echo "❌ Failed to get AWS account information. Please check your credentials." >&2
        exit 1
    fi

    user_id=$(timeout "$TIMEOUT_SECONDS" aws sts get-caller-identity --query 'UserId' --output text 2>/dev/null)
    arn=$(timeout "$TIMEOUT_SECONDS" aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)

    echo "----------------------------------------------------------" >&2
    echo "Account ID: $account_id" >&2
    echo "User ID:    $user_id" >&2
    echo "ARN:        $arn" >&2
    echo "----------------------------------------------------------" >&2

    log_message "INFO" "AWS Account: $account_id, User: $user_id"

    echo "" >&2
    echo "⚠️  Please verify this is the correct AWS account!" >&2
    echo "" >&2

    # Check if confirmation is skipped via environment variable
    if [ "${TERRAFORM_AWS_ACCOUNT_CONFIRMED:-}" = "true" ]; then
        log_message "INFO" "AWS account confirmation skipped via environment variable"
        echo "✅ AWS account confirmation skipped (TERRAFORM_AWS_ACCOUNT_CONFIRMED=true)" >&2
        return 0
    fi

    # Check if running in non-interactive mode
    if [ ! -t 0 ] && [ ! -t 1 ]; then
        log_message "WARNING" "Running in non-interactive mode without confirmation"
        echo "⚠️  Running in non-interactive mode - proceeding without confirmation" >&2
        echo "   Set TERRAFORM_AWS_ACCOUNT_CONFIRMED=true to suppress this warning" >&2
        return 0
    fi

    # Interactive confirmation prompt
    local confirmation
    echo -n "Do you want to proceed with this AWS account? (Y/N): " >&2

    # Read with timeout to prevent hanging
    if read -r -t "$TIMEOUT_SECONDS" confirmation < /dev/tty 2>/dev/null || read -r confirmation; then
        case $confirmation in
            [Yy]|[Yy][Ee][Ss])
                log_message "INFO" "AWS account confirmed by user"
                echo "✅ AWS account confirmed. Proceeding..." >&2
                return 0
                ;;
            [Nn]|[Nn][Oo])
                log_message "INFO" "AWS account confirmation denied by user"
                echo "❌ AWS account confirmation denied. Aborting..." >&2
                exit 1
                ;;
            *)
                log_message "ERROR" "Invalid user input: $confirmation"
                echo "❌ Invalid input. Please enter Y or N. Aborting..." >&2
                exit 1
                ;;
        esac
    else
        log_message "ERROR" "Timeout waiting for user confirmation"
        echo "❌ Timeout waiting for confirmation. Aborting..." >&2
        exit 1
    fi
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_message "ERROR" "Script failed at line $line_number with exit code $exit_code"
    echo '{"error": "Script failed", "exit_code": '$exit_code', "line": '$line_number'}' >&2
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Main execution
main() {
    log_message "INFO" "Script started"

    # Show confirmation prompt
    aws_account_confirmation

    # Get account info for output
    local account_id user_id arn
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    user_id=$(aws sts get-caller-identity --query 'UserId' --output text)
    arn=$(aws sts get-caller-identity --query 'Arn' --output text)

    log_message "INFO" "Script completed successfully"

    # Output JSON for Terraform external data source
    cat <<EOF
{
    "account_id": "$account_id",
    "user_id": "$user_id",
    "arn": "$arn",
    "confirmed": "true",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Call main function
main "$@"
