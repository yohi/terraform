#!/bin/bash

# Test terraform.tfvars.example for ALB Module

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

test_tfvars_example_exists() {
    print_status "$BLUE" "  Testing terraform.tfvars.example existence..."

    if [ -f "$TERRAFORM_DIR/terraform.tfvars.example" ]; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example exists"
        return 0
    else
        print_status "$RED" "  ❌ terraform.tfvars.example not found"
        return 1
    fi
}

test_tfvars_example_syntax() {
    print_status "$BLUE" "  Testing terraform.tfvars.example syntax..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"

    # Check if file can be parsed as HCL
    if terraform fmt -check=true "$tfvars_file" > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example has valid HCL syntax"
        return 0
    else
        print_status "$RED" "  ❌ terraform.tfvars.example has invalid HCL syntax"
        return 1
    fi
}

test_required_variables_present() {
    print_status "$BLUE" "  Testing required variables presence..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local required_vars=(
        "project_name"
        "environment"
        "vpc_id"
        "subnet_ids"
        "ssl_certificate_arn"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}[[:space:]]*=" "$tfvars_file"; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Missing required variables:"
        for var in "${missing_vars[@]}"; do
            print_status "$RED" "    - $var"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ All required variables are present"
        return 0
    fi
}

test_example_values_validity() {
    print_status "$BLUE" "  Testing example values validity..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local invalid_values=()

    # Check environment value
    if grep -q "environment.*=" "$tfvars_file"; then
        local env_value
        env_value=$(grep "environment.*=" "$tfvars_file" | sed 's/.*=\s*"\([^"]*\)".*/\1/')
        if [[ ! "$env_value" =~ ^(prd|rls|stg|dev)$ ]]; then
            invalid_values+=("environment: '$env_value' should be one of: prd, rls, stg, dev")
        fi
    fi

    # Check VPC ID format
    if grep -q "vpc_id.*=" "$tfvars_file"; then
        local vpc_id
        vpc_id=$(grep "vpc_id.*=" "$tfvars_file" | sed 's/.*=\s*"\([^"]*\)".*/\1/')
        if [[ ! "$vpc_id" =~ ^vpc-[a-z0-9]{8,17}$ ]]; then
            invalid_values+=("vpc_id: '$vpc_id' should follow VPC ID format (vpc-xxxxxxxxx)")
        fi
    fi

    # Check subnet IDs format
    if grep -q "subnet_ids.*=" "$tfvars_file"; then
        local subnet_count
        subnet_count=$(grep -o "subnet-[a-z0-9]*" "$tfvars_file" | wc -l)
        if [ "$subnet_count" -lt 2 ]; then
            invalid_values+=("subnet_ids: should have at least 2 subnets for ALB")
        fi
    fi

    # Check SSL certificate ARN format
    if grep -q "ssl_certificate_arn.*=" "$tfvars_file"; then
        local cert_arn
        cert_arn=$(grep "ssl_certificate_arn.*=" "$tfvars_file" | sed 's/.*=\s*"\([^"]*\)".*/\1/')
        if [[ ! "$cert_arn" =~ ^arn:aws:acm: ]]; then
            invalid_values+=("ssl_certificate_arn: '$cert_arn' should be a valid ACM certificate ARN")
        fi
    fi

    if [ ${#invalid_values[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Invalid example values:"
        for value in "${invalid_values[@]}"; do
            print_status "$YELLOW" "    - $value"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Example values are valid"
        return 0
    fi
}

test_alb_configuration_examples() {
    print_status "$BLUE" "  Testing ALB configuration examples..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local missing_configs=()

    # Check for ALB-specific configurations
    if ! grep -q "internal.*=" "$tfvars_file"; then
        missing_configs+=("internal (ALB type)")
    fi

    if ! grep -q "target_group_port.*=" "$tfvars_file"; then
        missing_configs+=("target_group_port")
    fi

    if ! grep -q "target_group_protocol.*=" "$tfvars_file"; then
        missing_configs+=("target_group_protocol")
    fi

    if ! grep -q "target_type.*=" "$tfvars_file"; then
        missing_configs+=("target_type")
    fi

    if ! grep -q "health_check_path.*=" "$tfvars_file"; then
        missing_configs+=("health_check_path")
    fi

    if [ ${#missing_configs[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing ALB configuration examples:"
        for config in "${missing_configs[@]}"; do
            print_status "$YELLOW" "    - $config"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ ALB configuration examples are comprehensive"
        return 0
    fi
}

test_common_tags_structure() {
    print_status "$BLUE" "  Testing common tags structure..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"

    if grep -q "common_tags.*=" "$tfvars_file"; then
        # Check if common_tags is properly structured
        local tags_section
        tags_section=$(awk '/common_tags.*=/{flag=1} flag && /}/{flag=0} flag' "$tfvars_file")

        if [[ "$tags_section" =~ Project && "$tags_section" =~ Environment && "$tags_section" =~ ManagedBy ]]; then
            print_status "$GREEN" "  ✅ Common tags structure is correct"
            return 0
        else
            print_status "$YELLOW" "  ⚠️  Common tags missing recommended tags (Project, Environment, ManagedBy)"
            return 0
        fi
    else
        print_status "$RED" "  ❌ common_tags not found in example"
        return 1
    fi
}

test_comments_and_documentation() {
    print_status "$BLUE" "  Testing comments and documentation..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local comment_count
    comment_count=$(grep -c "^#" "$tfvars_file" || true)

    if [ "$comment_count" -gt 5 ]; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example has adequate comments ($comment_count lines)"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  terraform.tfvars.example could use more comments for clarity"
        return 0
    fi
}

test_optional_variables_examples() {
    print_status "$BLUE" "  Testing optional variables examples..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local optional_vars_found=()

    # Check for optional variables examples
    if grep -q "enable_deletion_protection.*=" "$tfvars_file"; then
        optional_vars_found+=("enable_deletion_protection")
    fi

    if grep -q "enable_access_logs.*=" "$tfvars_file"; then
        optional_vars_found+=("enable_access_logs")
    fi

    if grep -q "idle_timeout.*=" "$tfvars_file"; then
        optional_vars_found+=("idle_timeout")
    fi

    if grep -q "ip_address_type.*=" "$tfvars_file"; then
        optional_vars_found+=("ip_address_type")
    fi

    if [ ${#optional_vars_found[@]} -gt 0 ]; then
        print_status "$GREEN" "  ✅ Optional variables examples found:"
        for var in "${optional_vars_found[@]}"; do
            print_status "$GREEN" "    - $var"
        done
        return 0
    else
        print_status "$YELLOW" "  ⚠️  No optional variables examples found"
        return 0
    fi
}

test_file_size_and_completeness() {
    print_status "$BLUE" "  Testing file size and completeness..."

    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local line_count
    line_count=$(wc -l < "$tfvars_file")

    if [ "$line_count" -gt 30 ]; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example is comprehensive ($line_count lines)"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  terraform.tfvars.example might be too brief ($line_count lines)"
        return 0
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running terraform.tfvars.example tests..."

    local tests=(
        "test_tfvars_example_exists"
        "test_tfvars_example_syntax"
        "test_required_variables_present"
        "test_example_values_validity"
        "test_alb_configuration_examples"
        "test_common_tags_structure"
        "test_comments_and_documentation"
        "test_optional_variables_examples"
        "test_file_size_and_completeness"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All terraform.tfvars.example tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests terraform.tfvars.example tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
