#!/bin/bash

# Test Documentation Exists
# This script checks if required documentation files exist

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

test_documentation_exists() {
    print_status "$BLUE" "🔍 Testing documentation files..."

    local exit_code=0

    # List of required documentation files
    local required_docs=(
        "../README.md"
        "../athena/README.md"
        "../athena/terraform/README.md"
        "../athena/ENVIRONMENT-ISOLATION-GUIDE.md"
        "../athena/TEMPLATE-VARIABLES-GUIDE.md"
    )

    # List of optional documentation files
    local optional_docs=(
        "../athena/terraform/terraform.tfvars.example"
        "../index.html"
    )

    print_status "$BLUE" "  Checking required documentation files..."

    for doc_file in "${required_docs[@]}"; do
        if [ -f "$doc_file" ]; then
            print_status "$GREEN" "    ✅ Found: $doc_file"

            # Check if file is not empty
            if [ -s "$doc_file" ]; then
                print_status "$GREEN" "      📄 File has content"
            else
                print_status "$YELLOW" "      ⚠️  File is empty"
            fi
        else
            print_status "$RED" "    ❌ Missing: $doc_file"
            exit_code=1
        fi
    done

    print_status "$BLUE" "  Checking optional documentation files..."

    for doc_file in "${optional_docs[@]}"; do
        if [ -f "$doc_file" ]; then
            print_status "$GREEN" "    ✅ Found: $doc_file"
        else
            print_status "$YELLOW" "    ⚠️  Optional file missing: $doc_file"
        fi
    done

    # Check for common documentation patterns
    print_status "$BLUE" "  Checking documentation content patterns..."

    # Check if README files contain expected sections
    local readme_files=(
        "../README.md"
        "../athena/README.md"
        "../athena/terraform/README.md"
    )

    for readme in "${readme_files[@]}"; do
        if [ -f "$readme" ]; then
            local file_name
            file_name=$(basename "$readme")

            # Check for common sections
            if grep -qi "# " "$readme"; then
                print_status "$GREEN" "    ✅ $file_name contains headers"
            else
                print_status "$YELLOW" "    ⚠️  $file_name may not contain proper headers"
            fi

            # Check for prerequisites section
            if grep -qi "prerequisite\|requirement\|依存" "$readme"; then
                print_status "$GREEN" "    ✅ $file_name contains prerequisites/requirements"
            else
                print_status "$YELLOW" "    ⚠️  $file_name may not contain prerequisites"
            fi

            # Check for usage/installation section
            if grep -qi "usage\|installation\|使用方法\|インストール" "$readme"; then
                print_status "$GREEN" "    ✅ $file_name contains usage/installation info"
            else
                print_status "$YELLOW" "    ⚠️  $file_name may not contain usage info"
            fi
        fi
    done

    # Check for template files
    print_status "$BLUE" "  Checking template files..."

    local template_dirs=(
        "../athena/templates"
    )

    for template_dir in "${template_dirs[@]}"; do
        if [ -d "$template_dir" ]; then
            local template_count
            template_count=$(find "$template_dir" -name "*.sql" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" | wc -l)

            if [ "$template_count" -gt 0 ]; then
                print_status "$GREEN" "    ✅ Found $template_count template files in $template_dir"
            else
                print_status "$YELLOW" "    ⚠️  No template files found in $template_dir"
            fi
        else
            print_status "$YELLOW" "    ⚠️  Template directory not found: $template_dir"
        fi
    done

    # Check for configuration examples
    print_status "$BLUE" "  Checking configuration examples..."

    local config_examples=(
        "../athena/terraform/terraform.tfvars.example"
    )

    for config_file in "${config_examples[@]}"; do
        if [ -f "$config_file" ]; then
            print_status "$GREEN" "    ✅ Found configuration example: $config_file"

            # Check if it contains example values
            if grep -q "=" "$config_file" && grep -q "#" "$config_file"; then
                print_status "$GREEN" "      📋 Contains example values and comments"
            else
                print_status "$YELLOW" "      ⚠️  May not contain proper example values"
            fi
        else
            print_status "$YELLOW" "    ⚠️  Missing configuration example: $config_file"
        fi
    done

    # Count total documentation files
    local total_docs=0
    for doc_pattern in "../*.md" "../athena/*.md" "../athena/terraform/*.md"; do
        if ls $doc_pattern > /dev/null 2>&1; then
            total_docs=$((total_docs + $(ls $doc_pattern | wc -l)))
        fi
    done

    print_status "$BLUE" "  📊 Total documentation files: $total_docs"

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ Documentation structure is adequate"
    else
        print_status "$RED" "❌ Documentation structure has issues"
    fi

    return $exit_code
}

# Execute test
test_documentation_exists
