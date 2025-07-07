#!/bin/bash

# Test Documentation Exists for ALB Module

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
MODULE_DIR="${TEST_DIR}/.."

test_readme_exists() {
    print_status "$BLUE" "  Testing README.md existence..."

    if [ -f "$MODULE_DIR/README.md" ]; then
        print_status "$GREEN" "  ✅ README.md exists"
        return 0
    else
        print_status "$RED" "  ❌ README.md not found"
        return 1
    fi
}

test_readme_content() {
    print_status "$BLUE" "  Testing README.md content..."

    local readme_file="$MODULE_DIR/README.md"
    local missing_sections=()

    # Check for essential sections
    if ! grep -q "# ALB Module" "$readme_file" 2>/dev/null; then
        missing_sections+=("Title/Header")
    fi

    if ! grep -q -i "usage" "$readme_file" 2>/dev/null; then
        missing_sections+=("Usage section")
    fi

    if ! grep -q -i "variable" "$readme_file" 2>/dev/null; then
        missing_sections+=("Variables section")
    fi

    if ! grep -q -i "output" "$readme_file" 2>/dev/null; then
        missing_sections+=("Outputs section")
    fi

    if [ ${#missing_sections[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Missing essential sections in README.md:"
        for section in "${missing_sections[@]}"; do
            print_status "$RED" "    - $section"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ README.md contains essential sections"
        return 0
    fi
}

test_terraform_files_documented() {
    print_status "$BLUE" "  Testing Terraform files documentation..."

    local terraform_dir="$MODULE_DIR/terraform"
    local undocumented_files=()

    # Check if main Terraform files exist
    local essential_files=("main.tf" "variables.tf" "outputs.tf" "versions.tf")

    for file in "${essential_files[@]}"; do
        if [ ! -f "$terraform_dir/$file" ]; then
            undocumented_files+=("$file (missing)")
        fi
    done

    # Check if terraform.tfvars.example exists
    if [ ! -f "$terraform_dir/terraform.tfvars.example" ]; then
        undocumented_files+=("terraform.tfvars.example (missing)")
    fi

    if [ ${#undocumented_files[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Missing essential Terraform files:"
        for file in "${undocumented_files[@]}"; do
            print_status "$RED" "    - $file"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ All essential Terraform files exist"
        return 0
    fi
}

test_variable_descriptions() {
    print_status "$BLUE" "  Testing variable descriptions..."

    local variables_file="$MODULE_DIR/terraform/variables.tf"
    local undescribed_vars=()

    # Extract variable names and check for descriptions
    if [ -f "$variables_file" ]; then
        # Get all variable blocks
        local vars
        vars=$(grep -n "^variable" "$variables_file" | cut -d: -f1)

        for line_num in $vars; do
            local var_name
            var_name=$(sed -n "${line_num}p" "$variables_file" | sed 's/variable "\([^"]*\)".*/\1/')

            # Check if description exists in the next few lines
            local end_line=$((line_num + 10))
            if ! sed -n "${line_num},${end_line}p" "$variables_file" | grep -q "description"; then
                undescribed_vars+=("$var_name")
            fi
        done

        if [ ${#undescribed_vars[@]} -gt 0 ]; then
            print_status "$YELLOW" "  ⚠️  Variables without descriptions:"
            for var in "${undescribed_vars[@]}"; do
                print_status "$YELLOW" "    - $var"
            done
            # This is a warning, not a failure
            return 0
        else
            print_status "$GREEN" "  ✅ All variables have descriptions"
            return 0
        fi
    else
        print_status "$RED" "  ❌ variables.tf not found"
        return 1
    fi
}

test_output_descriptions() {
    print_status "$BLUE" "  Testing output descriptions..."

    local outputs_file="$MODULE_DIR/terraform/outputs.tf"
    local undescribed_outputs=()

    # Extract output names and check for descriptions
    if [ -f "$outputs_file" ]; then
        # Get all output blocks
        local outputs
        outputs=$(grep -n "^output" "$outputs_file" | cut -d: -f1)

        for line_num in $outputs; do
            local output_name
            output_name=$(sed -n "${line_num}p" "$outputs_file" | sed 's/output "\([^"]*\)".*/\1/')

            # Check if description exists in the next few lines
            local end_line=$((line_num + 10))
            if ! sed -n "${line_num},${end_line}p" "$outputs_file" | grep -q "description"; then
                undescribed_outputs+=("$output_name")
            fi
        done

        if [ ${#undescribed_outputs[@]} -gt 0 ]; then
            print_status "$YELLOW" "  ⚠️  Outputs without descriptions:"
            for output in "${undescribed_outputs[@]}"; do
                print_status "$YELLOW" "    - $output"
            done
            # This is a warning, not a failure
            return 0
        else
            print_status "$GREEN" "  ✅ All outputs have descriptions"
            return 0
        fi
    else
        print_status "$RED" "  ❌ outputs.tf not found"
        return 1
    fi
}

test_example_configuration() {
    print_status "$BLUE" "  Testing example configuration..."

    local example_file="$MODULE_DIR/terraform/terraform.tfvars.example"

    if [ -f "$example_file" ]; then
        # Check if example file has reasonable content
        local line_count
        line_count=$(wc -l < "$example_file")

        if [ "$line_count" -gt 10 ]; then
            print_status "$GREEN" "  ✅ Example configuration file exists and has content"
            return 0
        else
            print_status "$YELLOW" "  ⚠️  Example configuration file is too short"
            return 0
        fi
    else
        print_status "$RED" "  ❌ terraform.tfvars.example not found"
        return 1
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running documentation existence tests..."

    local tests=(
        "test_readme_exists"
        "test_readme_content"
        "test_terraform_files_documented"
        "test_variable_descriptions"
        "test_output_descriptions"
        "test_example_configuration"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All documentation tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests documentation tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
