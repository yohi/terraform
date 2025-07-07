#!/bin/bash

# Test Terraform Plan for ECR Repository Module

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

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${TEST_DIR}/../terraform"
TEMP_DIR="${TEST_DIR}/temp"

# Create temporary directory for test
mkdir -p "$TEMP_DIR"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

test_terraform_plan() {
    print_status "$BLUE" "  Testing Terraform plan generation..."

    # Create test configuration
    cat > "$TEMP_DIR/test.tfvars" << EOF
# Test configuration for ECR repository module
project_name = "test-ecr"
environment  = "dev"
app         = "sample"

# Basic ECR settings
image_tag_mutability = "MUTABLE"
scan_on_push = true
encryption_type = "AES256"

# Lifecycle policy settings
enable_lifecycle_policy = true
untagged_image_count_limit = 5
tagged_image_count_limit = 10
image_age_limit_days = 30

# Repository policy settings
enable_repository_policy = false

# Replication settings
enable_replication = false

# Common tags
common_tags = {
  Project     = "test-ecr"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test.tfvars" -out="$TEMP_DIR/test.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate Terraform plan"
        return 1
    fi

    # Show plan summary
    local plan_output
    plan_output=$(terraform show -json "$TEMP_DIR/test.tfplan" | jq -r '
        .resource_changes[] |
        select(.change.actions[] | contains("create")) |
        .address'
    )

    if [ -n "$plan_output" ]; then
        print_status "$GREEN" "  ✅ Terraform plan generated successfully"
        print_status "$BLUE" "  📋 Resources to be created:"
        echo "$plan_output" | sed 's/^/    - /'
        return 0
    else
        print_status "$RED" "  ❌ No resources found in plan"
        return 1
    fi
}

test_multiple_repositories_plan() {
    print_status "$BLUE" "  Testing multiple repositories plan..."

    # Create test configuration for multiple repositories
    cat > "$TEMP_DIR/test-multi.tfvars" << EOF
# Test configuration for multiple ECR repositories
project_name = "test-multi-ecr"
environment  = "dev"

# Multiple repositories configuration
repositories = [
  {
    name                 = "test-web-app"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
  },
  {
    name                 = "test-api-server"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
  }
]

# Common tags
common_tags = {
  Project     = "test-multi-ecr"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan for multiple repositories
    if ! terraform plan -var-file="$TEMP_DIR/test-multi.tfvars" -out="$TEMP_DIR/test-multi.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate multiple repositories plan"
        return 1
    fi

    # Check if multiple ECR repositories will be created
    local ecr_count
    ecr_count=$(terraform show -json "$TEMP_DIR/test-multi.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecr_repository") |
        select(.change.actions[] | contains("create"))
    ' | jq -s 'length')

    if [ "$ecr_count" -eq 2 ]; then
        print_status "$GREEN" "  ✅ Multiple repositories plan generated successfully"
        print_status "$BLUE" "  📋 Will create $ecr_count ECR repositories"
        return 0
    else
        print_status "$RED" "  ❌ Expected 2 ECR repositories, got $ecr_count"
        return 1
    fi
}

test_plan_validation() {
    print_status "$BLUE" "  Testing plan validation..."

    # Create test configuration with validation errors
    cat > "$TEMP_DIR/test-invalid.tfvars" << EOF
# Test configuration with invalid values
project_name = "test-invalid"
environment  = "invalid"  # This should fail validation
app         = "sample"

common_tags = {
  Project     = "test-invalid"
  Environment = "invalid"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Try to generate plan with invalid configuration
    if terraform plan -var-file="$TEMP_DIR/test-invalid.tfvars" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Invalid configuration should have failed validation"
        return 1
    else
        print_status "$GREEN" "  ✅ Validation correctly rejected invalid configuration"
        return 0
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running Terraform plan tests..."

    local tests_passed=0
    local tests_failed=0

    # Test basic plan generation
    if test_terraform_plan; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test multiple repositories plan
    if test_multiple_repositories_plan; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test plan validation
    if test_plan_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All Terraform plan tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some Terraform plan tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
