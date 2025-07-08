# ==================================================
# オートスケーリンググループ情報
# ==================================================

output "autoscaling_group_id" {
  description = "オートスケーリンググループのID"
  value       = aws_autoscaling_group.main.id
}

output "autoscaling_group_arn" {
  description = "オートスケーリンググループのARN"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "オートスケーリンググループの名前"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_availability_zones" {
  description = "オートスケーリンググループが使用するアベイラビリティーゾーン"
  value       = aws_autoscaling_group.main.availability_zones
}

output "autoscaling_group_vpc_zone_identifier" {
  description = "オートスケーリンググループが使用するサブネットID"
  value       = aws_autoscaling_group.main.vpc_zone_identifier
}

output "autoscaling_group_min_size" {
  description = "オートスケーリンググループの最小サイズ"
  value       = aws_autoscaling_group.main.min_size
}

output "autoscaling_group_max_size" {
  description = "オートスケーリンググループの最大サイズ"
  value       = aws_autoscaling_group.main.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "オートスケーリンググループの希望容量"
  value       = aws_autoscaling_group.main.desired_capacity
}

output "autoscaling_group_default_cooldown" {
  description = "オートスケーリンググループのデフォルトクールダウン"
  value       = aws_autoscaling_group.main.default_cooldown
}

output "autoscaling_group_health_check_type" {
  description = "オートスケーリンググループのヘルスチェックタイプ"
  value       = aws_autoscaling_group.main.health_check_type
}

output "autoscaling_group_health_check_grace_period" {
  description = "オートスケーリンググループのヘルスチェック猶予期間"
  value       = aws_autoscaling_group.main.health_check_grace_period
}

# ==================================================
# 起動テンプレート情報
# ==================================================

output "launch_template_id" {
  description = "使用している起動テンプレートのID"
  value       = var.launch_template_id
}

output "launch_template_version" {
  description = "使用している起動テンプレートのバージョン"
  value       = var.launch_template_version
}

# ==================================================
# スケーリングポリシー情報
# ==================================================

output "scale_up_policy_arn" {
  description = "スケールアップポリシーのARN"
  value       = var.enable_scale_up_policy ? aws_autoscaling_policy.scale_up[0].arn : null
}

output "scale_up_policy_name" {
  description = "スケールアップポリシーの名前"
  value       = var.enable_scale_up_policy ? aws_autoscaling_policy.scale_up[0].name : null
}

output "scale_down_policy_arn" {
  description = "スケールダウンポリシーのARN"
  value       = var.enable_scale_down_policy ? aws_autoscaling_policy.scale_down[0].arn : null
}

output "scale_down_policy_name" {
  description = "スケールダウンポリシーの名前"
  value       = var.enable_scale_down_policy ? aws_autoscaling_policy.scale_down[0].name : null
}

# ==================================================
# CloudWatch Alarm情報
# ==================================================

output "cpu_high_alarm_arn" {
  description = "CPU使用率高アラームのARN"
  value       = var.enable_cpu_high_alarm ? aws_cloudwatch_metric_alarm.cpu_high[0].arn : null
}

output "cpu_high_alarm_name" {
  description = "CPU使用率高アラームの名前"
  value       = var.enable_cpu_high_alarm ? aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name : null
}

output "cpu_low_alarm_arn" {
  description = "CPU使用率低アラームのARN"
  value       = var.enable_cpu_low_alarm ? aws_cloudwatch_metric_alarm.cpu_low[0].arn : null
}

output "cpu_low_alarm_name" {
  description = "CPU使用率低アラームの名前"
  value       = var.enable_cpu_low_alarm ? aws_cloudwatch_metric_alarm.cpu_low[0].alarm_name : null
}

output "scale_up_alarm_arn" {
  description = "スケールアップアラームのARN"
  value       = var.enable_scale_up_policy && var.enable_scale_up_alarm ? aws_cloudwatch_metric_alarm.scale_up_alarm[0].arn : null
}

