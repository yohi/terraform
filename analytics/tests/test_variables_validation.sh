#!/bin/bash

# Test Terraform variables validation
# This script tests variable validation rules

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

test_variable_validation() {
    local test_name=$1
    local var_name=$2
    local var_value=$3
    local should_fail=$4

    print_status "$BLUE" "  Testing $test_name..."

    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)

    # Copy terraform files
    cp -r ../athena/terraform/*.tf "$temp_dir/"

    # Create test tfvars
    cat > "$temp_dir/terraform.tfvars" << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "test-logs-bucket"
logs_s3_prefix = "test-logs/containers"
$var_name = $var_value
EOF

    cd "$temp_dir"

    # Initialize and validate
    terraform init -backend=false > /dev/null 2>&1

    if terraform validate > /dev/null 2>&1; then
        if [ "$should_fail" = true ]; then
            print_status "$RED" "    ❌ Expected validation to fail but it passed"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        else
            print_status "$GREEN" "    ✅ Validation passed as expected"
        fi
    else
        if [ "$should_fail" = true ]; then
            print_status "$GREEN" "    ✅ Validation failed as expected"
        else
            print_status "$RED" "    ❌ Validation failed unexpectedly"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    return 0
}

test_variables_validation() {
    print_status "$BLUE" "🔍 Testing variable validation rules..."

    local exit_code=0

    # Test environment variable validation
    test_variable_validation "valid environment" "environment" '"dev"' false || exit_code=1
    test_variable_validation "invalid environment" "environment" '"invalid"' true || exit_code=1

    # Test data_classification validation
    test_variable_validation "valid data_classification" "data_classification" '"internal"' false || exit_code=1
    test_variable_validation "invalid data_classification" "data_classification" '"invalid"' true || exit_code=1

    # Test empty project_name
    test_variable_validation "empty project_name" "project_name" '""' true || exit_code=1

    # Test empty app
    test_variable_validation "empty app" "app" '""' true || exit_code=1

    # Test empty logs_bucket_name
    test_variable_validation "empty logs_bucket_name" "logs_bucket_name" '""' true || exit_code=1

    # Test s3 prefix with trailing slash
    test_variable_validation "s3 prefix with trailing slash" "logs_s3_prefix" '"logs/containers/"' true || exit_code=1

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ All variable validation tests passed"
    else
        print_status "$RED" "❌ Some variable validation tests failed"
    fi

    return $exit_code
}

# Execute test
test_variables_validation
