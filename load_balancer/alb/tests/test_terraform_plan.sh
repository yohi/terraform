#!/bin/bash

# Test Terraform Plan for ALB Module

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

test_basic_alb_plan() {
    print_status "$BLUE" "  Testing basic ALB plan generation..."

    # Create test configuration
    cat > "$TEMP_DIR/basic.tfvars" << EOF
# Basic ALB configuration
project_name = "test-alb"
environment  = "dev"
app         = "sample"

# Network configuration
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]

# ALB configuration
internal = false
enable_deletion_protection = false
enable_cross_zone_load_balancing = true

# Target Group configuration
target_group_port = 80
target_group_protocol = "HTTP"
target_type = "ip"

# Health Check configuration
health_check_path = "/"
health_check_healthy_threshold = 2
health_check_unhealthy_threshold = 2

# SSL certificate (required for HTTPS listener)
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Common tags
common_tags = {
  Project     = "test-alb"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to initialize Terraform"
        return 1
    fi

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/basic.tfvars" -out="$TEMP_DIR/basic.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate basic ALB plan"
        return 1
    fi

    # Verify expected resources
    local plan_json
    plan_json=$(terraform show -json "$TEMP_DIR/basic.tfplan")

    # Check if expected resources are being created
    local expected_resources=("aws_lb.main" "aws_lb_target_group.main" "aws_lb_listener.http" "aws_lb_listener.https" "aws_security_group.alb")
    local missing_resources=()

    for resource in "${expected_resources[@]}"; do
        if ! echo "$plan_json" | jq -r '.resource_changes[] | select(.change.actions[] | contains("create")) | .address' | grep -q "$resource"; then
            missing_resources+=("$resource")
        fi
    done

    if [ ${#missing_resources[@]} -gt 0 ]; then
        print_status "$RED" "  ❌ Missing expected resources:"
        for resource in "${missing_resources[@]}"; do
            print_status "$RED" "    - $resource"
        done
        return 1
    fi

    print_status "$GREEN" "  ✅ Basic ALB plan generated successfully"
    return 0
}

test_internal_alb_plan() {
    print_status "$BLUE" "  Testing internal ALB plan generation..."

    # Create test configuration for internal ALB
    cat > "$TEMP_DIR/internal.tfvars" << EOF
# Internal ALB configuration
project_name = "test-internal-alb"
environment  = "dev"

# Network configuration
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]

# ALB configuration
internal = true
enable_deletion_protection = false

# Target Group configuration
target_group_port = 8080
target_group_protocol = "HTTP"
target_type = "ip"

# Health Check configuration
health_check_path = "/health"
health_check_port = "8080"

# SSL certificate
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Common tags
common_tags = {
  Project     = "test-internal-alb"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/internal.tfvars" -out="$TEMP_DIR/internal.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate internal ALB plan"
        return 1
    fi

    # Verify ALB is configured as internal
    local plan_json
    plan_json=$(terraform show -json "$TEMP_DIR/internal.tfplan")

    local is_internal
    is_internal=$(echo "$plan_json" | jq -r '.resource_changes[] | select(.address == "aws_lb.main") | .change.after.internal')

    if [ "$is_internal" != "true" ]; then
        print_status "$RED" "  ❌ ALB is not configured as internal"
        return 1
    fi

    print_status "$GREEN" "  ✅ Internal ALB plan generated successfully"
    return 0
}

test_with_access_logs_plan() {
    print_status "$BLUE" "  Testing ALB with access logs plan generation..."

    # Create test configuration with access logs
    cat > "$TEMP_DIR/access-logs.tfvars" << EOF
# ALB with access logs configuration
project_name = "test-alb-logs"
environment  = "dev"

# Network configuration
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]

# ALB configuration
internal = false
enable_deletion_protection = false

# Access logs configuration
enable_access_logs = true
access_logs_bucket = "my-alb-access-logs-bucket"
access_logs_prefix = "alb-logs"

# Target Group configuration
target_group_port = 80
target_group_protocol = "HTTP"
target_type = "ip"

# SSL certificate
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Common tags
common_tags = {
  Project     = "test-alb-logs"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/access-logs.tfvars" -out="$TEMP_DIR/access-logs.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate ALB with access logs plan"
        return 1
    fi

    # Verify access logs are configured
    local plan_json
    plan_json=$(terraform show -json "$TEMP_DIR/access-logs.tfplan")

    local access_logs_enabled
    access_logs_enabled=$(echo "$plan_json" | jq -r '.resource_changes[] | select(.address == "aws_lb.main") | .change.after.access_logs[0].enabled')

    if [ "$access_logs_enabled" != "true" ]; then
        print_status "$RED" "  ❌ Access logs are not enabled"
        return 1
    fi

    print_status "$GREEN" "  ✅ ALB with access logs plan generated successfully"
    return 0
}

test_plan_validation() {
    print_status "$BLUE" "  Testing plan validation..."

    # Create test configuration with invalid values
    cat > "$TEMP_DIR/invalid.tfvars" << EOF
# Invalid configuration
project_name = "test-invalid"
environment  = "invalid"  # This should fail validation

# Network configuration
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678"]  # This should fail validation (need at least 2)

# SSL certificate
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Common tags
common_tags = {
  Project     = "test-invalid"
  Environment = "invalid"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Try to generate plan with invalid configuration
    if terraform plan -var-file="$TEMP_DIR/invalid.tfvars" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Invalid configuration should have failed validation"
        return 1
    else
        print_status "$GREEN" "  ✅ Validation correctly rejected invalid configuration"
        return 0
    fi
}

test_https_target_group_plan() {
    print_status "$BLUE" "  Testing HTTPS target group plan generation..."

    # Create test configuration for HTTPS target group
    cat > "$TEMP_DIR/https-tg.tfvars" << EOF
# HTTPS target group configuration
project_name = "test-https-tg"
environment  = "dev"

# Network configuration
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]

# ALB configuration
internal = false
enable_deletion_protection = false

# Target Group configuration
target_group_port = 443
target_group_protocol = "HTTPS"
target_type = "ip"

# Health Check configuration
health_check_path = "/health"
health_check_protocol = "HTTPS"
health_check_port = "443"

# SSL certificate
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Common tags
common_tags = {
  Project     = "test-https-tg"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/https-tg.tfvars" -out="$TEMP_DIR/https-tg.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate HTTPS target group plan"
        return 1
    fi

    # Verify target group is configured for HTTPS
    local plan_json
    plan_json=$(terraform show -json "$TEMP_DIR/https-tg.tfplan")

    local tg_protocol
    tg_protocol=$(echo "$plan_json" | jq -r '.resource_changes[] | select(.address == "aws_lb_target_group.main") | .change.after.protocol')

    if [ "$tg_protocol" != "HTTPS" ]; then
        print_status "$RED" "  ❌ Target group is not configured for HTTPS"
        return 1
    fi

    print_status "$GREEN" "  ✅ HTTPS target group plan generated successfully"
    return 0
}

# Run tests
main() {
    print_status "$BLUE" "Running Terraform plan tests..."

    local tests=(
        "test_basic_alb_plan"
        "test_internal_alb_plan"
        "test_with_access_logs_plan"
        "test_plan_validation"
        "test_https_target_group_plan"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All Terraform plan tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests Terraform plan tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
