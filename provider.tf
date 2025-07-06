# ==================================================
# AWS Provider Configuration
# ==================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==================================================
# 必須タグの強制設定
# ==================================================

locals {
  # 必須タグを保証するために、var.common_tagsと必須タグをマージ
  required_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # 最終的なタグ設定（common_tagsで上書き可能、ただし必須タグは保証）
  final_tags = merge(var.common_tags, local.required_tags)
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.final_tags
  }
}
