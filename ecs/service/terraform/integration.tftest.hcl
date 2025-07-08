# ECS Service Module - Integration Tests
# This test suite validates ECS service creation with real AWS resources
# WARNING: This test creates actual AWS resources and may incur costs

# Provider configuration for integration tests
provider "aws" {
  region = "ap-northeast-1"
  # Uses actual AWS credentials from environment or AWS config
}

# Common variables for all tests
variables {
  project_name = "test-ecs-service-integration"
  environment  = "dev"
  app          = "integration-test"
  cluster_name = "test-cluster"

  # Network configuration (must be provided before running tests)
  # These can be set via environment variables:
  # - TF_VAR_vpc_id
  # - TF_VAR_subnet_ids
  # Or via terraform.tfvars file
  vpc_id     = null # Set via TF_VAR_vpc_id environment variable or terraform.tfvars
  subnet_ids = null # Set via TF_VAR_subnet_ids environment variable or terraform.tfvars

  common_tags = {
    Project     = "test-ecs-service-integration"
    Environment = "dev"
    Purpose     = "integration-testing"
    ManagedBy   = "Terraform"
    TestRun     = "true"
  }
}

# Integration test - Create actual ECS service
run "create_ecs_service" {
  command = apply

  variables {
    # Use timestamp suffix to avoid conflicts
    service_name = "test-service-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1

    # Task configuration
    task_cpu    = 256
    task_memory = 512

    # Enable logging
    enable_logging        = true
    log_retention_in_days = 1

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true

    # Deployment configuration
    deployment_maximum_percent          = 200
    deployment_minimum_healthy_percent  = 50
    enable_deployment_circuit_breaker   = true
    deployment_circuit_breaker_rollback = true
  }

  assert {
    condition     = aws_ecs_service.main.name != null
    error_message = "ECS service should be created"
  }

  assert {
    condition     = aws_ecs_task_definition.main.arn != null
    error_message = "Task definition should be created"
  }

  assert {
    condition     = aws_security_group.main.id != null
    error_message = "Security group should be created"
  }

  assert {
    condition     = output.service_name != null
    error_message = "Service name output should be available"
  }

  assert {
    condition     = output.task_definition_arn != null
    error_message = "Task definition ARN output should be available"
  }
}

# Integration test - Create service with features
run "create_service_with_features" {
  command = apply

  variables {
    service_name = "test-service-features-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 2

    # Task configuration
    task_cpu    = 512
    task_memory = 1024

    # Enable Auto Scaling
    enable_auto_scaling       = true
    min_capacity              = 1
    max_capacity              = 4
    target_cpu_utilization    = 70
    target_memory_utilization = 80

    # Enable logging
    enable_logging        = true
    log_retention_in_days = 7

    # Environment variables
    environment_variables = {
      ENV       = "integration-test"
      LOG_LEVEL = "info"
    }

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true
  }

  assert {
    condition     = aws_ecs_service.main.desired_count == 2
    error_message = "Service should have desired count of 2"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_target.main)) == 1
    error_message = "Auto Scaling target should be created"
  }

  assert {
    condition     = length(keys(aws_cloudwatch_log_group.main)) == 1
    error_message = "CloudWatch log group should be created"
  }

  assert {
    condition     = output.autoscaling_target_resource_id != null
    error_message = "Auto Scaling target resource ID should be available"
  }

  assert {
    condition     = output.log_group_name != null
    error_message = "Log group name should be available"
  }
}

# Integration test - Test minimal configuration
run "test_minimal_configuration" {
  command = apply

  variables {
    service_name = "test-service-minimal-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

    # Only required variables
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1

    # Minimal task configuration
    task_cpu    = 256
    task_memory = 512

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true

    # Disable optional features
    enable_auto_scaling = false
    enable_logging      = false
  }

  assert {
    condition     = aws_ecs_service.main.desired_count == 1
    error_message = "Service should have desired count of 1"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_target.main)) == 0
    error_message = "No Auto Scaling target should be created"
  }

  assert {
    condition     = length(keys(aws_cloudwatch_log_group.main)) == 0
    error_message = "No CloudWatch log group should be created"
  }
}

# Integration test - Test tags
run "test_tags_integration" {
  command = apply

  variables {
    service_name = "test-service-tags-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1

    # Task configuration
    task_cpu    = 256
    task_memory = 512

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true

    # Custom tags
    common_tags = {
      Project     = "test-ecs-service-integration"
      Environment = "dev"
      Purpose     = "tag-testing"
      ManagedBy   = "Terraform"
      TestRun     = "true"
      Owner       = "integration-test"
    }
  }

  assert {
    condition     = aws_ecs_service.main.tags["Project"] == "test-ecs-service-integration"
    error_message = "Service should have correct Project tag"
  }

  assert {
    condition     = aws_ecs_service.main.tags["Owner"] == "integration-test"
    error_message = "Service should have correct Owner tag"
  }

  assert {
    condition     = aws_security_group.main.tags["ManagedBy"] == "Terraform"
    error_message = "Security group should have correct ManagedBy tag"
  }

  assert {
    condition     = aws_ecs_task_definition.main.tags["TestRun"] == "true"
    error_message = "Task definition should have correct TestRun tag"
  }
}

# Integration test - Test auto-generated names
run "test_auto_generated_name" {
  command = apply

  variables {
    service_name = "" # Empty to trigger auto-generation

    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1

    # Task configuration
    task_cpu    = 256
    task_memory = 512

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true
  }

  assert {
    condition     = can(regex("^${format("%s-%s-%s", var.project_name, var.environment, var.app)}$", aws_ecs_service.main.name))
    error_message = "Service name should be auto-generated correctly"
  }

  assert {
    condition     = can(regex("^${format("%s-%s-%s", var.project_name, var.environment, var.app)}$", aws_ecs_task_definition.main.family))
    error_message = "Task definition family should be auto-generated correctly"
  }

  assert {
    condition     = output.service_name == aws_ecs_service.main.name
    error_message = "Output service name should match actual service name"
  }
}

# Integration test - Test resource cleanup
run "test_resource_cleanup" {
  command = apply

  variables {
    service_name = "test-service-cleanup-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1

    # Task configuration
    task_cpu    = 256
    task_memory = 512

    # Network configuration
    launch_type      = "FARGATE"
    assign_public_ip = true

    # Enable all features to test cleanup
    enable_auto_scaling   = true
    min_capacity          = 1
    max_capacity          = 3
    enable_logging        = true
    log_retention_in_days = 1
  }

  assert {
    condition     = aws_ecs_service.main.name != null
    error_message = "All resources should be created for cleanup test"
  }

  assert {
    condition     = values(aws_appautoscaling_target.main)[0].resource_id != null
    error_message = "Auto Scaling target should be created for cleanup test"
  }

  assert {
    condition     = values(aws_cloudwatch_log_group.main)[0].name != null
    error_message = "CloudWatch log group should be created for cleanup test"
  }
}
