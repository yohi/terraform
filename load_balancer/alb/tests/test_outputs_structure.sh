#!/bin/bash

# Test Output Structure for ALB Module

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

test_outputs_file_exists() {
    print_status "$BLUE" "  Testing outputs.tf file existence..."

    if [ -f "$TERRAFORM_DIR/outputs.tf" ]; then
        print_status "$GREEN" "  ✅ outputs.tf exists"
        return 0
    else
        print_status "$RED" "  ❌ outputs.tf not found"
        return 1
    fi
}

test_required_outputs_exist() {
    print_status "$BLUE" "  Testing required outputs exist..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local required_outputs=(
        "alb_id"
        "alb_arn"
        "alb_dns_name"
        "target_group_id"
        "target_group_arn"
        "security_group_id"
        "load_balancer_url"
    )

    local missing_outputs=()

    for output in "${required_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_outputs+=("$output")
        fi
    done

    if [ ${#missing_outputs[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Missing required outputs:"
        for output in "${missing_outputs[@]}"; do
            print_status "$RED" "    - $output"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ All required outputs exist"
        return 0
    fi
}

test_alb_outputs_structure() {
    print_status "$BLUE" "  Testing ALB outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local alb_outputs=(
        "alb_id"
        "alb_arn"
        "alb_arn_suffix"
        "alb_name"
        "alb_dns_name"
        "alb_zone_id"
    )

    local missing_alb_outputs=()

    for output in "${alb_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_alb_outputs+=("$output")
        fi
    done

    if [ ${#missing_alb_outputs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing ALB outputs:"
        for output in "${missing_alb_outputs[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All ALB outputs are properly structured"
        return 0
    fi
}

test_target_group_outputs_structure() {
    print_status "$BLUE" "  Testing target group outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local tg_outputs=(
        "target_group_id"
        "target_group_arn"
        "target_group_arn_suffix"
        "target_group_name"
    )

    local missing_tg_outputs=()

    for output in "${tg_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_tg_outputs+=("$output")
        fi
    done

    if [ ${#missing_tg_outputs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing target group outputs:"
        for output in "${missing_tg_outputs[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All target group outputs are properly structured"
        return 0
    fi
}

test_listener_outputs_structure() {
    print_status "$BLUE" "  Testing listener outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local listener_outputs=(
        "http_listener_id"
        "http_listener_arn"
        "https_listener_id"
        "https_listener_arn"
    )

    local missing_listener_outputs=()

    for output in "${listener_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_listener_outputs+=("$output")
        fi
    done

    if [ ${#missing_listener_outputs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing listener outputs:"
        for output in "${missing_listener_outputs[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All listener outputs are properly structured"
        return 0
    fi
}

test_security_group_outputs_structure() {
    print_status "$BLUE" "  Testing security group outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local sg_outputs=(
        "security_group_id"
        "security_group_arn"
        "security_group_name"
    )

    local missing_sg_outputs=()

    for output in "${sg_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_sg_outputs+=("$output")
        fi
    done

    if [ ${#missing_sg_outputs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing security group outputs:"
        for output in "${missing_sg_outputs[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All security group outputs are properly structured"
        return 0
    fi
}

test_connection_outputs_structure() {
    print_status "$BLUE" "  Testing connection outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local connection_outputs=(
        "load_balancer_url"
        "load_balancer_http_url"
        "load_balancer_endpoint"
    )

    local missing_connection_outputs=()

    for output in "${connection_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_connection_outputs+=("$output")
        fi
    done

    if [ ${#missing_connection_outputs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing connection outputs:"
        for output in "${missing_connection_outputs[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All connection outputs are properly structured"
        return 0
    fi
}

test_output_descriptions() {
    print_status "$BLUE" "  Testing output descriptions..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local outputs_without_descriptions=()

    # Get all output blocks and check for descriptions
    local outputs
    outputs=$(grep -n "^output" "$outputs_file" | cut -d: -f1)

    for line_num in $outputs; do
        local output_name
        output_name=$(sed -n "${line_num}p" "$outputs_file" | sed 's/output "\([^"]*\)".*/\1/')

        # Check if description exists in the next few lines
        local end_line=$((line_num + 5))
        if ! sed -n "${line_num},${end_line}p" "$outputs_file" | grep -q "description"; then
            outputs_without_descriptions+=("$output_name")
        fi
    done

    if [ ${#outputs_without_descriptions[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Outputs without descriptions:"
        for output in "${outputs_without_descriptions[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All outputs have descriptions"
        return 0
    fi
}

test_output_values_format() {
    print_status "$BLUE" "  Testing output values format..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local format_issues=()

    # Check for common format issues
    if grep -q "aws_lb.main.id" "$outputs_file"; then
        if ! grep -q "alb_id" "$outputs_file"; then
            format_issues+=("Missing alb_id output")
        fi
    fi

    if grep -q "aws_lb.main.dns_name" "$outputs_file"; then
        if ! grep -q "alb_dns_name" "$outputs_file"; then
            format_issues+=("Missing alb_dns_name output")
        fi
    fi

    # Check for URL format
    if grep -q "https://\${aws_lb.main.dns_name}" "$outputs_file"; then
        print_status "$GREEN" "  ✅ HTTPS URL format is correct"
    else
        format_issues+=("HTTPS URL format issue")
    fi

    if [ ${#format_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Format issues:"
        for issue in "${format_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Output values format is correct"
        return 0
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running output structure tests..."

    local tests=(
        "test_outputs_file_exists"
        "test_required_outputs_exist"
        "test_alb_outputs_structure"
        "test_target_group_outputs_structure"
        "test_listener_outputs_structure"
        "test_security_group_outputs_structure"
        "test_connection_outputs_structure"
        "test_output_descriptions"
        "test_output_values_format"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All output structure tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests output structure tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
