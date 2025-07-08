# Mock configurations for ECS Cluster Module Tests
# This file provides mock data for AWS resources during unit testing

mock_provider "aws" {
  alias = "fake"

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

  mock_resource "aws_ecs_cluster" {
    defaults = {
      arn  = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/test-cluster"
      name = "test-cluster"
      id   = "test-cluster"
      tags = {
        Name      = "test-cluster"
        ManagedBy = "Terraform"
      }
      tags_all = {
        Name      = "test-cluster"
        ManagedBy = "Terraform"
      }
      configuration            = []
      service_connect_defaults = []
      setting = [
        {
          name  = "containerInsights"
          value = "enabled"
        }
      ]
    }
  }

  mock_resource "aws_ecs_cluster_capacity_providers" {
    defaults = {
      cluster_name       = "test-cluster"
      capacity_providers = ["FARGATE", "FARGATE_SPOT"]
      default_capacity_provider_strategy = [
        {
          capacity_provider = "FARGATE"
          weight            = 1
          base              = 0
        },
        {
          capacity_provider = "FARGATE_SPOT"
          weight            = 4
          base              = 0
        }
      ]
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn               = "arn:aws:logs:ap-northeast-1:123456789012:log-group:/aws/ecs/execute-command/test-cluster"
      name              = "/aws/ecs/execute-command/test-cluster"
      retention_in_days = 30
      kms_key_id        = null
      tags = {
        Name      = "/aws/ecs/execute-command/test-cluster"
        ManagedBy = "Terraform"
      }
      tags_all = {
        Name      = "/aws/ecs/execute-command/test-cluster"
        ManagedBy = "Terraform"
      }
    }
  }
}

# Override for aws_caller_identity to ensure consistent account_id
override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "123456789012"
    arn        = "arn:aws:iam::123456789012:user/test-user"
    user_id    = "AIDACKCEVSQ6C2EXAMPLE"
  }
}

# Override for aws_region to ensure consistent region
override_data {
  target = data.aws_region.current
  values = {
    name        = "ap-northeast-1"
    description = "Asia Pacific (Tokyo)"
  }
}
