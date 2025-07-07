#!/bin/bash

# Analytics Test Runner
# This script runs all tests for the analytics infrastructure

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test result tracking
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -i TESTS_SKIPPED=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo "========================================"
    echo "Analytics Infrastructure Test Suite"
    echo "========================================"
    echo ""
}

print_section() {
    echo ""
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

run_test() {
    local test_name=$1
    local test_command=$2
    local skip_condition=${3:-false}

    if [ "$skip_condition" = true ]; then
        print_status "$YELLOW" "⏭️  SKIPPED: $test_name"
        ((TESTS_SKIPPED++))
        return 0
    fi

    print_status "$BLUE" "🔍 Running: $test_name"

    if eval "$test_command"; then
        print_status "$GREEN" "✅ PASSED: $test_name"
        ((TESTS_PASSED++))
    else
        print_status "$RED" "❌ FAILED: $test_name"
        ((TESTS_FAILED++))
    fi
}

check_prerequisites() {
    print_section "Prerequisites Check"

    local missing_tools=()

    # Check required tools
    for tool in terraform aws jq shellcheck; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_status "$RED" "❌ Missing required tools: ${missing_tools[*]}"
        echo "Please install missing tools before running tests."
        exit 1
    fi

    print_status "$GREEN" "✅ All required tools are available"

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_status "$YELLOW" "⚠️  AWS credentials not configured. Some tests will be skipped."
        return 1
    fi

    print_status "$GREEN" "✅ AWS credentials are configured"
    return 0
}

run_script_tests() {
    print_section "Script Tests"

    # Test check_aws_account.sh
    run_test "check_aws_account.sh syntax" \
        "bash -n ../check_aws_account.sh" \
        false

    run_test "check_aws_account.sh shellcheck" \
        "shellcheck ../check_aws_account.sh" \
        false

    # Test athena terraform scripts
    run_test "athena apply_with_confirmation.sh syntax" \
        "bash -n ../athena/terraform/apply_with_confirmation.sh" \
        false

    run_test "athena apply_with_confirmation.sh shellcheck" \
        "shellcheck ../athena/terraform/apply_with_confirmation.sh" \
        false

    run_test "athena plan_with_confirmation.sh syntax" \
        "bash -n ../athena/terraform/plan_with_confirmation.sh" \
        false

    run_test "athena plan_with_confirmation.sh shellcheck" \
        "shellcheck ../athena/terraform/plan_with_confirmation.sh" \
        false

    run_test "athena check_athena_database.sh syntax" \
        "bash -n ../athena/terraform/check_athena_database.sh" \
        false

    run_test "athena s3_bucket_check.sh syntax" \
        "bash -n ../athena/terraform/s3_bucket_check.sh" \
        false

    run_test "athena aws_account_check.sh syntax" \
        "bash -n ../athena/terraform/aws_account_check.sh" \
        false
}

run_terraform_tests() {
    print_section "Terraform Tests"

    local terraform_dir="../athena/terraform"

    # Terraform format check
    run_test "terraform fmt check" \
        "cd $terraform_dir && terraform fmt -check=true -diff=true" \
        false

    # Terraform validation
    run_test "terraform validate" \
        "cd $terraform_dir && terraform init -backend=false && terraform validate" \
        false

    # Terraform plan (dry run)
    run_test "terraform plan (dry run)" \
        "./test_terraform_plan.sh" \
        "$AWS_CREDS_MISSING"
}

run_configuration_tests() {
    print_section "Configuration Tests"

    # Test terraform.tfvars.example
    run_test "terraform.tfvars.example syntax" \
        "./test_tfvars_example.sh" \
        false

    # Test variables validation
    run_test "variables validation" \
        "./test_variables_validation.sh" \
        false

    # Test outputs structure
    run_test "outputs structure" \
        "./test_outputs_structure.sh" \
        false
}

run_integration_tests() {
    print_section "Integration Tests"

    # Test AWS account check flow
    run_test "AWS account check flow" \
        "./test_aws_account_flow.sh" \
        "$AWS_CREDS_MISSING"

    # Test S3 bucket validation
    run_test "S3 bucket validation" \
        "./test_s3_bucket_validation.sh" \
        "$AWS_CREDS_MISSING"
}

run_documentation_tests() {
    print_section "Documentation Tests"

    # Check README files exist
    run_test "README files exist" \
        "./test_documentation_exists.sh" \
        false

    # Check markdown syntax
    run_test "markdown syntax" \
        "./test_markdown_syntax.sh" \
        false
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        print_status "$GREEN" "🎉 All tests passed!"
        exit 0
    else
        print_status "$RED" "❌ Some tests failed!"
        exit 1
    fi
}

main() {
    print_header

    # Change to tests directory
    cd "$(dirname "$0")"

    # Check prerequisites
    AWS_CREDS_MISSING=false
    if ! check_prerequisites; then
        AWS_CREDS_MISSING=true
    fi

    # Run test suites
    run_script_tests
    run_terraform_tests
    run_configuration_tests
    run_integration_tests
    run_documentation_tests

    print_summary
}

# Execute main function
main "$@"
