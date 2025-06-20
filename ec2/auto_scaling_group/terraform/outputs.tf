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
  description = "実際に適用されるタグ"
  value = merge(
    var.common_tags,
    {
      Name = local.name_prefix
    }
  )
}

output "asg_name_format" {
  description = "Auto Scaling Groupの名前形式"
  value       = local.asg_name
}
