#!/bin/bash

# Test Variables Validation for ECS Cluster Module

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

test_required_variables() {
    print_status "$BLUE" "  Testing required variables..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local required_variables=(
        "project_name"
        "environment"
        "common_tags"
    )

    local missing_required=()
    for var in "${required_variables[@]}"; do
        if ! grep -q "^variable \"$var\"" "$variables_file"; then
            missing_required+=("$var")
        fi
    done

    if [ ${#missing_required[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required variables are defined"
        return 0
    else
        print_status "$RED" "  ❌ Missing required variables:"
        for var in "${missing_required[@]}"; do
            print_status "$RED" "    - $var"
        done
        return 1
    fi
}

test_variable_types() {
    print_status "$BLUE" "  Testing variable types..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local type_errors=()

    # Check specific variable types
    local expected_types=(
        "project_name:string"
        "environment:string"
        "cluster_name:string"
        "capacity_providers:list(string)"
        "default_capacity_provider_strategy:list(object"
        "enable_container_insights:bool"
        "enable_execute_command_logging:bool"
        "enable_service_connect:bool"
        "service_connect_namespace:string"
        "execute_command_log_group_name:string"
        "execute_command_kms_key_id:string"
        "execute_command_s3_bucket_name:string"
        "execute_command_s3_key_prefix:string"
        "log_retention_in_days:number"
        "common_tags:map(string)"
    )

    for type_check in "${expected_types[@]}"; do
        local var_name="${type_check%:*}"
        local expected_type="${type_check#*:}"

        if ! grep -A 10 "^variable \"$var_name\"" "$variables_file" | grep -q "type.*$expected_type"; then
            type_errors+=("$var_name (expected: $expected_type)")
        fi
    done

    if [ ${#type_errors[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All variables have correct types"
        return 0
    else
        print_status "$RED" "  ❌ Variables with incorrect types:"
        for var in "${type_errors[@]}"; do
            print_status "$RED" "    - $var"
        done
        return 1
    fi
}

test_variable_descriptions() {
    print_status "$BLUE" "  Testing variable descriptions..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local variables_without_description=()

    # Extract variable names and check for descriptions
    while read -r line; do
        if [[ $line =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
            local var_name="${BASH_REMATCH[1]}"
            # Check if description exists for this variable
            if ! awk -v var="$var_name" '
                /^variable[[:space:]]+\"/ {
                    current_var = $0
                    gsub(/^variable[[:space:]]+\"/, "", current_var)
                    gsub(/\".*$/, "", current_var)
                    in_var = (current_var == var)
                    found_description = 0
                }
                in_var && /description[[:space:]]*=/ { found_description = 1 }
                /^variable[[:space:]]+\"/ && current_var != var {
                    if (in_var && !found_description) print var
                    in_var = 0
                }
                END {
                    if (in_var && !found_description) print var
                }
            ' "$variables_file" | grep -q "^$var_name$"; then
                continue
            else
                variables_without_description+=("$var_name")
            fi
        fi
    done < "$variables_file"

    if [ ${#variables_without_description[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All variables have descriptions"
        return 0
    else
        print_status "$RED" "  ❌ Variables without descriptions:"
        for var in "${variables_without_description[@]}"; do
            print_status "$RED" "    - $var"
        done
        return 1
    fi
}

test_variable_defaults() {
    print_status "$BLUE" "  Testing variable defaults..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local variables_with_proper_defaults=()

    # Variables that should have meaningful defaults
    local expected_defaults=(
        "cluster_name:\"\""
        "capacity_providers:[\"FARGATE\"]"
        "enable_container_insights:false"
        "enable_execute_command_logging:false"
        "enable_service_connect:false"
        "service_connect_namespace:\"\""
        "execute_command_log_group_name:\"\""
        "execute_command_kms_key_id:\"\""
        "execute_command_s3_bucket_name:\"\""
        "execute_command_s3_key_prefix:\"ecs-exec\""
        "log_retention_in_days:14"
    )

    for default_check in "${expected_defaults[@]}"; do
        local var_name="${default_check%:*}"
        local expected_default="${default_check#*:}"

        if grep -A 15 "^variable \"$var_name\"" "$variables_file" | grep -q "default.*$expected_default"; then
            variables_with_proper_defaults+=("$var_name")
        fi
    done

    if [ ${#variables_with_proper_defaults[@]} -gt 0 ]; then
        print_status "$GREEN" "  ✅ Variables with proper defaults: ${#variables_with_proper_defaults[@]}"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  No variables found with expected defaults (review recommended)"
        return 0
    fi
}

test_variable_validation() {
    print_status "$BLUE" "  Testing variable validation rules..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local variables_with_validation=()

    # Variables that should have validation rules
    local validation_candidates=(
        "environment"
        "log_retention_in_days"
        "capacity_providers"
    )

    for var in "${validation_candidates[@]}"; do
        if grep -A 20 "^variable \"$var\"" "$variables_file" | grep -q "validation[[:space:]]*{"; then
            variables_with_validation+=("$var")
        fi
    done

    if [ ${#variables_with_validation[@]} -gt 0 ]; then
        print_status "$GREEN" "  ✅ Variables with validation rules: ${#variables_with_validation[@]}"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  No variables found with validation rules (recommended for critical variables)"
        return 0
    fi
}

test_sensitive_variables() {
    print_status "$BLUE" "  Testing sensitive variables..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local sensitive_candidates=(
        "execute_command_kms_key_id"
    )

    local properly_marked_sensitive=()
    for var in "${sensitive_candidates[@]}"; do
        if grep -A 15 "^variable \"$var\"" "$variables_file" | grep -q "sensitive[[:space:]]*=[[:space:]]*true"; then
            properly_marked_sensitive+=("$var")
        fi
    done

    # For ECS cluster, sensitive variables are optional, so this is more informational
    if [ ${#properly_marked_sensitive[@]} -gt 0 ]; then
        print_status "$GREEN" "  ✅ Sensitive variables properly marked: ${#properly_marked_sensitive[@]}"
    else
        print_status "$BLUE" "  ℹ️  No sensitive variables found (this is acceptable for ECS cluster)"
    fi
    return 0
}

test_variable_consistency() {
    print_status "$BLUE" "  Testing variable consistency..."

    local variables_file="$TERRAFORM_DIR/variables.tf"
    local main_file="$TERRAFORM_DIR/main.tf"
    local inconsistent_variables=()

    # Check if all variables defined in variables.tf are used in main.tf
    while read -r line; do
        if [[ $line =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
            local var_name="${BASH_REMATCH[1]}"
            # Check if variable is referenced in main.tf
            if ! grep -q "var\.$var_name" "$main_file"; then
                inconsistent_variables+=("$var_name (defined but not used)")
            fi
        fi
    done < "$variables_file"

    if [ ${#inconsistent_variables[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All variables are consistently used"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Potentially unused variables:"
        for var in "${inconsistent_variables[@]}"; do
            print_status "$YELLOW" "    - $var"
        done
        return 0  # This is a warning, not an error
    fi
}

test_complex_variable_structure() {
    print_status "$BLUE" "  Testing complex variable structures..."

    local variables_file="$TERRAFORM_DIR/variables.tf"

    # Test default_capacity_provider_strategy object structure
    if grep -A 20 "^variable \"default_capacity_provider_strategy\"" "$variables_file" | grep -q "list(object"; then
        # Check if object has required fields
        if grep -A 30 "^variable \"default_capacity_provider_strategy\"" "$variables_file" | grep -q "capacity_provider.*string" && \
           grep -A 30 "^variable \"default_capacity_provider_strategy\"" "$variables_file" | grep -q "weight.*number" && \
           grep -A 30 "^variable \"default_capacity_provider_strategy\"" "$variables_file" | grep -q "base.*number"; then
            print_status "$GREEN" "  ✅ Complex variable structures are properly defined"
            return 0
        else
            print_status "$RED" "  ❌ Complex variable structure missing required fields"
            return 1
        fi
    else
        print_status "$RED" "  ❌ Complex variable structure not found"
        return 1
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running variable validation tests for ECS Cluster Module..."

    local failed_tests=0

    # Run all tests
    test_required_variables || ((failed_tests++))
    test_variable_types || ((failed_tests++))
    test_variable_descriptions || ((failed_tests++))
    test_variable_defaults || ((failed_tests++))
    test_variable_validation || ((failed_tests++))
    test_sensitive_variables || ((failed_tests++))
    test_variable_consistency || ((failed_tests++))
    test_complex_variable_structure || ((failed_tests++))

    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All variable validation tests passed!"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests test(s) failed"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
