#!/bin/bash

# Test Markdown Syntax
# This script checks markdown files for syntax issues

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

test_markdown_syntax() {
    print_status "$BLUE" "🔍 Testing markdown syntax..."

    local exit_code=0

    # Find all markdown files
    local markdown_files=()
    while IFS= read -r -d '' file; do
        markdown_files+=("$file")
    done < <(find .. -name "*.md" -print0)

    if [ ${#markdown_files[@]} -eq 0 ]; then
        print_status "$YELLOW" "⚠️  No markdown files found"
        return 0
    fi

    print_status "$BLUE" "  Found ${#markdown_files[@]} markdown files"

    # Basic syntax checks
    for md_file in "${markdown_files[@]}"; do
        local file_name
        file_name=$(basename "$md_file")

        print_status "$BLUE" "  Checking $file_name..."

        # Check for valid UTF-8 encoding
        if ! iconv -f UTF-8 -t UTF-8 "$md_file" > /dev/null 2>&1; then
            print_status "$RED" "    ❌ Invalid UTF-8 encoding"
            exit_code=1
        else
            print_status "$GREEN" "    ✅ Valid UTF-8 encoding"
        fi

        # Check for basic markdown structure
        if grep -q "^#" "$md_file"; then
            print_status "$GREEN" "    ✅ Contains headers"
        else
            print_status "$YELLOW" "    ⚠️  No headers found"
        fi

        # Check for unmatched brackets
        local open_brackets closed_brackets
        open_brackets=$(grep -o '\[' "$md_file" | wc -l)
        closed_brackets=$(grep -o '\]' "$md_file" | wc -l)

        if [ "$open_brackets" -eq "$closed_brackets" ]; then
            print_status "$GREEN" "    ✅ Balanced brackets"
        else
            print_status "$YELLOW" "    ⚠️  Unbalanced brackets ($open_brackets open, $closed_brackets closed)"
        fi

        # Check for broken links (simple check)
        if grep -q '\[.*\]()' "$md_file"; then
            print_status "$YELLOW" "    ⚠️  Found empty links"
        else
            print_status "$GREEN" "    ✅ No empty links found"
        fi

        # Check file size
        local file_size
        file_size=$(stat -c%s "$md_file" 2>/dev/null || stat -f%z "$md_file" 2>/dev/null || echo "0")

        if [ "$file_size" -gt 0 ]; then
            print_status "$GREEN" "    ✅ File has content ($file_size bytes)"
        else
            print_status "$YELLOW" "    ⚠️  File is empty"
        fi
    done

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ Markdown syntax checks passed"
    else
        print_status "$RED" "❌ Markdown syntax has issues"
    fi

    return $exit_code
}

# Execute test
test_markdown_syntax