output "scale_up_alarm_name" {
  description = "スケールアップアラームの名前"
  value       = var.enable_scale_up_policy && var.enable_scale_up_alarm ? aws_cloudwatch_metric_alarm.scale_up_alarm[0].alarm_name : null
}

output "scale_down_alarm_arn" {
  description = "スケールダウンアラームのARN"
  value       = var.enable_scale_down_policy && var.enable_scale_down_alarm ? aws_cloudwatch_metric_alarm.scale_down_alarm[0].arn : null
}

output "scale_down_alarm_name" {
  description = "スケールダウンアラームの名前"
  value       = var.enable_scale_down_policy && var.enable_scale_down_alarm ? aws_cloudwatch_metric_alarm.scale_down_alarm[0].alarm_name : null
}

# ==================================================
# SNS通知情報
# ==================================================

output "sns_topic_arn" {
  description = "SNS通知トピックのARN"
  value       = var.enable_notifications ? aws_sns_topic.asg_notifications[0].arn : null
}

output "sns_topic_name" {
  description = "SNS通知トピックの名前"
  value       = var.enable_notifications ? aws_sns_topic.asg_notifications[0].name : null
}

output "sns_subscription_arns" {
  description = "SNS通知サブスクリプションのARNリスト"
  value       = var.enable_notifications && length(local.notification_endpoints) > 0 ? aws_sns_topic_subscription.email_notifications[*].arn : []
}

# ==================================================
# 設定情報サマリー
# ==================================================

output "scaling_configuration" {
  description = "スケーリング設定のサマリー"
  value = {
    min_size                  = aws_autoscaling_group.main.min_size
    max_size                  = aws_autoscaling_group.main.max_size
    desired_capacity          = var.desired_capacity
    health_check_type         = var.health_check_type
    health_check_grace_period = var.health_check_grace_period
    default_cooldown          = var.default_cooldown
  }
}

output "scaling_policies_enabled" {
  description = "有効なスケーリングポリシー"
  value = {
    scale_up_enabled   = var.enable_scale_up_policy
    scale_down_enabled = var.enable_scale_down_policy
    scale_up_type      = var.enable_scale_up_policy ? var.scale_up_policy_type : null
    scale_down_type    = var.enable_scale_down_policy ? var.scale_down_policy_type : null
  }
}

output "alarms_enabled" {
  description = "有効なアラーム"
  value = {
    cpu_high_alarm   = var.enable_cpu_high_alarm
    cpu_low_alarm    = var.enable_cpu_low_alarm
    scale_up_alarm   = var.enable_scale_up_policy && var.enable_scale_up_alarm
    scale_down_alarm = var.enable_scale_down_policy && var.enable_scale_down_alarm
  }
}

output "notification_configuration" {
  description = "通知設定"
  value = {
    notifications_enabled = var.enable_notifications
    email_addresses       = var.enable_notifications ? var.notification_email_addresses : []
    notification_types    = var.enable_notifications ? var.notification_types : []
  }
}

# ==================================================
# タグ情報
# ==================================================

output "effective_tags" {
  description = "最終的に適用されたタグ"
  value = {
    common_tags     = local.final_common_tags
    additional_tags = var.additional_tags
    total_tag_count = length(local.final_common_tags) + length(var.additional_tags)
  }
}

output "asg_name_format" {
  description = "使用されているASG名の形式"
  value = {
    asg_name       = local.asg_name
    name_prefix    = local.name_prefix
    naming_pattern = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-asg" : "${var.project_name}-${var.environment}-asg"
  }
}

# ==================================================
# 運用・監視用の統合情報
# ==================================================

