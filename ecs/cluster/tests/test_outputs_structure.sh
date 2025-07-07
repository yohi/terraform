#!/bin/bash

# Test Output Structure for ECS Cluster Module

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

test_outputs_structure() {
    print_status "$BLUE" "  Testing outputs structure..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local expected_outputs=(
        "cluster_id"
        "cluster_name"
        "cluster_arn"
        "cluster_capacity_providers"
        "cluster_default_capacity_provider_strategy"
        "cluster_configuration"
        "cluster_service_connect_defaults"
        "cluster_tags"
        "cluster_tags_all"
        "execute_command_log_group_name"
        "execute_command_log_group_arn"
        "execute_command_log_group_retention_in_days"
    )

    local missing_outputs=()
    for output in "${expected_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$outputs_file"; then
            missing_outputs+=("$output")
        fi
    done

    if [ ${#missing_outputs[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All expected outputs are defined"
        return 0
    else
        print_status "$RED" "  ❌ Missing outputs:"
        for output in "${missing_outputs[@]}"; do
            print_status "$RED" "    - $output"
        done
        return 1
    fi
}

test_output_values() {
    print_status "$BLUE" "  Testing output values..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local outputs_with_incorrect_values=()

    # Check if outputs reference correct resources
    local expected_patterns=(
        "cluster_id:aws_ecs_cluster.main.id"
        "cluster_name:aws_ecs_cluster.main.name"
        "cluster_arn:aws_ecs_cluster.main.arn"
        "cluster_capacity_providers:aws_ecs_cluster_capacity_providers.main.capacity_providers"
        "cluster_default_capacity_provider_strategy:aws_ecs_cluster_capacity_providers.main.default_capacity_provider_strategy"
        "cluster_configuration:aws_ecs_cluster.main.configuration"
        "cluster_service_connect_defaults:aws_ecs_cluster.main.service_connect_defaults"
        "cluster_tags:aws_ecs_cluster.main.tags"
        "cluster_tags_all:aws_ecs_cluster.main.tags_all"
    )

    for pattern in "${expected_patterns[@]}"; do
        local output_name="${pattern%:*}"
        local expected_value="${pattern#*:}"

        if ! grep -A 5 "^output \"$output_name\"" "$outputs_file" | grep -q "$expected_value"; then
            outputs_with_incorrect_values+=("$output_name")
        fi
    done

    if [ ${#outputs_with_incorrect_values[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All outputs have correct values"
        return 0
    else
        print_status "$RED" "  ❌ Outputs with incorrect values:"
        for output in "${outputs_with_incorrect_values[@]}"; do
            print_status "$RED" "    - $output"
        done
        return 1
    fi
}

test_output_descriptions() {
    print_status "$BLUE" "  Testing output descriptions..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local outputs_without_description=()

    # Extract output names and check for descriptions
    while read -r line; do
        if [[ $line =~ ^output[[:space:]]+\"([^\"]+)\" ]]; then
            local output_name="${BASH_REMATCH[1]}"
            # Check if description exists for this output
            if ! awk -v output="$output_name" '
                /^output[[:space:]]+\"/ {
                    current_output = $0
                    gsub(/^output[[:space:]]+\"/, "", current_output)
                    gsub(/\".*$/, "", current_output)
                    in_output = (current_output == output)
                    found_description = 0
                }
                in_output && /description[[:space:]]*=/ { found_description = 1 }
                /^output[[:space:]]+\"/ && current_output != output {
                    if (in_output && !found_description) print output
                    in_output = 0
                }
                END {
                    if (in_output && !found_description) print output
                }
            ' "$outputs_file" | grep -q "^$output_name$"; then
                continue
            else
                outputs_without_description+=("$output_name")
            fi
        fi
    done < "$outputs_file"

    if [ ${#outputs_without_description[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All outputs have descriptions"
        return 0
    else
        print_status "$RED" "  ❌ Outputs without descriptions:"
        for output in "${outputs_without_description[@]}"; do
            print_status "$RED" "    - $output"
        done
        return 1
    fi
}

test_output_types() {
    print_status "$BLUE" "  Testing output types..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local outputs_without_type=()

    # Extract output names and check for types
    while read -r line; do
        if [[ $line =~ ^output[[:space:]]+\"([^\"]+)\" ]]; then
            local output_name="${BASH_REMATCH[1]}"
            # Check if type exists for this output (optional but recommended)
            if ! awk -v output="$output_name" '
                /^output[[:space:]]+\"/ {
                    current_output = $0
                    gsub(/^output[[:space:]]+\"/, "", current_output)
                    gsub(/\".*$/, "", current_output)
                    in_output = (current_output == output)
                    found_type = 0
                }
                in_output && /type[[:space:]]*=/ { found_type = 1 }
                /^output[[:space:]]+\"/ && current_output != output {
                    if (in_output && !found_type) print output
                    in_output = 0
                }
                END {
                    if (in_output && !found_type) print output
                }
            ' "$outputs_file" | grep -q "^$output_name$"; then
                continue
            else
                outputs_without_type+=("$output_name")
            fi
        fi
    done < "$outputs_file"

    # Note: Type annotation is optional but recommended for clarity
    if [ ${#outputs_without_type[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All outputs have type annotations"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Outputs without type annotations (recommended but optional):"
        for output in "${outputs_without_type[@]}"; do
            print_status "$YELLOW" "    - $output"
        done
        return 0  # This is a warning, not an error
    fi
}

test_conditional_outputs() {
    print_status "$BLUE" "  Testing conditional outputs..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"
    local conditional_outputs=(
        "execute_command_log_group_name"
        "execute_command_log_group_arn"
        "execute_command_log_group_retention_in_days"
    )

    local missing_conditional_logic=()
    for output in "${conditional_outputs[@]}"; do
        # Check if conditional logic exists for log group outputs
        if ! grep -A 10 "^output \"$output\"" "$outputs_file" | grep -q "try\|length\|count"; then
            missing_conditional_logic+=("$output")
        fi
    done

    if [ ${#missing_conditional_logic[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All conditional outputs have proper logic"
        return 0
    else
        print_status "$RED" "  ❌ Conditional outputs without proper logic:"
        for output in "${missing_conditional_logic[@]}"; do
            print_status "$RED" "    - $output"
        done
        return 1
    fi
}

test_output_formatting() {
    print_status "$BLUE" "  Testing output formatting..."

    local outputs_file="$TERRAFORM_DIR/outputs.tf"

    # Check if file follows consistent formatting
    if ! terraform fmt -check=true -diff=false "$outputs_file" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Output file formatting is inconsistent"
        return 1
    fi

    print_status "$GREEN" "  ✅ Output file formatting is consistent"
    return 0
}

# Run tests
main() {
    print_status "$BLUE" "Running output structure tests for ECS Cluster Module..."

    local failed_tests=0

    # Run all tests
    test_outputs_structure || ((failed_tests++))
    test_output_values || ((failed_tests++))
    test_output_descriptions || ((failed_tests++))
    test_output_types || ((failed_tests++))
    test_conditional_outputs || ((failed_tests++))
    test_output_formatting || ((failed_tests++))

    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All output structure tests passed!"
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
