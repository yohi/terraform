#!/bin/bash

# Test Terraform Plan for ECS Cluster Module

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

test_basic_terraform_plan() {
    print_status "$BLUE" "  Testing basic Terraform plan generation..."

    # Create test configuration
    cat > "$TEMP_DIR/test-basic.tfvars" << EOF
# Basic test configuration for ECS cluster module
project_name = "test-ecs-cluster"
environment  = "dev"

# Basic ECS cluster settings
cluster_name = "test-cluster"
capacity_providers = ["FARGATE", "FARGATE_SPOT"]
enable_container_insights = true
enable_execute_command_logging = false
enable_service_connect = false

# Common tags
common_tags = {
  Project     = "test-ecs-cluster"
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
    if ! terraform plan -var-file="$TEMP_DIR/test-basic.tfvars" -out="$TEMP_DIR/test-basic.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate basic Terraform plan"
        return 1
    fi

    # Show plan summary
    local plan_output
    plan_output=$(terraform show -json "$TEMP_DIR/test-basic.tfplan" | jq -r '
        .resource_changes[] |
        select(.change.actions[] | contains("create")) |
        .address'
    )

    if [ -n "$plan_output" ]; then
        print_status "$GREEN" "  ✅ Basic Terraform plan generated successfully"
        print_status "$BLUE" "  📋 Resources to be created:"
        echo "$plan_output" | sed 's/^/    - /'
        return 0
    else
        print_status "$RED" "  ❌ No resources found in basic plan"
        return 1
    fi
}

test_execute_command_plan() {
    print_status "$BLUE" "  Testing Execute Command configuration plan..."

    # Create test configuration with Execute Command enabled
    cat > "$TEMP_DIR/test-execute-command.tfvars" << EOF
# Execute Command test configuration
project_name = "test-ecs-execute"
environment  = "dev"

# ECS cluster settings with Execute Command
cluster_name = "test-execute-cluster"
capacity_providers = ["FARGATE"]
enable_container_insights = true
enable_execute_command_logging = true
execute_command_log_group_name = "/aws/ecs/execute-command/test-cluster"
execute_command_kms_key_id = ""
execute_command_s3_bucket_name = ""
execute_command_s3_key_prefix = "ecs-exec"
log_retention_in_days = 7

# Common tags
common_tags = {
  Project     = "test-ecs-execute"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test-execute-command.tfvars" -out="$TEMP_DIR/test-execute-command.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate Execute Command plan"
        return 1
    fi

    # Check if CloudWatch Log Group is created
    local log_group_count
    log_group_count=$(terraform show -json "$TEMP_DIR/test-execute-command.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_cloudwatch_log_group") |
        select(.change.actions[] | contains("create"))
    ' | jq -s 'length')

    if [ "$log_group_count" -eq 1 ]; then
        print_status "$GREEN" "  ✅ Execute Command plan generated successfully"
        print_status "$BLUE" "  📋 CloudWatch Log Group will be created"
        return 0
    else
        print_status "$RED" "  ❌ Expected 1 CloudWatch Log Group, got $log_group_count"
        return 1
    fi
}

test_service_connect_plan() {
    print_status "$BLUE" "  Testing Service Connect configuration plan..."

    # Create test configuration with Service Connect enabled
    cat > "$TEMP_DIR/test-service-connect.tfvars" << EOF
# Service Connect test configuration
project_name = "test-ecs-service-connect"
environment  = "dev"

# ECS cluster settings with Service Connect
cluster_name = "test-service-connect-cluster"
capacity_providers = ["FARGATE"]
enable_container_insights = false
enable_execute_command_logging = false
enable_service_connect = true
service_connect_namespace = "test-namespace"

# Common tags
common_tags = {
  Project     = "test-ecs-service-connect"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test-service-connect.tfvars" -out="$TEMP_DIR/test-service-connect.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate Service Connect plan"
        return 1
    fi

    # Check if ECS cluster has Service Connect configuration
    local cluster_config
    cluster_config=$(terraform show -json "$TEMP_DIR/test-service-connect.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecs_cluster") |
        select(.change.actions[] | contains("create")) |
        .change.after.service_connect_defaults'
    )

    if [ "$cluster_config" != "null" ] && [ "$cluster_config" != "" ]; then
        print_status "$GREEN" "  ✅ Service Connect plan generated successfully"
        print_status "$BLUE" "  📋 ECS cluster will have Service Connect configuration"
        return 0
    else
        print_status "$RED" "  ❌ Service Connect configuration not found in plan"
        return 1
    fi
}

test_capacity_provider_strategy_plan() {
    print_status "$BLUE" "  Testing capacity provider strategy plan..."

    # Create test configuration with custom capacity provider strategy
    cat > "$TEMP_DIR/test-capacity-strategy.tfvars" << EOF
# Capacity provider strategy test configuration
project_name = "test-ecs-capacity-strategy"
environment  = "dev"

# ECS cluster settings with custom capacity provider strategy
cluster_name = "test-capacity-strategy-cluster"
capacity_providers = ["FARGATE", "FARGATE_SPOT"]
default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  },
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
    base              = 0
  }
]
enable_container_insights = true
enable_execute_command_logging = false
enable_service_connect = false

