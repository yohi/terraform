#!/bin/bash

# Test ALB Configuration for ALB Module

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

test_alb_resource_definition() {
    print_status "$BLUE" "  Testing ALB resource definition..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local alb_issues=()

    # Check if ALB resource exists
    if ! grep -q "resource \"aws_lb\" \"main\"" "$main_tf"; then
        alb_issues+=("ALB resource 'aws_lb.main' not found")
    fi

    # Check essential ALB attributes
    if ! grep -A 20 "resource \"aws_lb\" \"main\"" "$main_tf" | grep -q "load_balancer_type.*=.*application"; then
        alb_issues+=("ALB should be of type 'application'")
    fi

    if ! grep -A 20 "resource \"aws_lb\" \"main\"" "$main_tf" | grep -q "security_groups"; then
        alb_issues+=("ALB should have security_groups configured")
    fi

    if ! grep -A 20 "resource \"aws_lb\" \"main\"" "$main_tf" | grep -q "subnets"; then
        alb_issues+=("ALB should have subnets configured")
    fi

    if [ ${#alb_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ ALB resource definition issues:"
        for issue in "${alb_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ ALB resource definition is correct"
        return 0
    fi
}

test_target_group_configuration() {
    print_status "$BLUE" "  Testing target group configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local tg_issues=()

    # Check if target group resource exists
    if ! grep -q "resource \"aws_lb_target_group\" \"main\"" "$main_tf"; then
        tg_issues+=("Target group resource 'aws_lb_target_group.main' not found")
    fi

    # Check essential target group attributes
    if ! grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "port"; then
        tg_issues+=("Target group should have port configured")
    fi

    if ! grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "protocol"; then
        tg_issues+=("Target group should have protocol configured")
    fi

    if ! grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "vpc_id"; then
        tg_issues+=("Target group should have vpc_id configured")
    fi

    if ! grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "target_type"; then
        tg_issues+=("Target group should have target_type configured")
    fi

    # Check health check configuration
    if ! grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "health_check"; then
        tg_issues+=("Target group should have health_check configured")
    fi

    if [ ${#tg_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Target group configuration issues:"
        for issue in "${tg_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ Target group configuration is correct"
        return 0
    fi
}

test_listener_configuration() {
    print_status "$BLUE" "  Testing listener configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local listener_issues=()

    # Check if HTTP listener exists
    if ! grep -q "resource \"aws_lb_listener\" \"http\"" "$main_tf"; then
        listener_issues+=("HTTP listener resource 'aws_lb_listener.http' not found")
    fi

    # Check if HTTPS listener exists
    if ! grep -q "resource \"aws_lb_listener\" \"https\"" "$main_tf"; then
        listener_issues+=("HTTPS listener resource 'aws_lb_listener.https' not found")
    fi

    # Check HTTP listener configuration
    if grep -A 20 "resource \"aws_lb_listener\" \"http\"" "$main_tf" | grep -q "port.*=.*80"; then
        print_status "$GREEN" "    ✅ HTTP listener port is correctly set to 80"
    else
        listener_issues+=("HTTP listener should be on port 80")
    fi

    # Check HTTPS listener configuration
    if grep -A 20 "resource \"aws_lb_listener\" \"https\"" "$main_tf" | grep -q "port.*=.*443"; then
        print_status "$GREEN" "    ✅ HTTPS listener port is correctly set to 443"
    else
        listener_issues+=("HTTPS listener should be on port 443")
    fi

    # Check if HTTPS listener has SSL certificate
    if grep -A 20 "resource \"aws_lb_listener\" \"https\"" "$main_tf" | grep -q "certificate_arn"; then
        print_status "$GREEN" "    ✅ HTTPS listener has SSL certificate configured"
    else
        listener_issues+=("HTTPS listener should have certificate_arn configured")
    fi

    if [ ${#listener_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Listener configuration issues:"
        for issue in "${listener_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ Listener configuration is correct"
        return 0
    fi
}

test_security_group_configuration() {
    print_status "$BLUE" "  Testing security group configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local sg_issues=()

    # Check if security group resource exists
    if ! grep -q "resource \"aws_security_group\" \"alb\"" "$main_tf"; then
        sg_issues+=("Security group resource 'aws_security_group.alb' not found")
    fi

    # Check ingress rules for HTTP
    if grep -A 50 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -q "from_port.*=.*80"; then
        print_status "$GREEN" "    ✅ HTTP ingress rule exists"
    else
        sg_issues+=("HTTP ingress rule (port 80) should be configured")
    fi

    # Check ingress rules for HTTPS
    if grep -A 50 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -q "from_port.*=.*443"; then
        print_status "$GREEN" "    ✅ HTTPS ingress rule exists"
    else
        sg_issues+=("HTTPS ingress rule (port 443) should be configured")
    fi

    # Check egress rules
    if grep -A 50 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -q "egress"; then
        print_status "$GREEN" "    ✅ Egress rules are configured"
    else
        sg_issues+=("Egress rules should be configured")
    fi

    if [ ${#sg_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Security group configuration issues:"
        for issue in "${sg_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ Security group configuration is correct"
        return 0
    fi
}

test_naming_conventions() {
    print_status "$BLUE" "  Testing naming conventions..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local naming_issues=()

    # Check if locals block exists for naming
    if ! grep -q "locals" "$main_tf"; then
        naming_issues+=("locals block for naming conventions not found")
    fi

    # Check if naming pattern is used
    if grep -A 10 "locals" "$main_tf" | grep -q "alb_name"; then
        print_status "$GREEN" "    ✅ ALB naming convention is implemented"
    else
        naming_issues+=("ALB naming convention should be implemented in locals")
    fi

    if grep -A 10 "locals" "$main_tf" | grep -q "target_group_name"; then
        print_status "$GREEN" "    ✅ Target group naming convention is implemented"
    else
        naming_issues+=("Target group naming convention should be implemented in locals")
    fi

    if [ ${#naming_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Naming convention issues:"
        for issue in "${naming_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Naming conventions are implemented"
        return 0
    fi
}

test_tagging_strategy() {
    print_status "$BLUE" "  Testing tagging strategy..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local tagging_issues=()

    # Check if resources have tags
    local resources=("aws_lb" "aws_lb_target_group" "aws_lb_listener" "aws_security_group")
    for resource in "${resources[@]}"; do
        if grep -A 20 "resource \"$resource\"" "$main_tf" | grep -q "tags"; then
            print_status "$GREEN" "    ✅ $resource has tags configured"
        else
            tagging_issues+=("$resource should have tags configured")
        fi
    done

    # Check if common_tags is used
    if grep -q "common_tags" "$main_tf"; then
        print_status "$GREEN" "    ✅ common_tags variable is used"
    else
        tagging_issues+=("common_tags variable should be used for consistent tagging")
    fi

    if [ ${#tagging_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Tagging strategy issues:"
        for issue in "${tagging_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Tagging strategy is implemented"
        return 0
    fi
}

test_ecs_optimization() {
    print_status "$BLUE" "  Testing ECS optimization..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local ecs_issues=()

    # Check if target type is set to 'ip' for ECS
    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "target_type.*=.*ip"; then
        print_status "$GREEN" "    ✅ Target type is set to 'ip' for ECS"
    else
        ecs_issues+=("Target type should be set to 'ip' for ECS compatibility")
    fi

    # Check if deregistration_delay is optimized for ECS
    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -q "deregistration_delay.*=.*30"; then
        print_status "$GREEN" "    ✅ Deregistration delay is optimized for ECS"
    else
        ecs_issues+=("Deregistration delay should be set to 30 seconds for ECS")
    fi

    if [ ${#ecs_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  ECS optimization issues:"
        for issue in "${ecs_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ ECS optimization is implemented"
        return 0
    fi
}

test_https_redirect() {
    print_status "$BLUE" "  Testing HTTPS redirect..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local redirect_issues=()

    # Check if HTTP listener redirects to HTTPS
    if grep -A 20 "resource \"aws_lb_listener\" \"http\"" "$main_tf" | grep -q "type.*=.*redirect"; then
        print_status "$GREEN" "    ✅ HTTP listener redirects to HTTPS"
    else
        redirect_issues+=("HTTP listener should redirect to HTTPS")
    fi

    # Check redirect configuration
    if grep -A 20 "resource \"aws_lb_listener\" \"http\"" "$main_tf" | grep -A 10 "redirect" | grep -q "port.*=.*443"; then
        print_status "$GREEN" "    ✅ HTTP redirect to port 443 is configured"
    else
        redirect_issues+=("HTTP redirect should redirect to port 443")
    fi

    if grep -A 20 "resource \"aws_lb_listener\" \"http\"" "$main_tf" | grep -A 10 "redirect" | grep -q "protocol.*=.*HTTPS"; then
        print_status "$GREEN" "    ✅ HTTP redirect to HTTPS protocol is configured"
    else
        redirect_issues+=("HTTP redirect should redirect to HTTPS protocol")
    fi

    if [ ${#redirect_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ HTTPS redirect issues:"
        for issue in "${redirect_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ HTTPS redirect is properly configured"
        return 0
    fi
}

test_health_check_configuration() {
    print_status "$BLUE" "  Testing health check configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local hc_issues=()

    # Check if health check is configurable
    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -A 15 "health_check" | grep -q "enabled"; then
        print_status "$GREEN" "    ✅ Health check enabled is configurable"
    else
        hc_issues+=("Health check enabled should be configurable")
    fi

    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -A 15 "health_check" | grep -q "path"; then
        print_status "$GREEN" "    ✅ Health check path is configurable"
    else
        hc_issues+=("Health check path should be configurable")
    fi

    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -A 15 "health_check" | grep -q "timeout"; then
        print_status "$GREEN" "    ✅ Health check timeout is configurable"
    else
        hc_issues+=("Health check timeout should be configurable")
    fi

    if grep -A 30 "resource \"aws_lb_target_group\" \"main\"" "$main_tf" | grep -A 15 "health_check" | grep -q "interval"; then
        print_status "$GREEN" "    ✅ Health check interval is configurable"
    else
        hc_issues+=("Health check interval should be configurable")
    fi

    if [ ${#hc_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Health check configuration issues:"
        for issue in "${hc_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Health check configuration is comprehensive"
        return 0
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running ALB configuration tests..."

    local tests=(
        "test_alb_resource_definition"
        "test_target_group_configuration"
        "test_listener_configuration"
        "test_security_group_configuration"
        "test_naming_conventions"
        "test_tagging_strategy"
        "test_ecs_optimization"
        "test_https_redirect"
        "test_health_check_configuration"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All ALB configuration tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests ALB configuration tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
