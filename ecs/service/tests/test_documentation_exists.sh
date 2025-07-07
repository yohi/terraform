#!/bin/bash

# Test Documentation Exists for ECS Service Module

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
    local required_sections=(
        "# ECS Service Module"
        "## Overview"
        "## Usage"
        "## Inputs"
        "## Outputs"
        "## Examples"
        "## Container Configuration"
        "## Load Balancer Integration"
        "## Auto Scaling"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section" "$readme_file"; then
            missing_sections+=("$section")
        fi
    done

    if [ ${#missing_sections[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required sections found in README.md"
        return 0
    else
        print_status "$RED" "  ❌ Missing sections in README.md:"
        for section in "${missing_sections[@]}"; do
            print_status "$RED" "    - $section"
        done
        return 1
    fi
}

test_terraform_files_exist() {
    print_status "$BLUE" "  Testing Terraform files existence..."

    local terraform_dir="$MODULE_DIR/terraform"
    local required_files=(
        "main.tf"
        "variables.tf"
        "outputs.tf"
        "versions.tf"
        "terraform.tfvars.example"
    )

    local missing_files=()
    for file in "${required_files[@]}"; do
        if [ ! -f "$terraform_dir/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required Terraform files exist"
        return 0
    else
        print_status "$RED" "  ❌ Missing Terraform files:"
        for file in "${missing_files[@]}"; do
            print_status "$RED" "    - $file"
        done
        return 1
    fi
}

test_templates_directory() {
    print_status "$BLUE" "  Testing templates directory..."

    local templates_dir="$MODULE_DIR/templates"

    if [ -d "$templates_dir" ]; then
        print_status "$GREEN" "  ✅ Templates directory exists"

        # Check if it's empty or has content
        if [ -z "$(ls -A "$templates_dir")" ]; then
            print_status "$YELLOW" "  ⚠️  Templates directory is empty"
        else
            print_status "$GREEN" "  ✅ Templates directory contains files"
        fi
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Templates directory does not exist (optional)"
        return 0
    fi
}

test_terraform_syntax() {
    print_status "$BLUE" "  Testing Terraform syntax..."

    local terraform_dir="$MODULE_DIR/terraform"

    # Change to terraform directory
    cd "$terraform_dir"

    # Check Terraform syntax
    if terraform fmt -check=true -diff=false > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ Terraform syntax is valid"
        return 0
    else
        print_status "$RED" "  ❌ Terraform syntax errors detected"
        return 1
    fi
}

test_terraform_validation() {
    print_status "$BLUE" "  Testing Terraform validation..."

    local terraform_dir="$MODULE_DIR/terraform"

    # Change to terraform directory
    cd "$terraform_dir"

    # Initialize Terraform
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi

    # Validate Terraform configuration
    if terraform validate > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ Terraform configuration is valid"
        return 0
    else
        print_status "$RED" "  ❌ Terraform validation failed"
        return 1
    fi
}

test_variable_descriptions() {
    print_status "$BLUE" "  Testing variable descriptions..."

    local variables_file="$MODULE_DIR/terraform/variables.tf"
    local variables_without_description=()

    # Extract variable names that don't have descriptions
    while read -r line; do
        if [[ $line =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
            local var_name="${BASH_REMATCH[1]}"
            # Check if description exists for this variable
            if ! awk -v var="$var_name" '
                /^variable[[:space:]]+\"/ { current_var = $0; gsub(/^variable[[:space:]]+\"/, "", current_var); gsub(/\".*$/, "", current_var) }
                current_var == var && /description[[:space:]]*=/ { found = 1 }
                /^variable[[:space:]]+\"/ && current_var != var { if (current_var == var && !found) print current_var; found = 0 }
                END { if (current_var == var && !found) print current_var }
            ' "$variables_file" | grep -q "^$var_name$"; then
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

test_output_descriptions() {
    print_status "$BLUE" "  Testing output descriptions..."

    local outputs_file="$MODULE_DIR/terraform/outputs.tf"
    local outputs_without_description=()

    # Extract output names that don't have descriptions
    while read -r line; do
        if [[ $line =~ ^output[[:space:]]+\"([^\"]+)\" ]]; then
            local output_name="${BASH_REMATCH[1]}"
            # Check if description exists for this output
            if ! awk -v output="$output_name" '
                /^output[[:space:]]+\"/ { current_output = $0; gsub(/^output[[:space:]]+\"/, "", current_output); gsub(/\".*$/, "", current_output) }
                current_output == output && /description[[:space:]]*=/ { found = 1 }
                /^output[[:space:]]+\"/ && current_output != output { if (current_output == output && !found) print current_output; found = 0 }
                END { if (current_output == output && !found) print current_output }
            ' "$outputs_file" | grep -q "^$output_name$"; then
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

test_complex_configuration_documentation() {
    print_status "$BLUE" "  Testing complex configuration documentation..."

    local readme_file="$MODULE_DIR/README.md"
    local documentation_issues=()

    # Check for container definition examples
    if ! grep -q -i "container.*definition\|container.*configuration" "$readme_file"; then
        documentation_issues+=("Missing container definition documentation")
    fi

    # Check for load balancer integration examples
    if ! grep -q -i "load.*balancer\|alb\|nlb" "$readme_file"; then
        documentation_issues+=("Missing load balancer integration documentation")
    fi

    # Check for auto scaling documentation
    if ! grep -q -i "auto.*scaling\|scaling.*policy" "$readme_file"; then
        documentation_issues+=("Missing auto scaling documentation")
    fi

    # Check for service connect documentation
    if ! grep -q -i "service.*connect" "$readme_file"; then
        documentation_issues+=("Missing service connect documentation")
    fi

    if [ ${#documentation_issues[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ Complex configuration documentation is comprehensive"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Documentation could be improved:"
        for issue in "${documentation_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # This is a warning, not an error
    fi
}

test_security_documentation() {
    print_status "$BLUE" "  Testing security documentation..."

    local readme_file="$MODULE_DIR/README.md"
    local security_topics=()

    # Check for security-related documentation
    if grep -q -i "security.*group\|iam.*role\|permission" "$readme_file"; then
        security_topics+=("Security groups and IAM roles")
    fi

    if grep -q -i "secret\|environment.*variable" "$readme_file"; then
        security_topics+=("Secrets and environment variables")
    fi

    if grep -q -i "network\|vpc\|subnet" "$readme_file"; then
        security_topics+=("Network configuration")
    fi

    if [ ${#security_topics[@]} -gt 0 ]; then
        print_status "$GREEN" "  ✅ Security documentation covers: ${#security_topics[@]} topics"
        return 0
    else
        print_status "$YELLOW" "  ⚠️  Consider adding security documentation"
        return 0  # This is a warning, not an error
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running documentation tests for ECS Service Module..."

    local failed_tests=0

    # Run all tests
    test_readme_exists || ((failed_tests++))
    test_readme_content || ((failed_tests++))
    test_terraform_files_exist || ((failed_tests++))
    test_templates_directory || ((failed_tests++))
    test_terraform_syntax || ((failed_tests++))
    test_terraform_validation || ((failed_tests++))
    test_variable_descriptions || ((failed_tests++))
    test_output_descriptions || ((failed_tests++))
    test_complex_configuration_documentation || ((failed_tests++))
    test_security_documentation || ((failed_tests++))

    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All documentation tests passed!"
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