# Common tags
common_tags = {
  Project     = "test-ecs-capacity-strategy"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test-capacity-strategy.tfvars" -out="$TEMP_DIR/test-capacity-strategy.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate capacity provider strategy plan"
        return 1
    fi

    # Check if capacity provider configuration is created
    local capacity_provider_count
    capacity_provider_count=$(terraform show -json "$TEMP_DIR/test-capacity-strategy.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecs_cluster_capacity_providers") |
        select(.change.actions[] | contains("create"))
    ' | jq -s 'length')

    if [ "$capacity_provider_count" -eq 1 ]; then
        print_status "$GREEN" "  ✅ Capacity provider strategy plan generated successfully"
        print_status "$BLUE" "  📋 ECS cluster capacity providers will be configured"
        return 0
    else
        print_status "$RED" "  ❌ Expected 1 capacity provider configuration, got $capacity_provider_count"
        return 1
    fi
}

test_minimal_configuration_plan() {
    print_status "$BLUE" "  Testing minimal configuration plan..."

    # Create minimal test configuration
    cat > "$TEMP_DIR/test-minimal.tfvars" << EOF
# Minimal test configuration
project_name = "test-ecs-minimal"
environment  = "dev"

# Common tags
common_tags = {
  Project     = "test-ecs-minimal"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test-minimal.tfvars" -out="$TEMP_DIR/test-minimal.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate minimal configuration plan"
        return 1
    fi

    # Check if minimal resources are created
    local resource_count
    resource_count=$(terraform show -json "$TEMP_DIR/test-minimal.tfplan" | jq -r '
        .resource_changes[] |
        select(.change.actions[] | contains("create"))
    ' | jq -s 'length')

    if [ "$resource_count" -ge 2 ]; then
        print_status "$GREEN" "  ✅ Minimal configuration plan generated successfully"
        print_status "$BLUE" "  📋 Will create $resource_count resources"
        return 0
    else
        print_status "$RED" "  ❌ Expected at least 2 resources, got $resource_count"
        return 1
    fi
}

test_plan_validation() {
    print_status "$BLUE" "  Testing plan validation..."

    # Create test configuration with invalid Service Connect setup
    cat > "$TEMP_DIR/test-invalid.tfvars" << EOF
# Invalid test configuration
project_name = "test-ecs-invalid"
environment  = "dev"

# Invalid Service Connect configuration (enabled but no namespace)
cluster_name = "test-invalid-cluster"
enable_service_connect = true
service_connect_namespace = ""

# Common tags
common_tags = {
  Project     = "test-ecs-invalid"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Try to generate plan with invalid configuration
    if terraform plan -var-file="$TEMP_DIR/test-invalid.tfvars" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Invalid configuration should have failed validation"
        return 1
    else
        print_status "$GREEN" "  ✅ Validation correctly rejected invalid configuration"
        return 0
    fi
}

test_resource_dependencies() {
    print_status "$BLUE" "  Testing resource dependencies..."

    # Create test configuration with Execute Command logging
    cat > "$TEMP_DIR/test-dependencies.tfvars" << EOF
# Dependencies test configuration
project_name = "test-ecs-dependencies"
environment  = "dev"

# ECS cluster settings with Execute Command (creates dependencies)
cluster_name = "test-dependencies-cluster"
enable_execute_command_logging = true
log_retention_in_days = 14

# Common tags
common_tags = {
  Project     = "test-ecs-dependencies"
  Environment = "dev"
  Purpose     = "testing"
  ManagedBy   = "terraform"
}
EOF

    # Change to terraform directory
    cd "$TERRAFORM_DIR"

    # Generate plan
    if ! terraform plan -var-file="$TEMP_DIR/test-dependencies.tfvars" -out="$TEMP_DIR/test-dependencies.tfplan" > /dev/null 2>&1; then
        print_status "$RED" "  ❌ Failed to generate dependencies plan"
        return 1
    fi

    # Check if dependencies are properly established
    local dependency_check
    dependency_check=$(terraform show -json "$TEMP_DIR/test-dependencies.tfplan" | jq -r '
        .resource_changes[] |
        select(.type == "aws_ecs_cluster") |
        select(.change.actions[] | contains("create")) |
        .change.after.configuration[0].execute_command_configuration[0].log_configuration[0].cloud_watch_log_group_name'
    )

    if [ "$dependency_check" != "null" ] && [ "$dependency_check" != "" ]; then
        print_status "$GREEN" "  ✅ Resource dependencies are properly established"
        return 0
    else
        print_status "$RED" "  ❌ Resource dependencies not found in plan"
        return 1
    fi
}

# Run tests
main() {
    print_status "$BLUE" "Running Terraform plan tests for ECS Cluster Module..."

    local failed_tests=0

    # Run all tests
    test_basic_terraform_plan || ((failed_tests++))
    test_execute_command_plan || ((failed_tests++))
    test_service_connect_plan || ((failed_tests++))
    test_capacity_provider_strategy_plan || ((failed_tests++))
    test_minimal_configuration_plan || ((failed_tests++))
    test_plan_validation || ((failed_tests++))
    test_resource_dependencies || ((failed_tests++))

    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All Terraform plan tests passed!"
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
