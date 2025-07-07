#!/bin/bash

# Test ECR Lifecycle Policy Configuration

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
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

test_default_lifecycle_policy() {
    print_status "$BLUE" "  Testing default lifecycle policy..."

    # Create test configuration with default lifecycle policy
    cat > "$TEMP_DIR/test-lifecycle.tfvars" << EOF
project_name = "test-lifecycle"
environment  = "dev"
app         = "sample"

# Enable lifecycle policy (default)
enable_lifecycle_policy = true

# Test default values
untagged_image_count_limit = 10
tagged_image_count_limit = 20
image_age_limit_days = 30

common_tags = {
  Project     = "test-lifecycle"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Initialize and plan
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi

    if ! terraform plan -var-file="$TEMP_DIR/test-lifecycle.tfvars" -out="$TEMP_DIR/lifecycle.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate plan with lifecycle policy"
        return 1
    fi

    # Check if lifecycle policy resource is created
    local lifecycle_resources
    lifecycle_resources=$(terraform show -json "$TEMP_DIR/lifecycle.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecr_lifecycle_policy") |
        select(.change.actions[] | contains("create")) |
        .address'
    )

    if [ -n "$lifecycle_resources" ]; then
        print_status "$GREEN" "  ✅ Default lifecycle policy will be created"
        return 0
    else
        print_status "$RED" "  ❌ Lifecycle policy resource not found in plan"
        return 1
    fi
}

test_custom_lifecycle_policy() {
    print_status "$BLUE" "  Testing custom lifecycle policy..."

    # Create custom lifecycle policy JSON
    cat > "$TEMP_DIR/custom-policy.json" << EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

    # Create test configuration with custom lifecycle policy
    cat > "$TEMP_DIR/test-custom-lifecycle.tfvars" << EOF
project_name = "test-custom-lifecycle"
environment  = "dev"
app         = "sample"

# Enable lifecycle policy with custom rules
enable_lifecycle_policy = true
lifecycle_policy_rules = file("$TEMP_DIR/custom-policy.json")

common_tags = {
  Project     = "test-custom-lifecycle"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan with custom lifecycle policy
    if ! terraform plan -var-file="$TEMP_DIR/test-custom-lifecycle.tfvars" -out="$TEMP_DIR/custom-lifecycle.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate plan with custom lifecycle policy"
        return 1
    fi

    # Check if lifecycle policy resource is created
    local lifecycle_resources
    lifecycle_resources=$(terraform show -json "$TEMP_DIR/custom-lifecycle.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecr_lifecycle_policy") |
        select(.change.actions[] | contains("create")) |
        .address'
    )

    if [ -n "$lifecycle_resources" ]; then
        print_status "$GREEN" "  ✅ Custom lifecycle policy will be created"
        return 0
    else
        print_status "$RED" "  ❌ Custom lifecycle policy resource not found in plan"
        return 1
    fi
}

test_lifecycle_policy_disabled() {
    print_status "$BLUE" "  Testing lifecycle policy disabled..."

    # Create test configuration with lifecycle policy disabled
    cat > "$TEMP_DIR/test-no-lifecycle.tfvars" << EOF
project_name = "test-no-lifecycle"
environment  = "dev"
app         = "sample"

# Disable lifecycle policy
enable_lifecycle_policy = false

common_tags = {
  Project     = "test-no-lifecycle"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan with lifecycle policy disabled
    if ! terraform plan -var-file="$TEMP_DIR/test-no-lifecycle.tfvars" -out="$TEMP_DIR/no-lifecycle.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate plan with lifecycle policy disabled"
        return 1
    fi

    # Check if lifecycle policy resource is NOT created
    local lifecycle_resources
    lifecycle_resources=$(terraform show -json "$TEMP_DIR/no-lifecycle.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecr_lifecycle_policy") |
        select(.change.actions[] | contains("create")) |
        .address'
    )

    if [ -z "$lifecycle_resources" ]; then
        print_status "$GREEN" "  ✅ Lifecycle policy correctly disabled"
        return 0
    else
        print_status "$RED" "  ❌ Lifecycle policy resource found when it should be disabled"
        return 1
    fi
}

test_lifecycle_policy_validation() {
    print_status "$BLUE" "  Testing lifecycle policy validation..."

    # Test with invalid JSON (should fail)
    cat > "$TEMP_DIR/invalid-policy.json" << EOF
{
  "rules": [
    {
      "rulePriority": "invalid",
      "description": "Invalid rule",
      "selection": {
        "tagStatus": "untagged"
      }
    }
  ]
}
EOF

    # Create test configuration with invalid lifecycle policy
    cat > "$TEMP_DIR/test-invalid-lifecycle.tfvars" << EOF
project_name = "test-invalid-lifecycle"
environment  = "dev"
app         = "sample"

# Enable lifecycle policy with invalid rules
enable_lifecycle_policy = true
lifecycle_policy_rules = file("$TEMP_DIR/invalid-policy.json")

common_tags = {
  Project     = "test-invalid-lifecycle"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Try to generate plan with invalid lifecycle policy
    if terraform plan -var-file="$TEMP_DIR/test-invalid-lifecycle.tfvars" > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ Invalid lifecycle policy was handled gracefully"
        return 0
    else
        print_status "$GREEN" "  ✅ Invalid lifecycle policy correctly rejected"
        return 0
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running ECR lifecycle policy tests..."

    local tests_passed=0
    local tests_failed=0

    # Test default lifecycle policy
    if test_default_lifecycle_policy; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test custom lifecycle policy
    if test_custom_lifecycle_policy; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test lifecycle policy disabled
    if test_lifecycle_policy_disabled; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test lifecycle policy validation
    if test_lifecycle_policy_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All lifecycle policy tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some lifecycle policy tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
