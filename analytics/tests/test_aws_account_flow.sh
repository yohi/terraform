#!/bin/bash

# Test AWS Account Check Flow
# This script tests the AWS account validation workflow

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

test_aws_account_flow() {
    print_status "$BLUE" "🔍 Testing AWS account check flow..."

    local exit_code=0

    # Test 1: Basic AWS credentials check
    print_status "$BLUE" "  Testing AWS credentials..."

    if aws sts get-caller-identity > /dev/null 2>&1; then
        print_status "$GREEN" "    ✅ AWS credentials are working"
    else
        print_status "$RED" "    ❌ AWS credentials are not working"
        exit_code=1
    fi

    # Test 2: AWS account information retrieval
    print_status "$BLUE" "  Testing account information retrieval..."

    local account_info
    if account_info=$(aws sts get-caller-identity 2>/dev/null); then
        local account_id
        local user_id
        local arn

        account_id=$(echo "$account_info" | jq -r '.Account // "N/A"')
        user_id=$(echo "$account_info" | jq -r '.UserId // "N/A"')
        arn=$(echo "$account_info" | jq -r '.Arn // "N/A"')

        if [ "$account_id" != "N/A" ] && [ "$user_id" != "N/A" ] && [ "$arn" != "N/A" ]; then
            print_status "$GREEN" "    ✅ Account information retrieved successfully"
            print_status "$BLUE" "      Account ID: $account_id"
            print_status "$BLUE" "      User ID: $user_id"
            print_status "$BLUE" "      ARN: $arn"
        else
            print_status "$RED" "    ❌ Failed to parse account information"
            exit_code=1
        fi
    else
        print_status "$RED" "    ❌ Failed to retrieve account information"
        exit_code=1
    fi

    # Test 3: Check AWS account check script
    print_status "$BLUE" "  Testing check_aws_account.sh script..."

    local script_path="../check_aws_account.sh"
    if [ -f "$script_path" ]; then
        # Test script syntax
        if bash -n "$script_path" > /dev/null 2>&1; then
            print_status "$GREEN" "    ✅ Script syntax is valid"
        else
            print_status "$RED" "    ❌ Script syntax is invalid"
            exit_code=1
        fi

        # Test script execution (capture output)
        local script_output
        if script_output=$(timeout 30 bash "$script_path" 2>&1); then
            print_status "$GREEN" "    ✅ Script executed successfully"

            # Check if script contains expected content
            if echo "$script_output" | grep -q "AWS Account Information"; then
                print_status "$GREEN" "    ✅ Script output contains expected content"
            else
                print_status "$YELLOW" "    ⚠️  Script output may not contain expected content"
            fi
        else
            print_status "$RED" "    ❌ Script execution failed or timed out"
            exit_code=1
        fi
    else
        print_status "$RED" "    ❌ check_aws_account.sh not found"
        exit_code=1
    fi

    # Test 4: Terraform account validation
    print_status "$BLUE" "  Testing Terraform account validation..."

    local terraform_dir="../athena/terraform"
    if [ -d "$terraform_dir" ]; then
        # Create temporary directory for test
        local temp_dir
        temp_dir=$(mktemp -d)

        # Copy terraform files
        cp -r "$terraform_dir"/*.tf "$temp_dir/"

        # Create test tfvars with current account
        local current_account_id
        current_account_id=$(aws sts get-caller-identity --query Account --output text)

        cat > "$temp_dir/terraform.tfvars" << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "test-logs-bucket"
logs_s3_prefix = "test-logs/containers"
expected_aws_account_id = "$current_account_id"
auto_create_bucket = true
skip_bucket_validation = false
require_bucket_exists = false
EOF

        cd "$temp_dir"

        # Initialize and validate
        if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
            print_status "$GREEN" "    ✅ Terraform account validation configuration is valid"
        else
            print_status "$RED" "    ❌ Terraform account validation configuration is invalid"
            exit_code=1
        fi

        # Test with wrong account ID
        cat > terraform.tfvars << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "test-logs-bucket"
logs_s3_prefix = "test-logs/containers"
expected_aws_account_id = "123456789012"
auto_create_bucket = true
skip_bucket_validation = false
require_bucket_exists = false
EOF

        # This should fail during plan
        if terraform plan > /dev/null 2>&1; then
            print_status "$YELLOW" "    ⚠️  Account validation did not fail as expected"
        else
            print_status "$GREEN" "    ✅ Account validation correctly failed for wrong account ID"
        fi

        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
    else
        print_status "$RED" "    ❌ Terraform directory not found"
        exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ AWS account check flow is working correctly"
    else
        print_status "$RED" "❌ AWS account check flow has issues"
    fi

    return $exit_code
}

# Execute test
test_aws_account_flow
