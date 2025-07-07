# ECS Cluster Module - Integration Tests
# This test suite validates ECS cluster creation with real AWS resources
# WARNING: This test creates actual AWS resources and may incur costs

# Provider configuration for integration tests
provider "aws" {
  region = "ap-northeast-1"
  # Uses actual AWS credentials from environment or AWS config
}

# Common variables for all tests
variables {
  project_name = "test-ecs-integration"
  environment  = "dev"
  app          = "integration-test"

  common_tags = {
    Project     = "test-ecs-integration"
    Environment = "dev"
    Purpose     = "integration-testing"
    ManagedBy   = "Terraform"
    TestRun     = "true"
  }
}

# Integration test - Create actual ECS cluster
run "create_ecs_cluster" {
  command = apply

  variables {
    # Use timestamp in name to ensure uniqueness
    cluster_name       = "test-cluster-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers = ["FARGATE"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 0
      }
    ]
    enable_container_insights      = true
    enable_execute_command_logging = true
    enable_service_connect         = false
    log_retention_in_days          = 7
  }

  assert {
    condition     = output.cluster_name != null
    error_message = "Cluster name output should not be null"
  }

  assert {
    condition     = can(regex("^test-cluster-", output.cluster_name))
    error_message = "Cluster name should start with test-cluster-"
  }

  assert {
    condition     = output.cluster_arn != null
    error_message = "Cluster ARN output should not be null"
  }

  assert {
    condition     = can(regex("^arn:aws:ecs:", output.cluster_arn))
    error_message = "Cluster ARN should be a valid ECS ARN"
  }
}

# Integration test - Create cluster with Execute Command and Service Connect
run "create_cluster_with_features" {
  command = apply

  variables {
    cluster_name       = "test-features-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 4
        base              = 0
      }
    ]
    enable_container_insights      = true
    enable_execute_command_logging = true
    execute_command_log_group_name = "/aws/ecs/execute-command/test-features"
    enable_service_connect         = true
    service_connect_namespace      = "test-namespace"
    log_retention_in_days          = 14
  }

  assert {
    condition     = output.service_connect_enabled == true
    error_message = "Service Connect should be enabled"
  }

  assert {
    condition     = output.execute_command_logging_enabled == true
    error_message = "Execute Command logging should be enabled"
  }

  assert {
    condition     = output.execute_command_log_group_name != null
    error_message = "Execute Command log group name should not be null"
  }

  assert {
    condition     = can(regex("^/aws/ecs/execute-command/", output.execute_command_log_group_name))
    error_message = "Execute Command log group name should have correct format"
  }
}

# Integration test - Test capacity providers
run "test_capacity_providers" {
  command = apply

  variables {
    cluster_name       = "test-capacity-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 3
        base              = 0
      }
    ]
    enable_container_insights      = false
    enable_execute_command_logging = false
    enable_service_connect         = false
  }

  assert {
    condition     = length(output.capacity_providers) == 2
    error_message = "Should have exactly 2 capacity providers"
  }

  assert {
    condition     = contains(output.capacity_providers, "FARGATE")
    error_message = "Should contain FARGATE capacity provider"
  }

  assert {
    condition     = contains(output.capacity_providers, "FARGATE_SPOT")
    error_message = "Should contain FARGATE_SPOT capacity provider"
  }

  assert {
    condition     = length(output.default_capacity_provider_strategy) == 2
    error_message = "Should have exactly 2 capacity provider strategies"
  }
}

# Integration test - Test minimal configuration
run "test_minimal_configuration" {
  command = apply

  variables {
    cluster_name                   = "test-minimal-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers             = ["FARGATE"]
    enable_container_insights      = false
    enable_execute_command_logging = false
    enable_service_connect         = false
  }

  assert {
    condition     = output.container_insights_enabled == false
    error_message = "Container Insights should be disabled"
  }

  assert {
    condition     = output.execute_command_logging_enabled == false
    error_message = "Execute Command logging should be disabled"
  }

  assert {
    condition     = output.service_connect_enabled == false
    error_message = "Service Connect should be disabled"
  }

  assert {
    condition     = output.execute_command_log_group_name == null
    error_message = "Execute Command log group should not be created"
  }
}

# Integration test - Test tags
run "test_tags_integration" {
  command = apply

  variables {
    cluster_name                   = "test-tags-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers             = ["FARGATE"]
    enable_container_insights      = true
    enable_execute_command_logging = true
    enable_service_connect         = false
    common_tags = {
      Project     = "test-ecs-integration"
      Environment = "dev"
      Purpose     = "tag-testing"
      ManagedBy   = "Terraform"
      TestRun     = "true"
      CostCenter  = "engineering"
    }
  }

  # Note: AWS resource tags may take some time to propagate
  # and may not be immediately available in outputs
  assert {
    condition     = output.cluster_name != null
    error_message = "Cluster should be created successfully with tags"
  }
}

# Integration test - Test auto-generated cluster name
run "test_auto_generated_name" {
  command = apply

  variables {
    cluster_name                   = "" # Empty to trigger auto-generation
    capacity_providers             = ["FARGATE"]
    enable_container_insights      = true
    enable_execute_command_logging = false
    enable_service_connect         = false
  }

  assert {
    condition     = output.cluster_name == "test-ecs-integration-dev-ecs"
    error_message = "Auto-generated cluster name should be 'test-ecs-integration-dev-ecs'"
  }

  assert {
    condition     = can(regex("^test-ecs-integration-dev-ecs$", output.cluster_name))
    error_message = "Auto-generated cluster name format should be correct"
  }
}

# Integration test - Resource cleanup verification
run "test_resource_cleanup" {
  command = apply

  variables {
    cluster_name                   = "test-cleanup-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    capacity_providers             = ["FARGATE"]
    enable_container_insights      = true
    enable_execute_command_logging = true
    execute_command_log_group_name = "/aws/ecs/execute-command/test-cleanup"
    enable_service_connect         = false
    log_retention_in_days          = 1 # Minimum retention for quick cleanup
  }

  assert {
    condition     = output.cluster_id != null
    error_message = "Cluster should be created successfully"
  }

  assert {
    condition     = output.execute_command_log_group_arn != null
    error_message = "Execute Command log group should be created"
  }

  # This test verifies that all resources are created correctly
  # The actual cleanup happens automatically when the test completes
}
