# ==================================================
# ローカル変数
# ==================================================

locals {
  # クラスター名の決定（優先順位: 明示的指定 > 自動生成）
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${var.project}-${var.env}-ecs"

  # Execute Command用ロググループ名の決定
  execute_command_log_group_name = var.execute_command_log_group_name != "" ? var.execute_command_log_group_name : "/aws/ecs/execute-command/${local.cluster_name}"
}

# ==================================================
# Execute Command用CloudWatchロググループ
# ==================================================

resource "aws_cloudwatch_log_group" "execute_command" {
  count = var.enable_execute_command_logging ? 1 : 0

  name              = local.execute_command_log_group_name
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name = local.execute_command_log_group_name
    }
  )
}

# ==================================================
# ECSクラスター
# ==================================================

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  # Container Insights設定
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  # Execute Command設定
  dynamic "configuration" {
    for_each = var.enable_execute_command_logging ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.execute_command_kms_key_id != "" ? var.execute_command_kms_key_id : null

        log_configuration {
          cloud_watch_encryption_enabled = var.execute_command_kms_key_id != "" ? true : false
          cloud_watch_log_group_name     = aws_cloudwatch_log_group.execute_command[0].name
          s3_bucket_name                 = var.execute_command_s3_bucket_name != "" ? var.execute_command_s3_bucket_name : null
          s3_key_prefix                  = var.execute_command_s3_key_prefix
        }

        logging = "OVERRIDE"
      }
    }
  }

  # Service Connect設定
  dynamic "service_connect_defaults" {
    for_each = var.enable_service_connect && var.service_connect_namespace != "" ? [1] : []
    content {
      namespace = var.service_connect_namespace
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = local.cluster_name
    }
  )
}

# ==================================================
# キャパシティプロバイダー
# ==================================================

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
    }
  }
}
