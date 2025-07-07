#!/bin/bash

# Test terraform.tfvars.example file

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
TFVARS_EXAMPLE_FILE="${TERRAFORM_DIR}/terraform.tfvars.example"

test_tfvars_example_exists() {
    print_status "$BLUE" "  Testing terraform.tfvars.example exists..."

    if [ -f "$TFVARS_EXAMPLE_FILE" ]; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example exists"
        return 0
    else
        print_status "$RED" "  ❌ terraform.tfvars.example not found"
        return 1
    fi
}

test_tfvars_example_syntax() {
    print_status "$BLUE" "  Testing terraform.tfvars.example syntax..."

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Test syntax by trying to use it in a plan
    if terraform init -backend=false > /dev/null 2>&1; then
        if terraform plan -var-file="terraform.tfvars.example" > /dev/null 2>&1; then
            print_status "$GREEN" "  ✅ terraform.tfvars.example has valid syntax"
            return 0
        else
            print_status "$RED" "  ❌ terraform.tfvars.example has syntax errors"
            return 1
        fi
    else
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi
}

test_required_variables() {
    print_status "$BLUE" "  Testing required variables are present..."

    local required_vars=(
        "project_name"
        "environment"
        "common_tags"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var" "$TFVARS_EXAMPLE_FILE"; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required variables are present"
        return 0
    else
        print_status "$RED" "  ❌ Missing required variables: ${missing_vars[*]}"
        return 1
    fi
}

test_example_values() {
    print_status "$BLUE" "  Testing example values are reasonable..."

    local issues=()

    # Check if example values are not obviously wrong
    if grep -q 'project_name = "your-project"' "$TFVARS_EXAMPLE_FILE"; then
        issues+=("project_name should have a more descriptive example")
    fi

    if grep -q 'environment = "???"' "$TFVARS_EXAMPLE_FILE"; then
        issues+=("environment should have a valid example (dev, stg, prd)")
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ Example values are reasonable"
        return 0
    else
        print_status "$RED" "  ❌ Issues with example values:"
        for issue in "${issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running terraform.tfvars.example tests..."

    local tests_passed=0
    local tests_failed=0

    # Test file existence
    if test_tfvars_example_exists; then
        ((tests_passed++))
    else
        ((tests_failed++))
        return 1  # Can't continue without the file
    fi

    # Test syntax
    if test_tfvars_example_syntax; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test required variables
    if test_required_variables; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test example values
    if test_example_values; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All terraform.tfvars.example tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some terraform.tfvars.example tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
