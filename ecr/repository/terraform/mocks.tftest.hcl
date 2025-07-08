# Mock configurations for ECR Repository Module Tests
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

  # Override for aws_caller_identity to ensure consistent account_id
  override_data {
    target = data.aws_caller_identity.current
    values = {
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

  mock_resource "aws_ecr_repository" {
    defaults = {
      arn                  = "arn:aws:ecr:ap-northeast-1:123456789012:repository/test-repo"
      name                 = "test-repo"
      registry_id          = "123456789012"
      repository_url       = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/test-repo"
      image_tag_mutability = "MUTABLE"

      image_scanning_configuration = [{
        scan_on_push = true
      }]

      encryption_configuration = [{
        encryption_type = "AES256"
        kms_key         = null
      }]

      tags = {}
    }
  }

  mock_resource "aws_ecr_lifecycle_policy" {
    defaults = {
      policy     = "{}"
      repository = "test-repo"
    }
  }

  mock_resource "aws_ecr_repository_policy" {
    defaults = {
      policy     = "{}"
      repository = "test-repo"
    }
  }

  mock_resource "aws_ecr_replication_configuration" {
    defaults = {
      replication_configuration = [{
        rule = [{
          destination = [{
            region      = "us-east-1"
            registry_id = "123456789012"
          }]
          repository_filter = [{
            filter      = "*"
            filter_type = "PREFIX_MATCH"
          }]
        }]
      }]
    }
  }

  mock_resource "aws_ecr_pull_through_cache_rule" {
    defaults = {
      ecr_repository_prefix = "test-prefix"
      upstream_registry_url = "public.ecr.aws"
    }
  }
}
