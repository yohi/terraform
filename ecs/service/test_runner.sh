#!/bin/bash

# Test Runner for ECS Service Module

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
MODULE_NAME="ECS Service Module"

# Test configuration
PARALLEL_TESTS=true
VERBOSE=false
SPECIFIC_TEST=""
SKIP_SLOW_TESTS=false
FAST_ONLY=false

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
            --fast-only)
                FAST_ONLY=true
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

Test runner for ECS Service Module

OPTIONS:
    -v, --verbose       Enable verbose output
    -s, --sequential    Run tests sequentially instead of in parallel
    -t, --test NAME     Run specific test only
    --skip-slow         Skip slow tests (like terraform plan tests)
    --fast-only         Run only fast tests (documentation and syntax checks)
    -h, --help          Show this help message

EXAMPLES:
    $0                                    # Run all tests
    $0 -v                                # Run all tests with verbose output
    $0 -t test_documentation_exists      # Run specific test only
    $0 --skip-slow                       # Skip slow tests
    $0 --fast-only                       # Run only fast tests
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
        wait $pid
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

    printf '%s\n' "${tests[@]}"
}

# Categorize tests
categorize_tests() {
    local all_tests=()
    readarray -t all_tests < <(get_available_tests)

    local fast_tests=()
    local slow_tests=()

    for test in "${all_tests[@]}"; do
        case "$test" in
            test_terraform_plan|test_container_configuration|test_load_balancer_integration)
                slow_tests+=("$test")
                ;;
            test_documentation_exists|test_outputs_structure|test_variables_validation|test_tfvars_example)
                fast_tests+=("$test")
                ;;
            *)
                fast_tests+=("$test")
                ;;
        esac
    done

    if [ "$FAST_ONLY" = true ]; then
        printf '%s\n' "${fast_tests[@]}"
    elif [ "$SKIP_SLOW_TESTS" = true ]; then
        printf '%s\n' "${fast_tests[@]}"
    else
        printf '%s\n' "${fast_tests[@]}" "${slow_tests[@]}"
    fi
}

# Create default test if none exist
create_default_test() {
    if [ ! -d "$TESTS_DIR" ]; then
        mkdir -p "$TESTS_DIR"
    fi

    # If no tests exist, create a basic documentation test
    if [ ! -f "$TESTS_DIR/test_documentation_exists.sh" ]; then
        print_status "$YELLOW" "⚠️  No tests found. Creating basic documentation test..."

        cat > "$TESTS_DIR/test_documentation_exists.sh" << 'EOF'
#!/bin/bash
# Basic documentation test for ECS Service Module
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${TEST_DIR}/.."

# Test if README exists
if [ -f "$MODULE_DIR/README.md" ]; then
    echo "✅ README.md exists"
    exit 0
else
    echo "❌ README.md not found"
    exit 1
fi
EOF
        chmod +x "$TESTS_DIR/test_documentation_exists.sh"
    fi
}

# Print test summary
print_summary() {
    print_section "Test Summary"

    print_status "$BLUE" "Module: $MODULE_NAME"
    print_status "$BLUE" "Total tests: $total_tests"
    print_status "$GREEN" "Passed: $passed_tests"
    print_status "$RED" "Failed: $failed_tests"
    print_status "$YELLOW" "Skipped: $skipped_tests"

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "🎉 All tests passed!"
    else
        print_status "$RED" "💥 Some tests failed"
    fi

    # Print detailed results
    if [ ${#test_results[@]} -gt 0 ]; then
        print_status "$BLUE" ""
        print_status "$BLUE" "Detailed Results:"
        for test in "${!test_results[@]}"; do
            local result="${test_results[$test]}"
            local duration="${test_durations[$test]:-0}"

            case "$result" in
                "PASSED")
                    print_status "$GREEN" "  ✅ $test (${duration}s)"
                    ;;
                "FAILED")
                    print_status "$RED" "  ❌ $test (${duration}s)"
                    ;;
                "SKIPPED")
                    print_status "$YELLOW" "  ⏭️  $test"
                    ;;
            esac
        done
    fi

    # Print performance summary
    if [ ${#test_durations[@]} -gt 0 ]; then
        local total_duration=0
        for duration in "${test_durations[@]}"; do
            total_duration=$((total_duration + duration))
        done

        print_status "$BLUE" ""
        print_status "$BLUE" "Performance Summary:"
        print_status "$BLUE" "  Total execution time: ${total_duration}s"

        if [ $total_duration -gt 60 ]; then
            print_status "$YELLOW" "  ⚠️  Consider using --fast-only for quicker feedback"
        fi
    fi
}

# Main execution
main() {
    parse_args "$@"

    print_banner "Test Runner for $MODULE_NAME"

    # Check prerequisites
    check_prerequisites

    # Create default test if needed
    create_default_test

    # Get tests to run
    local tests_to_run=()

    if [ -n "$SPECIFIC_TEST" ]; then
        tests_to_run+=("$SPECIFIC_TEST")
    else
        readarray -t tests_to_run < <(categorize_tests)
    fi

    if [ ${#tests_to_run[@]} -eq 0 ]; then
        print_status "$YELLOW" "⚠️  No tests found to run"
        exit 0
    fi

    print_section "Running Tests"
    print_status "$BLUE" "Running ${#tests_to_run[@]} test(s)..."

    if [ "$SKIP_SLOW_TESTS" = true ]; then
        print_status "$YELLOW" "⚠️  Skipping slow tests"
    fi

    if [ "$FAST_ONLY" = true ]; then
        print_status "$YELLOW" "⚠️  Running only fast tests"
    fi

    # Run tests
    local start_time=$(date +%s)

    if [ "$PARALLEL_TESTS" = true ] && [ ${#tests_to_run[@]} -gt 1 ]; then
        print_status "$BLUE" "🔄 Running tests in parallel..."
        run_tests_parallel "${tests_to_run[@]}"
    else
        print_status "$BLUE" "🔄 Running tests sequentially..."
        run_tests_sequential "${tests_to_run[@]}"
    fi

    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    print_section "Results"
    print_status "$BLUE" "Total execution time: ${total_duration}s"

    print_summary

    # Exit with appropriate code
    if [ $failed_tests -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
