# Mock configurations for ECS Service Module Tests
# This file provides mock data for AWS resources during unit testing

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name        = "ap-northeast-1"
      description = "Asia Pacific (Tokyo)"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
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

  mock_data "aws_subnet" {
    defaults = {
      id                      = "subnet-12345678"
      vpc_id                  = "vpc-12345678"
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "ap-northeast-1a"
      map_public_ip_on_launch = true
      tags = {
        Name = "test-subnet"
      }
    }
  }

  mock_resource "aws_ecs_service" {
    defaults = {
      id                  = "test-service"
      name                = "test-service"
      cluster             = "test-cluster"
      task_definition     = "test-task-definition:1"
      desired_count       = 2
      launch_type         = "FARGATE"
      platform_version    = "LATEST"
      scheduling_strategy = "REPLICA"

      network_configuration = [{
        subnets          = ["subnet-12345678", "subnet-87654321"]
        security_groups  = ["sg-12345678"]
        assign_public_ip = true
      }]

      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 50
      deployment_circuit_breaker = [{
        enable   = true
        rollback = true
      }]

      load_balancer = []

      tags = {
        Name        = "test-service"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_ecs_task_definition" {
    defaults = {
      arn                      = "arn:aws:ecs:ap-northeast-1:123456789012:task-definition/test-task-definition:1"
      family                   = "test-task-definition"
      revision                 = 1
      task_role_arn            = "arn:aws:iam::123456789012:role/test-task-role"
      execution_role_arn       = "arn:aws:iam::123456789012:role/test-execution-role"
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"

      container_definitions = "[{\"name\":\"webapp\",\"image\":\"nginx:latest\",\"cpu\":256,\"memory\":512,\"essential\":true,\"portMappings\":[{\"containerPort\":80,\"hostPort\":80,\"protocol\":\"tcp\"}],\"environment\":[],\"secrets\":[],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/aws/ecs/test-service\",\"awslogs-region\":\"ap-northeast-1\",\"awslogs-stream-prefix\":\"ecs\"}}}]"

      tags = {
        Name        = "test-task-definition"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id          = "sg-12345678"
      name        = "test-ecs-service-dev-webapp-sg"
      description = "Security group for ECS service"
      vpc_id      = "vpc-12345678"

      ingress = [{
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP"
      }]

      egress = [{
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }]

      tags = {
        Name        = "test-ecs-service-dev-webapp-sg"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      id   = "test-role"
      name = "test-role"
      arn  = "arn:aws:iam::123456789012:role/test-role"

      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"}}]}"

      tags = {
        Name        = "test-role"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_iam_role_policy_attachment" {
    defaults = {
      id         = "test-role-policy-attachment"
      role       = "test-role"
      policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      id                = "/aws/ecs/test-service"
      name              = "/aws/ecs/test-service"
      retention_in_days = 7

      tags = {
        Name        = "/aws/ecs/test-service"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_appautoscaling_target" {
    defaults = {
      id                 = "service/test-cluster/test-service"
      service_namespace  = "ecs"
      resource_id        = "service/test-cluster/test-service"
      scalable_dimension = "ecs:service:DesiredCount"
      min_capacity       = 2
      max_capacity       = 10

      tags = {
        Name        = "test-service-scaling-target"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }

  mock_resource "aws_appautoscaling_policy" {
    defaults = {
      id                 = "test-service-cpu-scaling"
      name               = "test-service-cpu-scaling"
      service_namespace  = "ecs"
      resource_id        = "service/test-cluster/test-service"
      scalable_dimension = "ecs:service:DesiredCount"
      policy_type        = "TargetTrackingScaling"

      target_tracking_scaling_policy_configuration = [{
        target_value = 70.0
        predefined_metric_specification = [{
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }]
      }]

      tags = {
        Name        = "test-service-cpu-scaling"
        Environment = "dev"
        ManagedBy   = "Terraform"
      }
    }
  }
}

# Test with mock provider
run "test_with_mocks" {
  command = apply

  variables {
    project_name = "test-ecs-service"
    environment  = "dev"
    app          = "webapp"
    cluster_name = "test-cluster"

    # Service configuration
    service_name    = "test-service"
    container_image = "nginx:latest"
    container_port  = 80
    desired_count   = 2

    # Task configuration
    task_cpu    = 256
    task_memory = 512

    # Network configuration
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]

    # Common tags
    common_tags = {
      Project     = "test-ecs-service"
      Environment = "dev"
      Purpose     = "testing"
      ManagedBy   = "Terraform"
    }
  }

  assert {
    condition     = aws_ecs_service.main.name == "test-service"
    error_message = "Service name should be test-service"
  }

  assert {
    condition     = aws_ecs_task_definition.main.family == "test-ecs-service-dev-webapp"
    error_message = "Task definition family should be auto-generated"
  }

  assert {
    condition     = aws_security_group.main.vpc_id == "vpc-12345678"
    error_message = "Security group should be in correct VPC"
  }
}
