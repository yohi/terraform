#!/bin/bash

# Test Variables Validation for ECR Repository Module

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

test_environment_validation() {
    print_status "$BLUE" "  Testing environment validation..."

    local test_cases=(
        "dev:valid"
        "stg:valid"
        "prd:valid"
        "rls:valid"
        "production:invalid"
        "staging:invalid"
        "test:invalid"
        "invalid:invalid"
    )

    local tests_passed=0
    local tests_failed=0

    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r env expected <<< "$test_case"

        # Create test configuration
        cat > "$TEMP_DIR/test-env-${env}.tfvars" << EOF
project_name = "test-env"
environment  = "${env}"
app         = "sample"

common_tags = {
  Project     = "test-env"
  Environment = "${env}"
  Purpose     = "testing"
}
EOF

        # Change to terraform directory
        cd "$TERRAFORM_DIR"

        # Initialize if needed
        if [ ! -d ".terraform" ]; then
            terraform init -backend=false > /dev/null 2>&1
        fi

        # Test validation
        if terraform validate -var-file="$TEMP_DIR/test-env-${env}.tfvars" > /dev/null 2>&1; then
            if [ "$expected" = "valid" ]; then
                print_status "$GREEN" "    ✅ Environment '${env}' correctly validated"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Environment '${env}' should have failed validation"
                ((tests_failed++))
            fi
        else
            if [ "$expected" = "invalid" ]; then
                print_status "$GREEN" "    ✅ Environment '${env}' correctly rejected"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Environment '${env}' should have passed validation"
                ((tests_failed++))
            fi
        fi
    done

    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "  ✅ Environment validation tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "  ❌ Environment validation tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

test_encryption_validation() {
    print_status "$BLUE" "  Testing encryption validation..."

    local test_cases=(
        "AES256::valid"
        "KMS:arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012:valid"
        "KMS::invalid"
        "INVALID::invalid"
    )

    local tests_passed=0
    local tests_failed=0

    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r encryption_type kms_key expected <<< "$test_case"

        # Create test configuration
        cat > "$TEMP_DIR/test-encryption-${encryption_type}.tfvars" << EOF
project_name = "test-encryption"
environment  = "dev"
app         = "sample"

encryption_type = "${encryption_type}"
kms_key_id     = "${kms_key}"

common_tags = {
  Project     = "test-encryption"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

        # Change to terraform directory
        cd "$TERRAFORM_DIR"

        # Test validation
        if terraform validate -var-file="$TEMP_DIR/test-encryption-${encryption_type}.tfvars" > /dev/null 2>&1; then
            if [ "$expected" = "valid" ]; then
                print_status "$GREEN" "    ✅ Encryption '${encryption_type}' correctly validated"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Encryption '${encryption_type}' should have failed validation"
                ((tests_failed++))
            fi
        else
            if [ "$expected" = "invalid" ]; then
                print_status "$GREEN" "    ✅ Encryption '${encryption_type}' correctly rejected"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Encryption '${encryption_type}' should have passed validation"
                ((tests_failed++))
            fi
        fi
    done

    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "  ✅ Encryption validation tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "  ❌ Encryption validation tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

test_image_tag_mutability_validation() {
    print_status "$BLUE" "  Testing image tag mutability validation..."

    local test_cases=(
        "MUTABLE:valid"
        "IMMUTABLE:valid"
        "mutable:invalid"
        "immutable:invalid"
        "INVALID:invalid"
    )

    local tests_passed=0
    local tests_failed=0

    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r mutability expected <<< "$test_case"

        # Create test configuration
        cat > "$TEMP_DIR/test-mutability-${mutability}.tfvars" << EOF
project_name = "test-mutability"
environment  = "dev"
app         = "sample"

image_tag_mutability = "${mutability}"

common_tags = {
  Project     = "test-mutability"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

        # Change to terraform directory
        cd "$TERRAFORM_DIR"

        # Test validation
        if terraform validate -var-file="$TEMP_DIR/test-mutability-${mutability}.tfvars" > /dev/null 2>&1; then
            if [ "$expected" = "valid" ]; then
                print_status "$GREEN" "    ✅ Mutability '${mutability}' correctly validated"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Mutability '${mutability}' should have failed validation"
                ((tests_failed++))
            fi
        else
            if [ "$expected" = "invalid" ]; then
                print_status "$GREEN" "    ✅ Mutability '${mutability}' correctly rejected"
                ((tests_passed++))
            else
                print_status "$RED" "    ❌ Mutability '${mutability}' should have passed validation"
                ((tests_failed++))
            fi
        fi
    done

    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "  ✅ Image tag mutability validation tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "  ❌ Image tag mutability validation tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

test_replication_validation() {
    print_status "$BLUE" "  Testing replication validation..."

    # Test valid replication configuration
    cat > "$TEMP_DIR/test-replication-valid.tfvars" << EOF
project_name = "test-replication"
environment  = "dev"
app         = "sample"

enable_replication = true
replication_destinations = ["us-east-1", "us-west-2"]

common_tags = {
  Project     = "test-replication"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Test invalid replication configuration (empty destinations)
    cat > "$TEMP_DIR/test-replication-invalid.tfvars" << EOF
project_name = "test-replication"
environment  = "dev"
app         = "sample"

enable_replication = true
replication_destinations = []

common_tags = {
  Project     = "test-replication"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    local tests_passed=0
    local tests_failed=0

    # Test valid configuration
    if terraform validate -var-file="$TEMP_DIR/test-replication-valid.tfvars" > /dev/null 2>&1; then
        print_status "$GREEN" "    ✅ Valid replication configuration passed validation"
        ((tests_passed++))
    else
        print_status "$RED" "    ❌ Valid replication configuration failed validation"
        ((tests_failed++))
    fi

    # Test invalid configuration (this should still pass validation as it's a runtime check)
    if terraform validate -var-file="$TEMP_DIR/test-replication-invalid.tfvars" > /dev/null 2>&1; then
        print_status "$GREEN" "    ✅ Invalid replication configuration handled gracefully"
        ((tests_passed++))
    else
        print_status "$RED" "    ❌ Invalid replication configuration should be handled gracefully"
        ((tests_failed++))
    fi

    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "  ✅ Replication validation tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "  ❌ Replication validation tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running variables validation tests..."

    local tests_passed=0
    local tests_failed=0

    # Test environment validation
    if test_environment_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test encryption validation
    if test_encryption_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test image tag mutability validation
    if test_image_tag_mutability_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test replication validation
    if test_replication_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All variables validation tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some variables validation tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
