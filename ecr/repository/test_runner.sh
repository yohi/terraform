#!/bin/bash

# ECR Repository Module Test Runner
# This script runs all tests for the ECR repository module

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
    echo "ECR Repository Module Test Suite"
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
    for tool in terraform aws jq docker; do
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

run_terraform_tests() {
    print_section "Terraform Tests"

    local terraform_dir="terraform"

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
        "./tests/test_terraform_plan.sh" \
        "$AWS_CREDS_MISSING"
}

run_configuration_tests() {
    print_section "Configuration Tests"

    # Test terraform.tfvars.example
    run_test "terraform.tfvars.example syntax" \
        "./tests/test_tfvars_example.sh" \
        false

    # Test variables validation
    run_test "variables validation" \
        "./tests/test_variables_validation.sh" \
        false

    # Test outputs structure
    run_test "outputs structure" \
        "./tests/test_outputs_structure.sh" \
        false
}

run_ecr_specific_tests() {
    print_section "ECR Specific Tests"

    # Test ECR repository creation
    run_test "ECR repository creation test" \
        "./tests/test_ecr_repository_creation.sh" \
        "$AWS_CREDS_MISSING"

    # Test lifecycle policy
    run_test "lifecycle policy validation" \
        "./tests/test_lifecycle_policy.sh" \
        false

    # Test repository policy
    run_test "repository policy validation" \
        "./tests/test_repository_policy.sh" \
        false

    # Test multiple repositories
    run_test "multiple repositories configuration" \
        "./tests/test_multiple_repositories.sh" \
        false

    # Test Docker integration
    run_test "Docker push simulation" \
        "./tests/test_docker_integration.sh" \
        "$AWS_CREDS_MISSING"
}

run_integration_tests() {
    print_section "Integration Tests"

    # Test AWS ECR service availability
    run_test "AWS ECR service availability" \
        "./tests/test_aws_ecr_service.sh" \
        "$AWS_CREDS_MISSING"

    # Test repository naming conventions
    run_test "repository naming conventions" \
        "./tests/test_repository_naming.sh" \
        false

    # Test replication configuration
    run_test "replication configuration" \
        "./tests/test_replication_config.sh" \
        false
}

run_security_tests() {
    print_section "Security Tests"

    # Test encryption configuration
    run_test "encryption configuration" \
        "./tests/test_encryption_config.sh" \
        false

    # Test scan on push
    run_test "scan on push configuration" \
        "./tests/test_scan_config.sh" \
        false

    # Test IAM permissions
    run_test "IAM permissions validation" \
        "./tests/test_iam_permissions.sh" \
        "$AWS_CREDS_MISSING"
}

run_documentation_tests() {
    print_section "Documentation Tests"

    # Check README files exist
    run_test "README files exist" \
        "./tests/test_documentation_exists.sh" \
        false

    # Check markdown syntax
    run_test "markdown syntax" \
        "./tests/test_markdown_syntax.sh" \
        false

    # Check terraform.tfvars.example completeness
    run_test "terraform.tfvars.example completeness" \
        "./tests/test_tfvars_completeness.sh" \
        false
}

print_summary() {
    print_section "Test Summary"

    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        print_status "$GREEN" "🎉 All tests passed!"
        return 0
    else
        print_status "$RED" "❌ Some tests failed. Check the output above for details."
        return 1
    fi
}

main() {
    print_header

    # Check prerequisites
    if ! check_prerequisites; then
        AWS_CREDS_MISSING=true
    else
        AWS_CREDS_MISSING=false
    fi

    # Create tests directory if it doesn't exist
    mkdir -p tests

    # Run all test categories
    run_terraform_tests
    run_configuration_tests
    run_ecr_specific_tests
    run_integration_tests
    run_security_tests
    run_documentation_tests

    # Print summary and exit
    print_summary
    exit $?
}

# Run main function
main "$@"
