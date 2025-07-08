# ECS Service Module - Basic Tests
# This test suite validates basic ECS service creation and configuration

# Using mock provider for testing
provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "ap-northeast-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

mock_provider "aws" {
  alias = "fake"

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      id                   = "vpc-12345678"
      cidr_block           = "10.0.0.0/16"
      default_vpc          = false
      enable_dns_hostnames = true
      enable_dns_support   = true
      instance_tenancy     = "default"
      tags = {
        Name = "test-vpc"
      }
    }
  }

  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-12345678", "subnet-87654321"]
      tags = {
        Name = "test-subnets"
      }
    }
  }
}

# Common variables for all tests
variables {
  project_name = "test-ecs-service"
  environment  = "dev"
  app          = "webapp"
  cluster_name = "test-cluster"

  # Required network configuration
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  common_tags = {
    Project     = "test-ecs-service"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "Terraform"
  }
}

# Test basic ECS service creation
run "basic_service_creation" {
  command = plan

  variables {
    service_name    = "test-service"
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 2
    task_cpu        = 256
    task_memory     = 512
  }

  assert {
    condition     = aws_ecs_service.main != null
    error_message = "Expected ECS service to be created"
  }

  assert {
    condition     = aws_ecs_service.main.name == "test-service"
    error_message = "ECS service name should be 'test-service'"
  }

  assert {
    condition     = aws_ecs_service.main.desired_count == 2
    error_message = "ECS service desired count should be 2"
  }
}

# Test auto-generated service name
run "auto_generated_service_name" {
  command = plan

  variables {
    service_name    = "" # Empty string should trigger auto-generation
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1
  }

  assert {
    condition     = can(regex("^test-ecs-service-dev-webapp$", aws_ecs_service.main.name))
    error_message = "Auto-generated service name should be 'test-ecs-service-dev-webapp'"
  }
}

# Test task definition creation
run "task_definition_creation" {
  command = plan

  variables {
    task_definition_family = "test-task-family"
    container_image        = "nginx:latest"
    container_port         = 80
    task_cpu               = 512
    task_memory            = 1024
    container_cpu          = 256
    container_memory       = 512
  }

  assert {
    condition     = aws_ecs_task_definition.main != null
    error_message = "Expected ECS task definition to be created"
  }

  assert {
    condition     = aws_ecs_task_definition.main.family == "test-task-family"
    error_message = "Task definition family should be 'test-task-family'"
  }

  assert {
    condition     = aws_ecs_task_definition.main.cpu == "512"
    error_message = "Task definition CPU should be '512'"
  }

  assert {
    condition     = aws_ecs_task_definition.main.memory == "1024"
    error_message = "Task definition memory should be '1024'"
  }
}

# Test security group creation
run "security_group_creation" {
  command = plan

  variables {
    container_port     = 8080
    container_protocol = "tcp"
  }

  assert {
    condition     = aws_security_group.main != null
    error_message = "Expected security group to be created"
  }

  assert {
    condition     = can(regex("test-ecs-service-dev-webapp", aws_security_group.main.name))
    error_message = "Security group name should contain service identifier"
  }

  assert {
    condition     = aws_security_group.main.vpc_id == "vpc-12345678"
    error_message = "Security group should be in correct VPC"
  }
}

# Test launch type configuration
run "fargate_launch_type" {
  command = plan

  variables {
    launch_type              = "FARGATE"
    assign_public_ip         = true
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
  }

  assert {
    condition     = aws_ecs_service.main.launch_type == "FARGATE"
    error_message = "Launch type should be FARGATE"
  }

  assert {
    condition     = aws_ecs_service.main.network_configuration[0].assign_public_ip == true
    error_message = "Public IP assignment should be enabled"
  }

  assert {
    condition     = aws_ecs_task_definition.main.network_mode == "awsvpc"
    error_message = "Network mode should be awsvpc for Fargate"
  }
}

# Test environment variables
run "environment_variables" {
  command = plan

  variables {
    environment_variables = {
      ENV       = "dev"
      LOG_LEVEL = "info"
      PORT      = "8080"
    }
  }

  assert {
    condition     = length(var.environment_variables) == 3
    error_message = "Should have 3 environment variables"
  }

  assert {
    condition     = var.environment_variables["ENV"] == "dev"
    error_message = "ENV variable should be 'dev'"
  }

  assert {
    condition     = var.environment_variables["LOG_LEVEL"] == "info"
    error_message = "LOG_LEVEL variable should be 'info'"
  }
}

# Test Auto Scaling configuration
run "auto_scaling_enabled" {
  command = plan

  variables {
    enable_auto_scaling       = true
    min_capacity              = 2
    max_capacity              = 10
    target_cpu_utilization    = 70
    target_memory_utilization = 80
  }

  assert {
    condition     = length(keys(aws_appautoscaling_target.main)) == 1
    error_message = "Auto Scaling target should be created when enabled"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_policy.cpu)) == 1
    error_message = "CPU Auto Scaling policy should be created"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_policy.memory)) == 1
    error_message = "Memory Auto Scaling policy should be created"
  }
}

