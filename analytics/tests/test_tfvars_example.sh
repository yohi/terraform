#!/bin/bash

# Test terraform.tfvars.example syntax
# This script validates the example configuration file

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

test_tfvars_example() {
    local tfvars_file="../athena/terraform/terraform.tfvars.example"

    print_status "$BLUE" "🔍 Testing terraform.tfvars.example syntax..."

    # Check if file exists
    if [ ! -f "$tfvars_file" ]; then
        print_status "$RED" "❌ terraform.tfvars.example not found"
        return 1
    fi

    # Create a temporary directory for test
    local temp_dir
    temp_dir=$(mktemp -d)

    # Copy necessary files
    cp -r ../athena/terraform/*.tf "$temp_dir/"
    cp "$tfvars_file" "$temp_dir/terraform.tfvars"

    cd "$temp_dir"

    local exit_code=0

    # Initialize Terraform
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "❌ Terraform init failed"
        exit_code=1
    fi

    # Validate configuration
    if ! terraform validate > /dev/null 2>&1; then
        print_status "$RED" "❌ terraform.tfvars.example contains invalid configuration"
        exit_code=1
    fi

    # Check required variables are present
    print_status "$BLUE" "  Checking required variables..."

    local required_vars=("project_name" "environment" "app" "logs_bucket_name" "logs_s3_prefix")

    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var.*=" terraform.tfvars; then
            print_status "$YELLOW" "  ⚠️  Required variable '$var' not found in example"
            exit_code=1
        fi
    done

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ terraform.tfvars.example is valid"

        # Show variable count
        local var_count
        var_count=$(grep -c "^[a-zA-Z_].*=" terraform.tfvars || echo "0")
        print_status "$BLUE" "  📊 Contains $var_count variable definitions"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    return $exit_code
}

# Execute test
test_tfvars_example
