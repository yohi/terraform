#!/bin/bash

# Test Terraform Plan execution
# This script tests that Terraform can generate a plan without errors

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

test_terraform_plan() {
    local terraform_dir="../athena/terraform"

    print_status "$BLUE" "🔍 Testing Terraform plan generation..."

    # Create a temporary directory for test
    local temp_dir
    temp_dir=$(mktemp -d)

    # Copy terraform files to temp directory
    cp -r "$terraform_dir"/* "$temp_dir/"

    # Create a test terraform.tfvars file
    cat > "$temp_dir/terraform.tfvars" << EOF
project_name = "test-project"
environment = "dev"
app = "web"
logs_bucket_name = "test-logs-bucket-$(date +%s)"
logs_s3_prefix = "test-logs/containers"
expected_aws_account_id = "$(aws sts get-caller-identity --query Account --output text)"
auto_create_bucket = true
skip_bucket_validation = false
require_bucket_exists = false
enable_crawler_schedule = false
enable_quicksight = false
aws_region = "ap-northeast-1"
EOF

    # Change to temp directory
    cd "$temp_dir"

    local exit_code=0

    # Initialize Terraform
    print_status "$BLUE" "  Initializing Terraform..."
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "❌ Terraform init failed"
        exit_code=1
    fi

    # Generate plan
    print_status "$BLUE" "  Generating Terraform plan..."
    if ! terraform plan -out=test.tfplan > /dev/null 2>&1; then
        print_status "$RED" "❌ Terraform plan failed"
        exit_code=1
    fi

    # Check if plan was created
    if [ ! -f "test.tfplan" ]; then
        print_status "$RED" "❌ Plan file was not created"
        exit_code=1
    fi

    # Show plan summary
    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ Terraform plan generated successfully"

        # Extract plan summary
        if terraform show -json test.tfplan > plan.json 2>/dev/null; then
            local resource_count
            resource_count=$(jq -r '.planned_values.root_module.resources | length' plan.json 2>/dev/null || echo "unknown")
            print_status "$BLUE" "  📊 Plan would create approximately $resource_count resources"
        fi
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    return $exit_code
}

# Execute test
test_terraform_plan
