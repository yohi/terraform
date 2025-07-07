# ECS Service Module - Validation Tests
# This test suite validates input variable validation rules

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
  project_name = "test-validation"
  app          = "webapp"
  cluster_name = "test-cluster"

  # Required network configuration
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  common_tags = {
    Project     = "test-validation"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "Terraform"
  }
}

# Test valid environment values
run "valid_environment_dev" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment dev should be valid"
  }
}

run "valid_environment_stg" {
  command = plan

  variables {
    environment     = "stg"
    container_image = "nginx:latest"
    container_port  = 80
  }

  assert {
    condition     = var.environment == "stg"
    error_message = "Environment stg should be valid"
  }
}

run "valid_environment_prd" {
  command = plan

  variables {
    environment     = "prd"
    container_image = "nginx:latest"
    container_port  = 80
  }

  assert {
    condition     = var.environment == "prd"
    error_message = "Environment prd should be valid"
  }
}

# Test invalid environment values
run "invalid_environment_production" {
  command = plan

  variables {
    environment     = "production"
    container_image = "nginx:latest"
    container_port  = 80
  }

  expect_failures = [
    var.environment,
  ]
}

run "invalid_environment_staging" {
  command = plan

  variables {
    environment     = "staging"
    container_image = "nginx:latest"
    container_port  = 80
  }

  expect_failures = [
    var.environment,
  ]
}

# Test CPU and memory validation
run "valid_cpu_256" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
    task_cpu        = 256
    task_memory     = 512
  }

  assert {
    condition     = var.task_cpu == 256
    error_message = "Task CPU 256 should be valid"
  }

  assert {
    condition     = var.task_memory == 512
    error_message = "Task memory 512 should be valid with CPU 256"
  }
}

run "valid_cpu_512" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
    task_cpu        = 512
    task_memory     = 1024
  }

  assert {
    condition     = var.task_cpu == 512
    error_message = "Task CPU 512 should be valid"
  }

  assert {
    condition     = var.task_memory == 1024
    error_message = "Task memory 1024 should be valid with CPU 512"
  }
}

run "valid_cpu_1024" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
    task_cpu        = 1024
    task_memory     = 2048
  }

  assert {
    condition     = var.task_cpu == 1024
    error_message = "Task CPU 1024 should be valid"
  }

  assert {
    condition     = var.task_memory == 2048
    error_message = "Task memory 2048 should be valid with CPU 1024"
  }
}

# Test port validation
run "valid_port_80" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
  }

  assert {
    condition     = var.container_port == 80
    error_message = "Container port 80 should be valid"
  }
}

run "valid_port_8080" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 8080
  }

  assert {
    condition     = var.container_port == 8080
    error_message = "Container port 8080 should be valid"
  }
}

run "valid_port_443" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 443
  }

  assert {
    condition     = var.container_port == 443
    error_message = "Container port 443 should be valid"
  }
}

# Test desired count validation
run "valid_desired_count_1" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 1
  }

  assert {
    condition     = var.desired_count == 1
    error_message = "Desired count 1 should be valid"
  }
}

run "valid_desired_count_3" {
  command = plan

  variables {
    environment     = "dev"
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 3
  }

  assert {
    condition     = var.desired_count == 3
    error_message = "Desired count 3 should be valid"
  }
}

# Test auto scaling configuration
run "valid_auto_scaling_configuration" {
  command = plan

  variables {
    environment            = "dev"
    container_image        = "nginx:latest"
    container_port         = 80
    enable_auto_scaling    = true
    min_capacity           = 2
    max_capacity           = 10
    target_cpu_utilization = 70
  }

  assert {
    condition     = var.enable_auto_scaling == true
    error_message = "Auto scaling should be enabled"
  }

  assert {
    condition     = var.min_capacity == 2
    error_message = "Minimum capacity should be 2"
  }

  assert {
    condition     = var.max_capacity == 10
    error_message = "Maximum capacity should be 10"
  }

  assert {
    condition     = var.target_cpu_utilization == 70
    error_message = "Target CPU utilization should be 70"
  }

  assert {
    condition     = var.min_capacity <= var.max_capacity
    error_message = "Minimum capacity should be less than or equal to maximum capacity"
  }
}

# Test launch type validation
run "valid_launch_type_fargate" {
  command = plan

  variables {
    environment              = "dev"
    container_image          = "nginx:latest"
    container_port           = 80
    launch_type              = "FARGATE"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
  }

  assert {
    condition     = var.launch_type == "FARGATE"
    error_message = "Launch type FARGATE should be valid"
  }

  assert {
    condition     = var.network_mode == "awsvpc"
    error_message = "Network mode awsvpc should be valid with FARGATE"
  }

  assert {
    condition     = contains(var.requires_compatibilities, "FARGATE")
    error_message = "Requires compatibilities should include FARGATE"
  }
}

