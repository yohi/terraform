#!/bin/bash

# Test Outputs Structure for ECR Repository Module

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
TERRAFORM_DIR="${TEST_DIR}/../terraform"
OUTPUTS_FILE="${TERRAFORM_DIR}/outputs.tf"

test_outputs_file_exists() {
    print_status "$BLUE" "  Testing outputs.tf file exists..."

    if [ -f "$OUTPUTS_FILE" ]; then
        print_status "$GREEN" "  ✅ outputs.tf file exists"
        return 0
    else
        print_status "$RED" "  ❌ outputs.tf file not found"
        return 1
    fi
}

test_required_outputs() {
    print_status "$BLUE" "  Testing required outputs are defined..."

    local required_outputs=(
        "repository_urls"
        "repository_arns"
        "repository_names"
        "registry_ids"
        "repository_url"
        "repository_arn"
        "repository_name"
        "registry_id"
        "aws_account_id"
        "aws_region"
    )

    local missing_outputs=()

    for output in "${required_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$OUTPUTS_FILE"; then
            missing_outputs+=("$output")
        fi
    done

    if [ ${#missing_outputs[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All required outputs are defined"
        return 0
    else
        print_status "$RED" "  ❌ Missing required outputs: ${missing_outputs[*]}"
        return 1
    fi
}

test_output_descriptions() {
    print_status "$BLUE" "  Testing output descriptions..."

    local outputs_without_description=()

    # Extract all output blocks and check for descriptions
    while IFS= read -r line; do
        if [[ $line =~ ^output\ \"([^\"]+)\" ]]; then
            local output_name="${BASH_REMATCH[1]}"
            local has_description=false

            # Read the next few lines to check for description
            local context_lines=5
            local current_line_num=$(grep -n "^output \"$output_name\"" "$OUTPUTS_FILE" | cut -d: -f1)

            for ((i=1; i<=context_lines; i++)); do
                local check_line=$(sed -n "$((current_line_num + i))p" "$OUTPUTS_FILE")
                if [[ $check_line =~ description ]]; then
                    has_description=true
                    break
                fi
            done

            if [ "$has_description" = false ]; then
                outputs_without_description+=("$output_name")
            fi
        fi
    done < "$OUTPUTS_FILE"

    if [ ${#outputs_without_description[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All outputs have descriptions"
        return 0
    else
        print_status "$RED" "  ❌ Outputs without descriptions: ${outputs_without_description[*]}"
        return 1
    fi
}

test_output_values() {
    print_status "$BLUE" "  Testing output values are reasonable..."

    local temp_dir="${TEST_DIR}/temp"
    mkdir -p "$temp_dir"

    # Create test configuration
    cat > "$temp_dir/test-outputs.tfvars" << EOF
project_name = "test-outputs"
environment  = "dev"
app         = "sample"

common_tags = {
  Project     = "test-outputs"
  Environment = "dev"
  Purpose     = "testing"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Initialize and plan
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! terraform plan -var-file="$temp_dir/test-outputs.tfvars" -out="$temp_dir/test-outputs.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate plan"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract planned output values
    local plan_json
    plan_json=$(terraform show -json "$temp_dir/test-outputs.tfplan")

    # Check if output values are structured correctly
    local outputs_valid=true

    # Check repository_urls output
    if ! echo "$plan_json" | jq -e '.planned_values.outputs.repository_urls' > /dev/null 2>&1; then
        print_status "$RED" "    ❌ repository_urls output not found or invalid"
        outputs_valid=false
    fi

    # Check repository_arns output
    if ! echo "$plan_json" | jq -e '.planned_values.outputs.repository_arns' > /dev/null 2>&1; then
        print_status "$RED" "    ❌ repository_arns output not found or invalid"
        outputs_valid=false
    fi

    # Check aws_account_id output
    if ! echo "$plan_json" | jq -e '.planned_values.outputs.aws_account_id' > /dev/null 2>&1; then
        print_status "$RED" "    ❌ aws_account_id output not found or invalid"
        outputs_valid=false
    fi

    # Check aws_region output
    if ! echo "$plan_json" | jq -e '.planned_values.outputs.aws_region' > /dev/null 2>&1; then
        print_status "$RED" "    ❌ aws_region output not found or invalid"
        outputs_valid=false
    fi

    # Cleanup
    rm -rf "$temp_dir"

    if [ "$outputs_valid" = true ]; then
        print_status "$GREEN" "  ✅ Output values are structured correctly"
        return 0
    else
        print_status "$RED" "  ❌ Some output values are invalid"
        return 1
    fi
}

test_helper_outputs() {
    print_status "$BLUE" "  Testing helper outputs..."

    local helper_outputs=(
        "repository_image_uris"
        "repository_push_commands"
        "lifecycle_policy_enabled"
        "repository_policy_enabled"
        "replication_enabled"
        "scan_on_push_enabled"
    )

    local missing_helpers=()

    for helper in "${helper_outputs[@]}"; do
        if ! grep -q "^output \"$helper\"" "$OUTPUTS_FILE"; then
            missing_helpers+=("$helper")
        fi
    done

    if [ ${#missing_helpers[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All helper outputs are defined"
        return 0
    else
        print_status "$RED" "  ❌ Missing helper outputs: ${missing_helpers[*]}"
        return 1
    fi
}

test_backward_compatibility() {
    print_status "$BLUE" "  Testing backward compatibility outputs..."

    local backward_compat_outputs=(
        "repository_url"
        "repository_arn"
        "repository_name"
        "registry_id"
    )

    local missing_compat=()

    for output in "${backward_compat_outputs[@]}"; do
        if ! grep -q "^output \"$output\"" "$OUTPUTS_FILE"; then
            missing_compat+=("$output")
        fi
    done

    if [ ${#missing_compat[@]} -eq 0 ]; then
        print_status "$GREEN" "  ✅ All backward compatibility outputs are defined"
        return 0
    else
        print_status "$RED" "  ❌ Missing backward compatibility outputs: ${missing_compat[*]}"
        return 1
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running outputs structure tests..."

    local tests_passed=0
    local tests_failed=0

    # Test outputs file exists
    if test_outputs_file_exists; then
        ((tests_passed++))
    else
        ((tests_failed++))
        return 1  # Can't continue without the file
    fi

    # Test required outputs
    if test_required_outputs; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test output descriptions
    if test_output_descriptions; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test output values
    if test_output_values; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test helper outputs
    if test_helper_outputs; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Test backward compatibility
    if test_backward_compatibility; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    # Summary
    if [ $tests_failed -eq 0 ]; then
        print_status "$GREEN" "✅ All outputs structure tests passed ($tests_passed/$((tests_passed + tests_failed)))"
        return 0
    else
        print_status "$RED" "❌ Some outputs structure tests failed ($tests_passed/$((tests_passed + tests_failed)))"
        return 1
    fi
}

main "$@"
