#!/bin/bash

# Test Runner for ALB Module

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_banner() {
    local message=$1
    print_status "$BLUE" "════════════════════════════════════════════════════════════════"
    print_status "$BOLD$BLUE" "$message"
    print_status "$BLUE" "════════════════════════════════════════════════════════════════"
}

print_section() {
    local message=$1
    print_status "$BLUE" "────────────────────────────────────────────────────────────────"
    print_status "$BOLD$BLUE" "$message"
    print_status "$BLUE" "────────────────────────────────────────────────────────────────"
}

# Get directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${SCRIPT_DIR}/tests"
MODULE_NAME="ALB Module"

# Test configuration
PARALLEL_TESTS=true
VERBOSE=false
SPECIFIC_TEST=""
SKIP_SLOW_TESTS=false

# Test results
declare -A test_results
declare -A test_durations
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--sequential)
                PARALLEL_TESTS=false
                shift
                ;;
            -t|--test)
                SPECIFIC_TEST="$2"
                shift 2
                ;;
            --skip-slow)
                SKIP_SLOW_TESTS=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Test runner for ALB Module

OPTIONS:
    -v, --verbose       Enable verbose output
    -s, --sequential    Run tests sequentially instead of in parallel
    -t, --test NAME     Run specific test only
    --skip-slow         Skip slow tests (like terraform plan tests)
    -h, --help          Show this help message

EXAMPLES:
    $0                                    # Run all tests
    $0 -v                                # Run all tests with verbose output
    $0 -t test_documentation_exists      # Run specific test only
    $0 --skip-slow                       # Skip slow tests
    $0 -s -v                            # Run sequentially with verbose output

EOF
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"

    local missing_tools=()

    # Check for required tools
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi

    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi

    if ! command -v bash &> /dev/null; then
        missing_tools+=("bash")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_status "$RED" "❌ Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            print_status "$RED" "  - $tool"
        done
        exit 1
    fi

    print_status "$GREEN" "✅ All prerequisites are met"
}

# Run individual test
run_test() {
    local test_name=$1
    local test_file="${TESTS_DIR}/${test_name}.sh"

    if [ ! -f "$test_file" ]; then
        print_status "$RED" "❌ Test file not found: $test_file"
        return 1
    fi

    print_status "$BLUE" "🧪 Running $test_name..."

    local start_time=$(date +%s)
    local output
    local exit_code

    if [ "$VERBOSE" = true ]; then
        if bash "$test_file"; then
            exit_code=0
        else
            exit_code=1
        fi
    else
        if output=$(bash "$test_file" 2>&1); then
            exit_code=0
        else
            exit_code=1
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    test_durations["$test_name"]=$duration

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ $test_name passed (${duration}s)"
        test_results["$test_name"]="PASSED"
        ((passed_tests++))
    else
        print_status "$RED" "❌ $test_name failed (${duration}s)"
        test_results["$test_name"]="FAILED"
        ((failed_tests++))

        if [ "$VERBOSE" = false ] && [ -n "$output" ]; then
            echo "$output"
        fi
    fi

    ((total_tests++))
}

# Run tests in parallel
run_tests_parallel() {
    local tests=("$@")
    local pids=()

    # Start all tests
    for test in "${tests[@]}"; do
        run_test "$test" &
        pids+=($!)
    done

    # Wait for all tests to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Run tests sequentially
run_tests_sequential() {
    local tests=("$@")

    for test in "${tests[@]}"; do
        run_test "$test"
    done
}

# Get list of available tests
get_available_tests() {
    local tests=()

    if [ -d "$TESTS_DIR" ]; then
        for test_file in "$TESTS_DIR"/test_*.sh; do
            if [ -f "$test_file" ]; then
                local test_name=$(basename "$test_file" .sh)
                tests+=("$test_name")
            fi
        done
    fi

    echo "${tests[@]}"
}

# Filter tests based on options
filter_tests() {
    local all_tests=("$@")
    local filtered_tests=()

    for test in "${all_tests[@]}"; do
        # Skip slow tests if requested
        if [ "$SKIP_SLOW_TESTS" = true ]; then
            case "$test" in
                test_terraform_plan|test_alb_configuration)
                    print_status "$YELLOW" "⏭️  Skipping slow test: $test"
                    ((skipped_tests++))
                    continue
                    ;;
            esac
        fi

        # Run specific test only if requested
        if [ -n "$SPECIFIC_TEST" ]; then
            if [ "$test" = "$SPECIFIC_TEST" ]; then
                filtered_tests+=("$test")
            fi
        else
            filtered_tests+=("$test")
        fi
    done

    echo "${filtered_tests[@]}"
}

# Print test summary
print_summary() {
    print_section "Test Summary"

    local total_duration=0
    for test in "${!test_durations[@]}"; do
        total_duration=$((total_duration + test_durations[$test]))
    done

    print_status "$BLUE" "📊 Results:"
    print_status "$GREEN" "  ✅ Passed: $passed_tests"
    print_status "$RED" "  ❌ Failed: $failed_tests"
    print_status "$YELLOW" "  ⏭️  Skipped: $skipped_tests"
    print_status "$BLUE" "  📈 Total: $total_tests"
    print_status "$BLUE" "  ⏱️  Duration: ${total_duration}s"

    if [ $failed_tests -gt 0 ]; then
        print_status "$RED" "💥 Failed tests:"
        for test in "${!test_results[@]}"; do
            if [ "${test_results[$test]}" = "FAILED" ]; then
                print_status "$RED" "  - $test"
            fi
        done
    fi

    print_status "$BLUE" "────────────────────────────────────────────────────────────────"

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "🎉 All tests passed!"
        return 0
    else
        print_status "$RED" "💔 Some tests failed"
        return 1
    fi
}

# Main execution
main() {
    parse_args "$@"

    print_banner "$MODULE_NAME Test Runner"

    check_prerequisites

    # Get available tests
    local available_tests
    read -ra available_tests <<< "$(get_available_tests)"

    if [ ${#available_tests[@]} -eq 0 ]; then
        print_status "$RED" "❌ No tests found in $TESTS_DIR"
        exit 1
    fi

    # Filter tests
    local tests_to_run
    read -ra tests_to_run <<< "$(filter_tests "${available_tests[@]}")"

    if [ ${#tests_to_run[@]} -eq 0 ]; then
        print_status "$YELLOW" "⚠️  No tests to run"
        exit 0
    fi

    print_section "Running Tests"
    print_status "$BLUE" "🔍 Found ${#tests_to_run[@]} tests to run"

    # Run tests
    if [ "$PARALLEL_TESTS" = true ]; then
        print_status "$BLUE" "🚀 Running tests in parallel..."
        run_tests_parallel "${tests_to_run[@]}"
    else
        print_status "$BLUE" "🐌 Running tests sequentially..."
        run_tests_sequential "${tests_to_run[@]}"
    fi

    # Print summary
    print_summary
}

# Run main function
main "$@"