run "valid_launch_type_ec2" {
  command = plan

  variables {
    environment              = "dev"
    container_image          = "nginx:latest"
    container_port           = 80
    launch_type              = "EC2"
    network_mode             = "bridge"
    requires_compatibilities = ["EC2"]
  }

  assert {
    condition     = var.launch_type == "EC2"
    error_message = "Launch type EC2 should be valid"
  }

  assert {
    condition     = var.network_mode == "bridge"
    error_message = "Network mode bridge should be valid with EC2"
  }

  assert {
    condition     = contains(var.requires_compatibilities, "EC2")
    error_message = "Requires compatibilities should include EC2"
  }
}

# Test log retention validation
run "valid_log_retention_1_day" {
  command = plan

  variables {
    environment           = "dev"
    container_image       = "nginx:latest"
    container_port        = 80
    enable_logging        = true
    log_retention_in_days = 1
  }

  assert {
    condition     = var.log_retention_in_days == 1
    error_message = "Log retention 1 day should be valid"
  }
}

run "valid_log_retention_7_days" {
  command = plan

  variables {
    environment           = "dev"
    container_image       = "nginx:latest"
    container_port        = 80
    enable_logging        = true
    log_retention_in_days = 7
  }

  assert {
    condition     = var.log_retention_in_days == 7
    error_message = "Log retention 7 days should be valid"
  }
}

run "valid_log_retention_30_days" {
  command = plan

  variables {
    environment           = "dev"
    container_image       = "nginx:latest"
    container_port        = 80
    enable_logging        = true
    log_retention_in_days = 30
  }

  assert {
    condition     = var.log_retention_in_days == 30
    error_message = "Log retention 30 days should be valid"
  }
}

# Test health check configuration
run "valid_health_check_configuration" {
  command = plan

  variables {
    environment                       = "dev"
    container_image                   = "nginx:latest"
    container_port                    = 80
    target_group_arn                  = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-tg/1234567890123456"
    health_check_grace_period_seconds = 60
  }

  assert {
    condition     = var.health_check_grace_period_seconds == 60
    error_message = "Health check grace period should be 60 seconds"
  }

  assert {
    condition     = var.health_check_grace_period_seconds >= 0
    error_message = "Health check grace period should be non-negative"
  }
}

# Test deployment configuration validation
run "valid_deployment_configuration" {
  command = plan

  variables {
    environment                         = "dev"
    container_image                     = "nginx:latest"
    container_port                      = 80
    deployment_maximum_percent          = 200
    deployment_minimum_healthy_percent  = 50
    enable_deployment_circuit_breaker   = true
    deployment_circuit_breaker_rollback = true
  }

  assert {
    condition     = var.deployment_maximum_percent == 200
    error_message = "Deployment maximum percent should be 200"
  }

  assert {
    condition     = var.deployment_minimum_healthy_percent == 50
    error_message = "Deployment minimum healthy percent should be 50"
  }

  assert {
    condition     = var.deployment_maximum_percent >= 100
    error_message = "Deployment maximum percent should be at least 100"
  }

  assert {
    condition     = var.deployment_minimum_healthy_percent >= 0
    error_message = "Deployment minimum healthy percent should be non-negative"
  }

  assert {
    condition     = var.deployment_minimum_healthy_percent <= 100
    error_message = "Deployment minimum healthy percent should be at most 100"
  }

  assert {
    condition     = var.enable_deployment_circuit_breaker == true
    error_message = "Deployment circuit breaker should be enabled"
  }

  assert {
    condition     = var.deployment_circuit_breaker_rollback == true
    error_message = "Deployment circuit breaker rollback should be enabled"
  }
}

# Test network configuration validation
run "valid_network_configuration" {
  command = plan

  variables {
    environment      = "dev"
    container_image  = "nginx:latest"
    container_port   = 80
    launch_type      = "FARGATE"
    assign_public_ip = true
    vpc_id           = "vpc-12345678"
    subnet_ids       = ["subnet-12345678", "subnet-87654321"]
  }

  assert {
    condition     = var.assign_public_ip == true
    error_message = "Assign public IP should be true"
  }

  assert {
    condition     = var.vpc_id == "vpc-12345678"
    error_message = "VPC ID should be correct"
  }

  assert {
    condition     = length(var.subnet_ids) == 2
    error_message = "Should have 2 subnet IDs"
  }

  assert {
    condition     = contains(var.subnet_ids, "subnet-12345678")
    error_message = "Should contain first subnet ID"
  }

  assert {
    condition     = contains(var.subnet_ids, "subnet-87654321")
    error_message = "Should contain second subnet ID"
  }
}
