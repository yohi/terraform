#!/bin/bash

# Test Security Group Rules for ALB Module

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

test_security_group_resource_exists() {
    print_status "$BLUE" "  Testing security group resource existence..."

    local main_tf="$TERRAFORM_DIR/main.tf"

    if grep -q "resource \"aws_security_group\" \"alb\"" "$main_tf"; then
        print_status "$GREEN" "  ✅ Security group resource exists"
        return 0
    else
        print_status "$RED" "  ❌ Security group resource 'aws_security_group.alb' not found"
        return 1
    fi
}

test_http_ingress_rules() {
    print_status "$BLUE" "  Testing HTTP ingress rules..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local http_issues=()

    # Check IPv4 HTTP rule
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -q "from_port.*=.*80"; then
        if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*80" | grep -q "cidr_blocks.*=.*0.0.0.0/0"; then
            print_status "$GREEN" "    ✅ HTTP IPv4 ingress rule is configured"
        else
            http_issues+=("HTTP IPv4 ingress rule should allow access from 0.0.0.0/0")
        fi
    else
        http_issues+=("HTTP ingress rule (port 80) not found")
    fi

    # Check IPv6 HTTP rule
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*80" | grep -q "ipv6_cidr_blocks.*=.*::/0"; then
        print_status "$GREEN" "    ✅ HTTP IPv6 ingress rule is configured"
    else
        http_issues+=("HTTP IPv6 ingress rule should allow access from ::/0")
    fi

    # Check protocol
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*80" | grep -q "protocol.*=.*tcp"; then
        print_status "$GREEN" "    ✅ HTTP protocol is correctly set to tcp"
    else
        http_issues+=("HTTP protocol should be tcp")
    fi

    if [ ${#http_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ HTTP ingress rule issues:"
        for issue in "${http_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ HTTP ingress rules are correctly configured"
        return 0
    fi
}

test_https_ingress_rules() {
    print_status "$BLUE" "  Testing HTTPS ingress rules..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local https_issues=()

    # Check IPv4 HTTPS rule
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -q "from_port.*=.*443"; then
        if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*443" | grep -q "cidr_blocks.*=.*0.0.0.0/0"; then
            print_status "$GREEN" "    ✅ HTTPS IPv4 ingress rule is configured"
        else
            https_issues+=("HTTPS IPv4 ingress rule should allow access from 0.0.0.0/0")
        fi
    else
        https_issues+=("HTTPS ingress rule (port 443) not found")
    fi

    # Check IPv6 HTTPS rule
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*443" | grep -q "ipv6_cidr_blocks.*=.*::/0"; then
        print_status "$GREEN" "    ✅ HTTPS IPv6 ingress rule is configured"
    else
        https_issues+=("HTTPS IPv6 ingress rule should allow access from ::/0")
    fi

    # Check protocol
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*443" | grep -q "protocol.*=.*tcp"; then
        print_status "$GREEN" "    ✅ HTTPS protocol is correctly set to tcp"
    else
        https_issues+=("HTTPS protocol should be tcp")
    fi

    if [ ${#https_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ HTTPS ingress rule issues:"
        for issue in "${https_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ HTTPS ingress rules are correctly configured"
        return 0
    fi
}

test_egress_rules() {
    print_status "$BLUE" "  Testing egress rules..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local egress_issues=()

    # Check if egress block exists
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -q "egress"; then
        print_status "$GREEN" "    ✅ Egress block exists"
    else
        egress_issues+=("Egress block not found")
        return 1
    fi

    # Check egress rule configuration
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "egress" | grep -q "from_port.*=.*0"; then
        print_status "$GREEN" "    ✅ Egress allows all ports"
    else
        egress_issues+=("Egress should allow all ports (from_port = 0)")
    fi

    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "egress" | grep -q "to_port.*=.*0"; then
        print_status "$GREEN" "    ✅ Egress allows all ports"
    else
        egress_issues+=("Egress should allow all ports (to_port = 0)")
    fi

    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "egress" | grep -q "protocol.*=.*-1"; then
        print_status "$GREEN" "    ✅ Egress allows all protocols"
    else
        egress_issues+=("Egress should allow all protocols (protocol = -1)")
    fi

    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "egress" | grep -q "cidr_blocks.*=.*0.0.0.0/0"; then
        print_status "$GREEN" "    ✅ Egress allows all IPv4 destinations"
    else
        egress_issues+=("Egress should allow all IPv4 destinations (0.0.0.0/0)")
    fi

    if [ ${#egress_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Egress rule issues:"
        for issue in "${egress_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ Egress rules are correctly configured"
        return 0
    fi
}

test_security_group_naming() {
    print_status "$BLUE" "  Testing security group naming..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local naming_issues=()

    # Check if security group name is configurable
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -q "name.*=.*local.security_group_name"; then
        print_status "$GREEN" "    ✅ Security group name uses local variable"
    else
        naming_issues+=("Security group name should use local variable for consistency")
    fi

    # Check if locals defines security group name
    if grep -A 10 "locals" "$main_tf" | grep -q "security_group_name"; then
        print_status "$GREEN" "    ✅ Security group name is defined in locals"
    else
        naming_issues+=("Security group name should be defined in locals block")
    fi

    if [ ${#naming_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Security group naming issues:"
        for issue in "${naming_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Security group naming is correctly configured"
        return 0
    fi
}

test_security_group_tags() {
    print_status "$BLUE" "  Testing security group tags..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local tagging_issues=()

    # Check if security group has tags
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -q "tags"; then
        print_status "$GREEN" "    ✅ Security group has tags configured"
    else
        tagging_issues+=("Security group should have tags configured")
    fi

    # Check if common_tags is merged
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "tags" | grep -q "merge.*common_tags"; then
        print_status "$GREEN" "    ✅ Security group uses common_tags"
    else
        tagging_issues+=("Security group should merge common_tags")
    fi

    # Check if Name tag is set
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "tags" | grep -q "Name"; then
        print_status "$GREEN" "    ✅ Security group has Name tag"
    else
        tagging_issues+=("Security group should have Name tag")
    fi

    if [ ${#tagging_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Security group tagging issues:"
        for issue in "${tagging_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Security group tagging is correctly configured"
        return 0
    fi
}

test_lifecycle_configuration() {
    print_status "$BLUE" "  Testing security group lifecycle configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local lifecycle_issues=()

    # Check if create_before_destroy is set
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -q "lifecycle"; then
        if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "lifecycle" | grep -q "create_before_destroy.*=.*true"; then
            print_status "$GREEN" "    ✅ Security group has create_before_destroy enabled"
        else
            lifecycle_issues+=("Security group should have create_before_destroy = true")
        fi
    else
        lifecycle_issues+=("Security group should have lifecycle configuration")
    fi

    if [ ${#lifecycle_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Security group lifecycle issues:"
        for issue in "${lifecycle_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Security group lifecycle is correctly configured"
        return 0
    fi
}

test_port_range_configuration() {
    print_status "$BLUE" "  Testing port range configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local port_issues=()

    # Check HTTP port range
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*80" | grep -q "to_port.*=.*80"; then
        print_status "$GREEN" "    ✅ HTTP port range is correctly configured"
    else
        port_issues+=("HTTP port range should be 80-80")
    fi

    # Check HTTPS port range
    if grep -A 100 "resource \"aws_security_group\" \"alb\"" "$main_tf" | grep -A 10 "ingress" | grep -B 5 -A 5 "from_port.*=.*443" | grep -q "to_port.*=.*443"; then
        print_status "$GREEN" "    ✅ HTTPS port range is correctly configured"
    else
        port_issues+=("HTTPS port range should be 443-443")
    fi

    if [ ${#port_issues[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Port range configuration issues:"
        for issue in "${port_issues[@]}"; do
            print_status "$RED" "    - $issue"
        done
        return 1
    else
        print_status "$GREEN" "  ✅ Port range configuration is correct"
        return 0
    fi
}

test_additional_security_groups() {
    print_status "$BLUE" "  Testing additional security groups configuration..."

    local main_tf="$TERRAFORM_DIR/main.tf"
    local additional_sg_issues=()

    # Check if ALB uses additional security groups
    if grep -A 100 "resource \"aws_lb\" \"main\"" "$main_tf" | grep -q "additional_security_group_ids"; then
        print_status "$GREEN" "    ✅ ALB supports additional security groups"
    else
        additional_sg_issues+=("ALB should support additional security groups")
    fi

    # Check if concat is used to merge security groups
    if grep -A 100 "resource \"aws_lb\" \"main\"" "$main_tf" | grep -q "concat.*security_groups"; then
        print_status "$GREEN" "    ✅ ALB security groups are properly concatenated"
    else
        additional_sg_issues+=("ALB should concatenate default and additional security groups")
    fi

    if [ ${#additional_sg_issues[@]} -gt 0 ]; then
        print_status "$YELLOW" "  ⚠️  Additional security groups issues:"
        for issue in "${additional_sg_issues[@]}"; do
            print_status "$YELLOW" "    - $issue"
        done
        return 0  # Warning, not failure
    else
        print_status "$GREEN" "  ✅ Additional security groups configuration is correct"
        return 0
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running security group rules tests..."

    local tests=(
        "test_security_group_resource_exists"
        "test_http_ingress_rules"
        "test_https_ingress_rules"
        "test_egress_rules"
        "test_security_group_naming"
        "test_security_group_tags"
        "test_lifecycle_configuration"
        "test_port_range_configuration"
        "test_additional_security_groups"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All security group rules tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests security group rules tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
