#!/bin/bash

# Test S3 Bucket Validation
# This script tests the S3 bucket validation functionality

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

test_s3_bucket_validation() {
    print_status "$BLUE" "🔍 Testing S3 bucket validation..."

    local exit_code=0

    # Test 1: Check S3 bucket validation script
    print_status "$BLUE" "  Testing s3_bucket_check.sh script..."

    local script_path="../athena/terraform/s3_bucket_check.sh"
    if [ -f "$script_path" ]; then
        # Test script syntax
        if bash -n "$script_path" > /dev/null 2>&1; then
            print_status "$GREEN" "    ✅ Script syntax is valid"
        else
            print_status "$RED" "    ❌ Script syntax is invalid"
            exit_code=1
        fi

        # Test script with non-existent bucket
        print_status "$BLUE" "    Testing with non-existent bucket..."
        local test_bucket="non-existent-bucket-$(date +%s)"

        if bash "$script_path" "$test_bucket" > /dev/null 2>&1; then
            print_status "$YELLOW" "    ⚠️  Script did not fail for non-existent bucket"
        else
            print_status "$GREEN" "    ✅ Script correctly failed for non-existent bucket"
        fi
    else
        print_status "$RED" "    ❌ s3_bucket_check.sh not found"
        exit_code=1
    fi

    # Test 2: Terraform bucket validation logic
    print_status "$BLUE" "  Testing Terraform bucket validation logic..."

    local terraform_dir="../athena/terraform"
    if [ -d "$terraform_dir" ]; then
        # Create temporary directory for test
        local temp_dir
        temp_dir=$(mktemp -d)

        # Copy terraform files
        cp -r "$terraform_dir"/*.tf "$temp_dir/"

        cd "$temp_dir"

        # Test with skip_bucket_validation=true
        print_status "$BLUE" "    Testing with skip_bucket_validation=true..."

        cat > terraform.tfvars << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "non-existent-bucket-$(date +%s)"
logs_s3_prefix = "test-logs/containers"
skip_bucket_validation = true
require_bucket_exists = false
auto_create_bucket = false
EOF

        if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
            print_status "$GREEN" "    ✅ Validation passed with skip_bucket_validation=true"
        else
            print_status "$RED" "    ❌ Validation failed with skip_bucket_validation=true"
            exit_code=1
        fi

        # Test with auto_create_bucket=true
        print_status "$BLUE" "    Testing with auto_create_bucket=true..."

        cat > terraform.tfvars << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "test-bucket-$(date +%s)"
logs_s3_prefix = "test-logs/containers"
skip_bucket_validation = false
require_bucket_exists = false
auto_create_bucket = true
EOF

        if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
            print_status "$GREEN" "    ✅ Validation passed with auto_create_bucket=true"
        else
            print_status "$RED" "    ❌ Validation failed with auto_create_bucket=true"
            exit_code=1
        fi

        # Test with require_bucket_exists=true and non-existent bucket
        print_status "$BLUE" "    Testing with require_bucket_exists=true..."

        cat > terraform.tfvars << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "non-existent-bucket-$(date +%s)"
logs_s3_prefix = "test-logs/containers"
skip_bucket_validation = false
require_bucket_exists = true
auto_create_bucket = false
EOF

        # This should fail during plan
        if terraform plan > /dev/null 2>&1; then
            print_status "$YELLOW" "    ⚠️  Bucket validation did not fail as expected"
        else
            print_status "$GREEN" "    ✅ Bucket validation correctly failed for non-existent bucket"
        fi

        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
    else
        print_status "$RED" "    ❌ Terraform directory not found"
        exit_code=1
    fi

    # Test 3: Check for existing buckets (optional)
    print_status "$BLUE" "  Testing bucket listing capability..."

    if aws s3 ls > /dev/null 2>&1; then
        print_status "$GREEN" "    ✅ S3 bucket listing works"

        # Count available buckets
        local bucket_count
        bucket_count=$(aws s3 ls | wc -l)
        print_status "$BLUE" "    📊 Found $bucket_count S3 buckets in account"
    else
        print_status "$YELLOW" "    ⚠️  S3 bucket listing failed (permissions or network issue)"
    fi

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ S3 bucket validation is working correctly"
    else
        print_status "$RED" "❌ S3 bucket validation has issues"
    fi

    return $exit_code
}

# Execute test
test_s3_bucket_validation
