# ECS Cluster Module - Basic Tests
# This test suite validates basic ECS cluster creation and configuration

# Use mocks for unit testing
mock_provider "aws" {}

# Common variables for all tests
variables {
  project_name = "test-ecs-cluster"
  environment  = "dev"
  app          = "webapp"

  common_tags = {
    Project     = "test-ecs-cluster"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "Terraform"
  }
}

# Test basic ECS cluster creation
run "basic_cluster_creation" {
  command = plan

  variables {
    cluster_name                   = "test-cluster"
    capacity_providers             = ["FARGATE", "FARGATE_SPOT"]
    enable_container_insights      = true
    enable_execute_command_logging = false
    enable_service_connect         = false
  }

  assert {
    condition     = aws_ecs_cluster.main != null
    error_message = "Expected ECS cluster to be created"
  }

  assert {
    condition     = aws_ecs_cluster.main.name == "test-cluster"
    error_message = "ECS cluster name should be 'test-cluster'"
  }

  assert {
    condition     = can(regex("^test-cluster", aws_ecs_cluster.main.name))
    error_message = "ECS cluster name should start with 'test-cluster'"
  }
}

# Test auto-generated cluster name
run "auto_generated_cluster_name" {
  command = plan

  variables {
    cluster_name              = "" # Empty string should trigger auto-generation
    capacity_providers        = ["FARGATE"]
    enable_container_insights = true
  }

  assert {
    condition     = aws_ecs_cluster.main.name == "test-ecs-cluster-dev-ecs"
    error_message = "Auto-generated cluster name should be 'test-ecs-cluster-dev-ecs'"
  }

  assert {
    condition     = can(regex("^test-ecs-cluster-dev-ecs$", aws_ecs_cluster.main.name))
    error_message = "Auto-generated cluster name format is incorrect"
  }
}

# Test Container Insights settings
run "container_insights_enabled" {
  command = plan

  variables {
    enable_container_insights = true
  }

  assert {
    condition     = length([for s in aws_ecs_cluster.main.setting : s if s.name == "containerInsights"]) == 1
    error_message = "Container Insights setting should be present"
  }

  assert {
    condition     = [for s in aws_ecs_cluster.main.setting : s if s.name == "containerInsights"][0].value == "enabled"
    error_message = "Container Insights should be enabled"
  }
}

run "container_insights_disabled" {
  command = plan

  variables {
    enable_container_insights = false
  }

  assert {
    condition     = length([for s in aws_ecs_cluster.main.setting : s if s.name == "containerInsights"]) == 1
    error_message = "Container Insights setting should be present"
  }

  assert {
    condition     = [for s in aws_ecs_cluster.main.setting : s if s.name == "containerInsights"][0].value == "disabled"
    error_message = "Container Insights should be disabled"
  }
}

# Test capacity providers
run "capacity_providers_fargate_only" {
  command = plan

  variables {
    capacity_providers = ["FARGATE"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      }
    ]
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.main.capacity_providers) == 1
    error_message = "Expected exactly one capacity provider"
  }

  assert {
    condition     = contains(aws_ecs_cluster_capacity_providers.main.capacity_providers, "FARGATE")
    error_message = "FARGATE capacity provider should be present"
  }
}

run "capacity_providers_fargate_spot" {
  command = plan

  variables {
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
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.main.capacity_providers) == 2
    error_message = "Expected two capacity providers"
  }

  assert {
    condition     = contains(aws_ecs_cluster_capacity_providers.main.capacity_providers, "FARGATE")
    error_message = "FARGATE capacity provider should be present"
  }

  assert {
    condition     = contains(aws_ecs_cluster_capacity_providers.main.capacity_providers, "FARGATE_SPOT")
    error_message = "FARGATE_SPOT capacity provider should be present"
  }
}

# Test Execute Command logging
run "execute_command_logging_enabled" {
  command = plan

  variables {
    enable_execute_command_logging = true
    execute_command_log_group_name = "/aws/ecs/execute-command/test-cluster"
    log_retention_in_days          = 7
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.execute_command) == 1
    error_message = "Expected exactly one CloudWatch log group to be created"
  }

  assert {
    condition     = aws_cloudwatch_log_group.execute_command[0].name == "/aws/ecs/execute-command/test-cluster"
    error_message = "CloudWatch log group name should be '/aws/ecs/execute-command/test-cluster'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.execute_command[0].retention_in_days == 7
    error_message = "Log retention should be 7 days"
  }
}

run "execute_command_logging_disabled" {
  command = plan

  variables {
    enable_execute_command_logging = false
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.execute_command) == 0
    error_message = "No CloudWatch log group should be created when logging is disabled"
  }
}

# Test Service Connect configuration
# Note: Temporarily disabled due to Service Connect ARN validation issues
# run "service_connect_enabled" {
#   command = plan
#
#   variables {
#     enable_service_connect    = true
#     service_connect_namespace = "test-namespace"
#   }
#
#   assert {
#     condition     = length(aws_ecs_cluster.main.service_connect_defaults) > 0 && aws_ecs_cluster.main.service_connect_defaults[0].namespace == "test-namespace"
#     error_message = "Service Connect namespace should be 'test-namespace'"
#   }
# }

run "service_connect_disabled" {
  command = plan

  variables {
    enable_service_connect    = false
    service_connect_namespace = ""
  }

  assert {
    condition     = length(aws_ecs_cluster.main.service_connect_defaults) == 0
    error_message = "No Service Connect configuration should be present when disabled"
  }
}

# Test outputs
run "verify_outputs" {
  command = apply

  variables {
    cluster_name                   = "test-outputs-cluster"
    capacity_providers             = ["FARGATE"]
    enable_container_insights      = true
    enable_execute_command_logging = true
    enable_service_connect         = false
  }

  assert {
    condition     = output.cluster_name == "test-outputs-cluster"
    error_message = "cluster_name output should match input"
  }

  assert {
    condition     = output.cluster_id != null
    error_message = "cluster_id output should not be null"
  }

  assert {
    condition     = output.cluster_arn != null
    error_message = "cluster_arn output should not be null"
  }

  assert {
    condition     = output.capacity_providers != null
    error_message = "capacity_providers output should not be null"
  }

  assert {
    condition     = output.container_insights_enabled == true
    error_message = "container_insights_enabled output should be true"
  }

  assert {
    condition     = output.execute_command_logging_enabled == true
    error_message = "execute_command_logging_enabled output should be true"
  }

  assert {
    condition     = output.service_connect_enabled == false
    error_message = "service_connect_enabled output should be false"
  }
}

# Test tags
run "verify_tags" {
  command = apply

  variables {
    cluster_name = "test-tags-cluster"
    common_tags = {
      Project     = "test-ecs-cluster"
      Environment = "dev"
      Purpose     = "testing"
      ManagedBy   = "Terraform"
    }
  }

  assert {
    condition     = aws_ecs_cluster.main.tags["Project"] == "test-ecs-cluster"
    error_message = "Project tag should be set correctly"
  }

  assert {
    condition     = aws_ecs_cluster.main.tags["Environment"] == "dev"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = aws_ecs_cluster.main.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag should be set correctly"
  }

  assert {
    condition     = aws_ecs_cluster.main.tags["Purpose"] == "testing"
    error_message = "Purpose tag should be set correctly"
  }
}
