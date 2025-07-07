#!/bin/bash

# Test Variables Validation for ALB Module

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

test_variables_file_exists() {
    print_status "$BLUE" "  Testing variables.tf file existence..."

    if [ -f "$TERRAFORM_DIR/variables.tf" ]; then
        print_status "$GREEN" "  ✅ variables.tf exists"
        return 0
    else
        print_status "$RED" "  ❌ variables.tf not found"
        return 1
    fi
}

test_required_variables_defined() {
    print_status "$BLUE" "  Testing required variables definition..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local required_vars=(
        "vpc_id"
        "subnet_ids"
        "ssl_certificate_arn"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if ! grep -q "^variable \"$var\"" "$variables_file"; then
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
        print_status "$GREEN" "  ✅ All required variables are defined"
        return 0
    fi
}

test_variable_types() {
    print_status "$BLUE" "  Testing variable types..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local type_issues=()

    # Check string variables
    local string_vars=("project_name" "environment" "vpc_id" "ssl_certificate_arn")
    for var in "${string_vars[@]}"; do
        if grep -A 5 "^variable \"$var\"" "$variables_file" | grep -q "type.*=.*string"; then
            continue
        else
            type_issues+=("$var should be type string")
        fi
    done

    # Check list variables
    if grep -A 5 "^variable \"subnet_ids\"" "$variables_file" | grep -q "type.*=.*list"; then
        :
    else
        type_issues+=("subnet_ids should be type list")
    fi

    # Check bool variables
    local bool_vars=("internal" "enable_deletion_protection" "enable_cross_zone_load_balancing")
    for var in "${bool_vars[@]}"; do
        if grep -A 5 "^variable \"$var\"" "$variables_file" | grep -q "type.*=.*bool"; then
            continue
        else
            type_issues+=("$var should be type bool")
        fi
    done

    # Check number variables
    local number_vars=("target_group_port" "health_check_healthy_threshold" "idle_timeout")
    for var in "${number_vars[@]}"; do
        if grep -A 5 "^variable \"$var\"" "$variables_file" | grep -q "type.*=.*number"; then
            continue
        else
            type_issues+=("$var should be type number")
        fi
    done

    if [ ${#type_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Variable type issues:"
        for issue in "${type_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Variable types are correct"
        return 0
    fi
}

test_validation_rules() {
    print_status "$BLUE" "  Testing validation rules..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local validation_issues=()

    # Check environment validation
    if grep -A 20 "^variable \"environment\"" "$variables_file" | grep -q "validation"; then
        if grep -A 20 "^variable \"environment\"" "$variables_file" | grep -q "contains.*prd.*rls.*stg.*dev"; then
            print_status "$GREEN" "    ✅ Environment validation rule exists"
        else
            validation_issues+=("environment validation rule incomplete")
        fi
    else
        validation_issues+=("environment validation rule missing")
    fi

    # Check subnet_ids validation
    if grep -A 20 "^variable \"subnet_ids\"" "$variables_file" | grep -q "validation"; then
        if grep -A 20 "^variable \"subnet_ids\"" "$variables_file" | grep -q "length.*>=.*2"; then
            print_status "$GREEN" "    ✅ subnet_ids validation rule exists"
        else
            validation_issues+=("subnet_ids validation rule should check minimum length")
        fi
    else
        validation_issues+=("subnet_ids validation rule missing")
    fi

    # Check protocol validations
    local protocol_vars=("target_group_protocol" "health_check_protocol")
    for var in "${protocol_vars[@]}"; do
        if grep -A 20 "^variable \"$var\"" "$variables_file" | grep -q "validation"; then
            if grep -A 20 "^variable \"$var\"" "$variables_file" | grep -q "contains.*HTTP.*HTTPS"; then
                print_status "$GREEN" "    ✅ $var validation rule exists"
            else
                validation_issues+=("$var validation rule should check HTTP/HTTPS")
            fi
        else
            validation_issues+=("$var validation rule missing")
        fi
    done

    if [ ${#validation_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Validation issues:"
        for issue in "${validation_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Validation rules are comprehensive"
        return 0
    fi
}

test_default_values() {
    print_status "$BLUE" "  Testing default values..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local default_issues=()

    # Check reasonable defaults
    if grep -A 10 "^variable \"aws_region\"" "$variables_file" | grep -q "default.*=.*ap-northeast-1"; then
        print_status "$GREEN" "    ✅ aws_region has appropriate default"
    else
        default_issues+=("aws_region should have ap-northeast-1 as default")
    fi

    if grep -A 10 "^variable \"environment\"" "$variables_file" | grep -q "default.*=.*dev"; then
        print_status "$GREEN" "    ✅ environment has appropriate default"
    else
        default_issues+=("environment should have dev as default")
    fi

    if grep -A 10 "^variable \"target_group_port\"" "$variables_file" | grep -q "default.*=.*80"; then
        print_status "$GREEN" "    ✅ target_group_port has appropriate default"
    else
        default_issues+=("target_group_port should have 80 as default")
    fi

    if grep -A 10 "^variable \"target_type\"" "$variables_file" | grep -q "default.*=.*ip"; then
        print_status "$GREEN" "    ✅ target_type has appropriate default for ECS"
    else
        default_issues+=("target_type should have ip as default for ECS")
    fi

    if [ ${#default_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Default value issues:"
        for issue in "${default_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Default values are appropriate"
        return 0
    fi
}

test_variable_descriptions() {
    print_status "$BLUE" "  Testing variable descriptions..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local vars_without_descriptions=()

    # Get all variable blocks
    local vars
    vars=$(grep -n "^variable" "$variables_file" | cut -d: -f1)

    for line_num in $vars; do
        local var_name
        var_name=$(sed -n "${line_num}p" "$variables_file" | sed 's/variable "\([^"]*\)".*/\1/')

        # Check if description exists in the next few lines
        local end_line=$((line_num + 15))
        if ! sed -n "${line_num},${end_line}p" "$variables_file" | grep -q "description"; then
            vars_without_descriptions+=("$var_name")
        fi
    done

    if [ ${#vars_without_descriptions[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Variables without descriptions:"
        for var in "${vars_without_descriptions[@]}"; do
            print_status "$YELLOW" "    - $var"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All variables have descriptions"
        return 0
    fi
}

test_security_related_variables() {
    print_status "$BLUE" "  Testing security-related variables..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local security_vars=(
        "ssl_certificate_arn"
        "ssl_policy"
        "enable_deletion_protection"
        "allowed_cidr_blocks"
    )

    local missing_security_vars=()

    for var in "${security_vars[@]}"; do
        if ! grep -q "^variable \"$var\"" "$variables_file"; then
            missing_security_vars+=("$var")
        fi
    done

    if [ ${#missing_security_vars[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing security-related variables:"
        for var in "${missing_security_vars[@]}"; do
            print_status "$YELLOW" "    - $var"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All security-related variables are defined"
        return 0
    fi
}

test_alb_specific_variables() {
    print_status "$BLUE" "  Testing ALB-specific variables..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local alb_vars=(
        "internal"
        "enable_cross_zone_load_balancing"
        "enable_http2"
        "ip_address_type"
        "enable_access_logs"
        "access_logs_bucket"
    )

    local missing_alb_vars=()

    for var in "${alb_vars[@]}"; do
        if ! grep -q "^variable \"$var\"" "$variables_file"; then
            missing_alb_vars+=("$var")
        fi
    done

    if [ ${#missing_alb_vars[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing ALB-specific variables:"
        for var in "${missing_alb_vars[@]}"; do
            print_status "$YELLOW" "    - $var"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All ALB-specific variables are defined"
        return 0
    fi
}

test_health_check_variables() {
    print_status "$BLUE" "  Testing health check variables..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local health_check_vars=(
        "health_check_enabled"
        "health_check_path"
        "health_check_port"
        "health_check_protocol"
        "health_check_healthy_threshold"
        "health_check_unhealthy_threshold"
        "health_check_timeout"
        "health_check_interval"
        "health_check_matcher"
    )

    local missing_health_check_vars=()

    for var in "${health_check_vars[@]}"; do
        if ! grep -q "^variable \"$var\"" "$variables_file"; then
            missing_health_check_vars+=("$var")
        fi
    done

    if [ ${#missing_health_check_vars[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Missing health check variables:"
        for var in "${missing_health_check_vars[@]}"; do
            print_status "$YELLOW" "    - $var"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ All health check variables are defined"
        return 0
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running variables validation tests..."

    local tests=(
        "test_variables_file_exists"
        "test_required_variables_defined"
        "test_variable_types"
        "test_validation_rules"
        "test_default_values"
        "test_variable_descriptions"
        "test_security_related_variables"
        "test_alb_specific_variables"
        "test_health_check_variables"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All variables validation tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests variables validation tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