run "auto_scaling_disabled" {
  command = plan

  variables {
    enable_auto_scaling = false
  }

  assert {
    condition     = length(keys(aws_appautoscaling_target.main)) == 0
    error_message = "No Auto Scaling target should be created when disabled"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_policy.cpu)) == 0
    error_message = "No CPU Auto Scaling policy should be created when disabled"
  }

  assert {
    condition     = length(keys(aws_appautoscaling_policy.memory)) == 0
    error_message = "No Memory Auto Scaling policy should be created when disabled"
  }
}

# Test CloudWatch logging
run "logging_enabled" {
  command = plan

  variables {
    enable_logging        = true
    log_group_name        = "/aws/ecs/test-service"
    log_retention_in_days = 14
  }

  assert {
    condition     = length(keys(aws_cloudwatch_log_group.main)) == 1
    error_message = "CloudWatch log group should be created when logging is enabled"
  }

  assert {
    condition     = values(aws_cloudwatch_log_group.main)[0].name == "/aws/ecs/test-service"
    error_message = "Log group name should be '/aws/ecs/test-service'"
  }

  assert {
    condition     = values(aws_cloudwatch_log_group.main)[0].retention_in_days == 14
    error_message = "Log retention should be 14 days"
  }
}

run "logging_disabled" {
  command = plan

  variables {
    enable_logging = false
  }

  assert {
    condition     = length(keys(aws_cloudwatch_log_group.main)) == 0
    error_message = "No CloudWatch log group should be created when logging is disabled"
  }
}

# Test load balancer integration
run "load_balancer_integration" {
  command = plan

  variables {
    target_group_arn                  = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-tg/1234567890123456"
    load_balancer_container_name      = "webapp"
    load_balancer_container_port      = 80
    health_check_grace_period_seconds = 60
  }

  assert {
    condition     = length(aws_ecs_service.main.load_balancer) == 1
    error_message = "Load balancer configuration should be present"
  }

  assert {
    condition     = aws_ecs_service.main.load_balancer[0].target_group_arn == "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-tg/1234567890123456"
    error_message = "Target group ARN should match"
  }

  assert {
    condition     = aws_ecs_service.main.health_check_grace_period_seconds == 60
    error_message = "Health check grace period should be 60 seconds"
  }
}

# Test deployment configuration
run "deployment_configuration" {
  command = plan

  variables {
    deployment_maximum_percent          = 200
    deployment_minimum_healthy_percent  = 50
    enable_deployment_circuit_breaker   = true
    deployment_circuit_breaker_rollback = true
  }

  assert {
    condition     = aws_ecs_service.main.deployment_maximum_percent == 200
    error_message = "Maximum deployment percent should be 200"
  }

  assert {
    condition     = aws_ecs_service.main.deployment_minimum_healthy_percent == 50
    error_message = "Minimum healthy percent should be 50"
  }

  assert {
    condition     = aws_ecs_service.main.deployment_circuit_breaker[0].enable == true
    error_message = "Deployment circuit breaker should be enabled"
  }

  assert {
    condition     = aws_ecs_service.main.deployment_circuit_breaker[0].rollback == true
    error_message = "Deployment circuit breaker rollback should be enabled"
  }
}

# Test outputs
run "verify_outputs" {
  command = apply

  variables {
    service_name        = "test-outputs-service"
    container_image     = "nginx:latest"
    container_port      = 80
    desired_count       = 1
    enable_auto_scaling = true
    enable_logging      = true
  }

  assert {
    condition     = output.service_name == "test-outputs-service"
    error_message = "service_name output should match input"
  }

  assert {
    condition     = output.task_definition_arn != null
    error_message = "task_definition_arn output should not be null"
  }

  assert {
    condition     = output.security_group_id != null
    error_message = "security_group_id output should not be null"
  }

  assert {
    condition     = output.autoscaling_target_resource_id != null
    error_message = "autoscaling_target_resource_id output should not be null when auto scaling is enabled"
  }

  assert {
    condition     = output.log_group_name != null
    error_message = "log_group_name output should not be null when logging is enabled"
  }
}

# Test tags
run "verify_tags" {
  command = apply

  variables {
    service_name    = "test-tags-service"
    container_image = "nginx:latest"
    container_port  = 80
    common_tags = {
      Project     = "test-ecs-service"
      Environment = "dev"
      Purpose     = "tag-testing"
      ManagedBy   = "Terraform"
    }
  }

  assert {
    condition     = aws_ecs_service.main.tags["Project"] == "test-ecs-service"
    error_message = "Project tag should be set correctly on service"
  }

  assert {
    condition     = aws_ecs_service.main.tags["Environment"] == "dev"
    error_message = "Environment tag should be set correctly on service"
  }

  assert {
    condition     = aws_security_group.main.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag should be set correctly on security group"
  }
}
