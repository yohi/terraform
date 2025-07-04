# ==================================================
# ローカル変数
# ==================================================

locals {
  # 単一リポジトリの名前決定
  single_repository_name = var.repository_name != "" ? var.repository_name : (
    var.app != "" ? "${var.project}-${var.env}-${var.app}" : "${var.project}-${var.env}"
  )

  # リポジトリのリスト作成（単一リポジトリまたは複数リポジトリ）
  repositories = length(var.repositories) > 0 ? var.repositories : [
    {
      name                 = local.single_repository_name
      image_tag_mutability = var.image_tag_mutability
      scan_on_push         = var.scan_on_push
      encryption_type      = var.encryption_type
      kms_key_id           = var.kms_key_id
    }
  ]

  # デフォルトライフサイクルポリシー
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.untagged_image_count_limit} untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.untagged_image_count_limit
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.tagged_image_count_limit} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "main", "master", "dev", "staging", "prod"]
          countType     = "imageCountMoreThan"
          countNumber   = var.tagged_image_count_limit
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete images older than ${var.image_age_limit_days} days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.image_age_limit_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # 最終的なライフサイクルポリシー
  lifecycle_policy = var.lifecycle_policy_rules != "" ? var.lifecycle_policy_rules : local.default_lifecycle_policy

  # デフォルトリポジトリポリシー
  default_repository_policy = length(var.allowed_principals) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = var.allowed_actions
      }
    ]
  }) : ""

  # 最終的なリポジトリポリシー
  repository_policy = var.repository_policy_json != "" ? var.repository_policy_json : local.default_repository_policy
}

# ==================================================
# データソース
# ==================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ==================================================
# ECRリポジトリ
# ==================================================

resource "aws_ecr_repository" "main" {
  for_each = { for repo in local.repositories : repo.name => repo }

  lifecycle {
    precondition {
      condition     = each.value.encryption_type != "KMS" || each.value.kms_key_id != ""
      error_message = "kms_key_id must not be empty when encryption_type is set to 'KMS'."
    }
  }

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.encryption_type == "KMS" && each.value.kms_key_id != "" ? each.value.kms_key_id : null
  }

  tags = merge(
    var.common_tags,
    {
      Name = each.value.name
    }
  )
}

# ==================================================
# ライフサイクルポリシー
# ==================================================

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = var.enable_lifecycle_policy ? aws_ecr_repository.main : {}

  repository = each.value.name
  policy     = local.lifecycle_policy
}

# ==================================================
# リポジトリポリシー
# ==================================================

resource "aws_ecr_repository_policy" "main" {
  for_each = var.enable_repository_policy && local.repository_policy != "" ? aws_ecr_repository.main : {}

  repository = each.value.name
  policy     = local.repository_policy
}

# ==================================================
# レプリケーション設定
# ==================================================

resource "aws_ecr_replication_configuration" "main" {
  count = var.enable_replication && length(var.replication_destinations) > 0 ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.enable_replication || length(var.replication_destinations) > 0
      error_message = "replication_destinations must have at least one entry when enable_replication is true."
    }
  }

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_destinations
        content {
          region      = destination.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }

      repository_filter {
        filter      = "*"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

# ==================================================
# プル経由キャッシュルール
# ==================================================

resource "aws_ecr_pull_through_cache_rule" "main" {
  count = var.enable_pull_through_cache && var.upstream_registry_url != "" ? 1 : 0

  ecr_repository_prefix = "${var.project}-${var.env}"
  upstream_registry_url = var.upstream_registry_url
}
