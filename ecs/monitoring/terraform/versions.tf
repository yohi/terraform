# ==================================================
# Terraform バージョン制約
# ==================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# ==================================================
# AWSプロバイダー設定
# ==================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