output "operational_summary" {
  description = "運用・監視に必要な情報のサマリー"
  value = {
    # 基本情報
    asg_name = aws_autoscaling_group.main.name
    asg_arn  = aws_autoscaling_group.main.arn
    capacity_info = {
      min_size         = aws_autoscaling_group.main.min_size
      max_size         = aws_autoscaling_group.main.max_size
      desired_capacity = aws_autoscaling_group.main.desired_capacity
    }

    # 監視情報
    monitoring = {
      health_check_type         = aws_autoscaling_group.main.health_check_type
      health_check_grace_period = aws_autoscaling_group.main.health_check_grace_period
      cpu_high_alarm_enabled    = var.enable_cpu_high_alarm
      cpu_low_alarm_enabled     = var.enable_cpu_low_alarm
      notifications_enabled     = var.enable_notifications
    }

    # ネットワーク情報
    network = {
      availability_zones  = aws_autoscaling_group.main.availability_zones
      vpc_zone_identifier = aws_autoscaling_group.main.vpc_zone_identifier
      subnet_count        = length(aws_autoscaling_group.main.vpc_zone_identifier)
    }

    # 起動テンプレート情報
    launch_template = {
      id      = var.launch_template_id
      version = var.launch_template_version
    }
  }
}

output "aws_cli_commands" {
  description = "AWS CLIを使用した管理コマンドの例"
  value = {
    describe_asg       = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${aws_autoscaling_group.main.name}"
    scaling_activities = "aws autoscaling describe-scaling-activities --auto-scaling-group-name ${aws_autoscaling_group.main.name}"
    manual_scale_up    = "aws autoscaling set-desired-capacity --auto-scaling-group-name ${aws_autoscaling_group.main.name} --desired-capacity $((${var.desired_capacity} + 1))"
    manual_scale_down  = "aws autoscaling set-desired-capacity --auto-scaling-group-name ${aws_autoscaling_group.main.name} --desired-capacity $((${var.desired_capacity} - 1))"
    suspend_scaling    = "aws autoscaling suspend-processes --auto-scaling-group-name ${aws_autoscaling_group.main.name}"
    resume_scaling     = "aws autoscaling resume-processes --auto-scaling-group-name ${aws_autoscaling_group.main.name}"
  }
}

output "terraform_commands" {
  description = "Terraform管理コマンドの例"
  value = {
    refresh_state   = "terraform refresh"
    show_state      = "terraform show"
    import_existing = "terraform import aws_autoscaling_group.main ${aws_autoscaling_group.main.name}"
    targeted_apply  = "terraform apply -target=aws_autoscaling_group.main"
  }
}

output "troubleshooting_info" {
  description = "トラブルシューティング用の情報"
  value = {
    # CloudWatch ログ関連
    cloudwatch_log_groups = [
      "/aws/ec2/autoscaling",
      "/aws/events/autoscaling",
    ]

    # 設定検証
    configuration_check = {
      min_size_valid            = var.min_size <= var.desired_capacity
      subnet_count_adequate     = length(local.subnet_ids) >= 1
      notification_config_valid = !var.enable_notifications || length(var.notification_email_addresses) > 0
    }

    # アラーム状態確認コマンド
    alarm_commands = var.enable_cpu_high_alarm || var.enable_cpu_low_alarm ? {
      list_alarms   = "aws cloudwatch describe-alarms --alarm-name-prefix ${local.name_prefix}-asg"
      alarm_history = "aws cloudwatch describe-alarm-history --alarm-name ${local.name_prefix}-asg-cpu-high"
    } : {}
  }
}

output "cost_optimization_tips" {
  description = "コスト最適化のためのヒント"
  value = {
    current_config = {
      environment      = var.environment
      min_size         = var.min_size
      desired_capacity = var.desired_capacity
      max_size         = var.desired_capacity * 2
    }

    suggestions = var.environment == "prd" ? [
      "本番環境: スケジュールベースのスケーリングを検討してください",
      "本番環境: Spot インスタンスの混在使用を検討してください",
      "本番環境: 詳細監視でコストと性能のバランスを取ってください"
      ] : var.environment == "dev" ? [
      "開発環境: min_size を 0 に設定して夜間停止を検討してください",
      "開発環境: business-hours スケジュールの適用を検討してください",
      "開発環境: 基本監視で十分な場合があります"
      ] : [
      "ステージング環境: 本番環境より小さな構成を検討してください",
      "ステージング環境: スケジュールベースの運用を検討してください"
    ]
  }
}
