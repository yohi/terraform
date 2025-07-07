#!/bin/bash

# Test tfvars.example for ECS Cluster Module

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

test_tfvars_example_exists() {
    print_status "$BLUE" "  Testing terraform.tfvars.example existence..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"

    if [ -f "$tfvars_example_file" ]; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example exists"
        return 0
    else
        print_status "$RED" "  ❌ terraform.tfvars.example not found"
        return 1
    fi
}

test_tfvars_example_syntax() {
    print_status "$BLUE" "  Testing terraform.tfvars.example syntax..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Copy example file to test syntax
    cp "$tfvars_example_file" "$TEMP_DIR/test.tfvars"

    # Initialize Terraform
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi

    # Test syntax by running plan
    if terraform plan -var-file="$TEMP_DIR/test.tfvars" > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ terraform.tfvars.example syntax is valid"
        return 0
    else
        print_status "$RED" "  ❌ terraform.tfvars.example has syntax errors"
        return 1
    fi
}

test_required_variables_coverage() {
    print_status "$BLUE" "  Testing required variables coverage..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local variables_file="$TERRAFORM_DIR/variables.tf"

    # Extract required variables (variables without default values)
    local required_variables=()
    while read -r line; do
        if [[ $line =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
            local var_name="${BASH_REMATCH[1]}"
            # Check if variable has no default value
            if ! awk -v var="$var_name" '
                /^variable[[:space:]]+\"/ {
                    current_var = $0
                    gsub(/^variable[[:space:]]+\"/, "", current_var)
                    gsub(/\".*$/, "", current_var)
                    in_var = (current_var == var)
                    found_default = 0
                }
                in_var && /default[[:space:]]*=/ { found_default = 1 }
                /^variable[[:space:]]+\"/ && current_var != var {
                    if (in_var && !found_default) print var
                    in_var = 0
                }
                END {
                    if (in_var && !found_default) print var
                }
            ' "$variables_file" | grep -q "^$var_name$"; then
                continue
            else
                required_variables+=("$var_name")
            fi
        fi
    done < "$variables_file"

    # Check if all required variables are covered in tfvars.example
    local missing_variables=()
    for var in "${required_variables[@]}"; do
        if ! grep -q "^$var[[:space:]]*=" "$tfvars_example_file" && ! grep -q "^#[[:space:]]*$var[[:space:]]*=" "$tfvars_example_file"; then
            missing_variables+=("$var")
        fi
    done

    if [ ${#missing_variables[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required variables are covered in tfvars.example"
        return 0
    else
        print_status "$RED" "  ❌ Missing required variables in tfvars.example:"
        for var in "${missing_variables[@]}"; do
            print_status "$RED" "    - $var"
        done
        return 1
    fi
}

test_optional_variables_coverage() {
    print_status "$BLUE" "  Testing optional variables coverage..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local variables_file="$TERRAFORM_DIR/variables.tf"

    # Extract optional variables (variables with default values)
    local optional_variables=()
    while read -r line; do
        if [[ $line =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
            local var_name="${BASH_REMATCH[1]}"
            # Check if variable has default value
            if awk -v var="$var_name" '
                /^variable[[:space:]]+\"/ {
                    current_var = $0
                    gsub(/^variable[[:space:]]+\"/, "", current_var)
                    gsub(/\".*$/, "", current_var)
                    in_var = (current_var == var)
                    found_default = 0
                }
                in_var && /default[[:space:]]*=/ { found_default = 1 }
                /^variable[[:space:]]+\"/ && current_var != var {
                    if (in_var && found_default) print var
                    in_var = 0
                }
                END {
                    if (in_var && found_default) print var
                }
            ' "$variables_file" | grep -q "^$var_name$"; then
                optional_variables+=("$var_name")
            fi
        fi
    done < "$variables_file"

    # Check coverage of optional variables (should be commented out)
    local covered_optional=0
    for var in "${optional_variables[@]}"; do
        if grep -q "^#[[:space:]]*$var[[:space:]]*=" "$tfvars_example_file"; then
            ((covered_optional++))
        fi
    done

    local coverage_percentage=$((covered_optional * 100 / ${#optional_variables[@]}))

    if [ $coverage_percentage -ge 80 ]; then
        print_status "$GREEN" "  ✅ Good coverage of optional variables: $coverage_percentage%"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Low coverage of optional variables: $coverage_percentage%"
        return 0  # This is a warning, not an error
    fi
}

test_example_values() {
    print_status "$BLUE" "  Testing example values..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local issues=()

    # Check for placeholder values that should be replaced
    if grep -q "CHANGE_ME\|REPLACE_ME\|YOUR_VALUE_HERE" "$tfvars_example_file"; then
        issues+=("Contains placeholder values that should be replaced")
    fi

    # Check for realistic example values
    if ! grep -q "project_name.*=" "$tfvars_example_file"; then
        issues+=("Missing project_name example")
    fi

    if ! grep -q "environment.*=" "$tfvars_example_file"; then
        issues+=("Missing environment example")
    fi

    if ! grep -q "common_tags.*=" "$tfvars_example_file"; then
        issues+=("Missing common_tags example")
    fi

    # Check for valid environment values
    if grep -q "environment.*=" "$tfvars_example_file"; then
        local env_value
        env_value=$(grep "environment.*=" "$tfvars_example_file" | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')
        if [[ ! "$env_value" =~ ^(dev|staging|prod|test)$ ]]; then
            issues+=("Environment value '$env_value' is not a common environment name")
        fi
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ Example values are appropriate"
        return 0
    else
        print_status "$RED" "  ❌ Issues with example values:"
        for issue in "${issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    fi
}

test_documentation_in_tfvars() {
    print_status "$BLUE" "  Testing documentation in tfvars.example..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local documentation_issues=()

    # Check for header comments
    if ! head -n 10 "$tfvars_example_file" | grep -q "^#"; then
        documentation_issues+=("Missing header documentation")
    fi

    # Check for section comments
    if ! grep -q "^#.*ECS.*[Cc]luster" "$tfvars_example_file"; then
        documentation_issues+=("Missing ECS cluster section documentation")
    fi

    # Check for inline comments explaining complex configurations
    if grep -q "capacity_providers\|default_capacity_provider_strategy" "$tfvars_example_file"; then
        if ! grep -A 5 -B 5 "capacity_providers\|default_capacity_provider_strategy" "$tfvars_example_file" | grep -q "^#"; then
            documentation_issues+=("Missing documentation for capacity provider configuration")
        fi
    fi

    if [ ${#documentation_issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ Documentation in tfvars.example is adequate"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Documentation could be improved:"
        for issue in "${documentation_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # This is a warning, not an error
    fi
}

test_configuration_examples() {
    print_status "$BLUE" "  Testing configuration examples..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local config_issues=()

    # Check for multiple configuration scenarios
    if ! grep -q "# Basic configuration\|# Advanced configuration\|# Example" "$tfvars_example_file"; then
        config_issues+=("Missing configuration scenario examples")
    fi

    # Check for capacity provider strategy examples
    if grep -q "default_capacity_provider_strategy" "$tfvars_example_file"; then
        if ! grep -A 15 "default_capacity_provider_strategy" "$tfvars_example_file" | grep -q "capacity_provider.*weight.*base"; then
            config_issues+=("Incomplete capacity provider strategy example")
        fi
    fi

    # Check for Service Connect example
    if grep -q "enable_service_connect" "$tfvars_example_file"; then
        if ! grep -A 5 -B 5 "enable_service_connect" "$tfvars_example_file" | grep -q "service_connect_namespace"; then
            config_issues+=("Missing complete Service Connect configuration example")
        fi
    fi

    if [ ${#config_issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ Configuration examples are comprehensive"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Configuration examples could be improved:"
        for issue in "${config_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # This is a warning, not an error
    fi
}

test_tfvars_formatting() {
    print_status "$BLUE" "  Testing tfvars.example formatting..."

    local tfvars_example_file="$TERRAFORM_DIR/terraform.tfvars.example"
    local formatting_issues=()

    # Check for consistent indentation
    if grep -q "^[[:space:]]\+[^[:space:]#]" "$tfvars_example_file"; then
        # Check if indentation is consistent (2 or 4 spaces)
        local indent_pattern=$(grep "^[[:space:]]\+[^[:space:]#]" "$tfvars_example_file" | head -1 | sed 's/\([[:space:]]*\).*/\1/')
        if ! grep -q "^${indent_pattern}[^[:space:]#]" "$tfvars_example_file"; then
            formatting_issues+=("Inconsistent indentation")
        fi
    fi

    # Check for proper alignment of equals signs
    if grep -q "=" "$tfvars_example_file"; then
        local max_var_length=0
        while read -r line; do
            if [[ $line =~ ^[[:space:]]*([^[:space:]#=]+)[[:space:]]*= ]]; then
                local var_name="${BASH_REMATCH[1]}"
                if [ ${#var_name} -gt $max_var_length ]; then
                    max_var_length=${#var_name}
                fi
            fi
        done < "$tfvars_example_file"

        # This is just a formatting preference, not a strict requirement
        print_status "$BLUE" "  ℹ️  Variable name alignment could be optimized (max length: $max_var_length)"
    fi

    if [ ${#formatting_issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ tfvars.example formatting is consistent"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Formatting issues:"
        for issue in "${formatting_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # This is a warning, not an error
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running tfvars.example tests for ECS Cluster Module..."

    local failed_tests=0

    # Run all tests
    test_tfvars_example_exists || ((failed_tests++))
    test_tfvars_example_syntax || ((failed_tests++))
    test_required_variables_coverage || ((failed_tests++))
    test_optional_variables_coverage || ((failed_tests++))
    test_example_values || ((failed_tests++))
    test_documentation_in_tfvars || ((failed_tests++))
    test_configuration_examples || ((failed_tests++))
    test_tfvars_formatting || ((failed_tests++))

    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All tfvars.example tests passed!"
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
