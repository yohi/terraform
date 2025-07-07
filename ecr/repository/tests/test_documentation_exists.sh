#!/bin/bash

# Test Documentation Existence for ECR Repository Module

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
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
    print_status "$BLUE" "  Testing README.md exists..."

    if [ -f "$MODULE_DIR/README.md" ]; then
        print_status "$GREEN" "  ✅ README.md exists"
        return 0
    else
        print_status "$RED" "  ❌ README.md not found"
        return 1
    fi
}

test_terraform_files_exist() {
    print_status "$BLUE" "  Testing Terraform files exist..."

    local required_files=(
        "terraform/main.tf"
        "terraform/variables.tf"
        "terraform/outputs.tf"
        "terraform/versions.tf"
        "terraform/terraform.tfvars.example"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [ ! -f "$MODULE_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required Terraform files exist"
        return 0
    else
        print_status "$RED" "  ❌ Missing Terraform files: ${missing_files[*]}"
        return 1
    fi
}

test_readme_content() {
    print_status "$BLUE" "  Testing README.md content..."

    local readme_file="$MODULE_DIR/README.md"

    if [ ! -f "$readme_file" ]; then
        print_status "$RED" "  ❌ README.md not found"
        return 1
    fi

    local required_sections=(
        "# ECR Repository"
        "## 概要"
        "## 使用方法"
        "## 変数"
        "## 出力"
        "## 例"
    )

    local missing_sections=()

    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$readme_file"; then
            missing_sections+=("$section")
        fi
    done

    if [ ${#missing_sections[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ README.md has all required sections"
        return 0
    else
        print_status "$RED" "  ❌ Missing README sections: ${missing_sections[*]}"
        return 1
    fi
}

test_terraform_example_syntax() {
    print_status "$BLUE" "  Testing Terraform examples in README..."

    local readme_file="$MODULE_DIR/README.md"

    if [ ! -f "$readme_file" ]; then
        print_status "$RED" "  ❌ README.md not found"
        return 1
    fi

    # Extract Terraform code blocks from README
    local temp_dir="${TEST_DIR}/temp"
    mkdir -p "$temp_dir"

    # Extract code blocks between ```hcl and ```
    awk '/```hcl/,/```/' "$readme_file" | grep -v '```' > "$temp_dir/extracted_examples.tf" || true

    if [ ! -s "$temp_dir/extracted_examples.tf" ]; then
        print_status "$GREEN" "  ✅ No Terraform examples found in README (skipping syntax check)"
        rm -rf "$temp_dir"
        return 0
    fi

    # Check syntax of extracted examples
    cd "$temp_dir"

    if terraform fmt -check=true extracted_examples.tf > /dev/null 2>&1; then
        print_status "$GREEN" "  ✅ Terraform examples in README have correct syntax"
        rm -rf "$temp_dir"
        return 0
    else
        print_status "$RED" "  ❌ Terraform examples in README have syntax issues"
        rm -rf "$temp_dir"
        return 1
    fi
}

test_tfvars_example_documented() {
    print_status "$BLUE" "  Testing terraform.tfvars.example is documented..."

    local tfvars_file="$MODULE_DIR/terraform/terraform.tfvars.example"

    if [ ! -f "$tfvars_file" ]; then
        print_status "$RED" "  ❌ terraform.tfvars.example not found"
        return 1
    fi

    # Check if variables in terraform.tfvars.example have comments
    local lines_without_comments=0
    local total_variable_lines=0

    while IFS= read -r line; do
        # Skip empty lines and pure comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Check if line contains a variable assignment
        if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*= ]]; then
            ((total_variable_lines++))

            # Check if there's a comment on the same line or the line before
            if [[ ! "$line" =~ # ]] && ! grep -B1 -n "^$line$" "$tfvars_file" | grep -q "#"; then
                ((lines_without_comments++))
            fi
        fi
    done < "$tfvars_file"

    if [ $lines_without_comments -eq 0 ]; then
        print_status "$GREEN" "  ✅ All variables in terraform.tfvars.example are documented"
        return 0
    else
        print_status "$RED" "  ❌ $lines_without_comments/$total_variable_lines variables lack documentation"
        return 1
    fi
}

test_versions_file_content() {
    print_status "$BLUE" "  Testing versions.tf content..."

    local versions_file="$MODULE_DIR/terraform/versions.tf"

    if [ ! -f "$versions_file" ]; then
        print_status "$RED" "  ❌ versions.tf not found"
        return 1
    fi

    local required_providers=(
        "aws"
    )

    local missing_providers=()

    for provider in "${required_providers[@]}"; do
        if ! grep -q "$provider" "$versions_file"; then
            missing_providers+=("$provider")
        fi
    done

    # Check for terraform version requirement
    if ! grep -q "required_version" "$versions_file"; then
        print_status "$RED" "  ❌ versions.tf missing required_version"
        return 1
    fi

    if [ ${#missing_providers[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ versions.tf has all required providers"
        return 0
    else
        print_status "$RED" "  ❌ versions.tf missing providers: ${missing_providers[*]}"
        return 1
    fi
}

test_changelog_or_history() {
    print_status "$BLUE" "  Testing change documentation..."

    local changelog_files=(
        "CHANGELOG.md"
        "HISTORY.md"
        "RELEASES.md"
    )

    local found_changelog=false

    for file in "${changelog_files[@]}"; do
        if [ -f "$MODULE_DIR/$file" ]; then
            found_changelog=true
            break
        fi
    done

    if [ "$found_changelog" = true ]; then
        print_status "$GREEN" "  ✅ Change documentation found"
        return 0
    else
        print_status "$GREEN" "  ✅ Change documentation not required (but recommended)"
        return 0
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running documentation existence tests..."

    local tests_passed=0
    local tests_failed=0

    # Test README exists
    if test_readme_exists; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test Terraform files exist
    if test_terraform_files_exist; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test README content
    if test_readme_content; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test Terraform examples in README
    if test_terraform_example_syntax; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test terraform.tfvars.example documentation
    if test_tfvars_example_documented; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test versions.tf content
    if test_versions_file_content; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test changelog or history
    if test_changelog_or_history; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All documentation existence tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some documentation existence tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
