# ==================================================
# EventBridge ルール情報
# ==================================================

output "eventbridge_rule_name" {
  description = "EventBridge ルール名"
  value       = var.enable_monitoring ? try(aws_cloudwatch_event_rule.ecs_instance_state_change[0].name, null) : null
}

output "eventbridge_rule_arn" {
  description = "EventBridge ルール ARN"
  value       = var.enable_monitoring ? try(aws_cloudwatch_event_rule.ecs_instance_state_change[0].arn, null) : null
}

# ==================================================
# CloudWatch ログ情報
# ==================================================

output "log_group_name" {
  description = "CloudWatch ログ グループ名"
  value       = var.enable_monitoring ? try(aws_cloudwatch_log_group.ecs_agent_monitor[0].name, null) : null
}

output "log_group_arn" {
  description = "CloudWatch ログ グループ ARN"
  value       = var.enable_monitoring ? try(aws_cloudwatch_log_group.ecs_agent_monitor[0].arn, null) : null
}

# ==================================================
# Lambda 関数情報
# ==================================================

output "lambda_function_name" {
  description = "Lambda 関数名"
  value       = var.enable_monitoring ? try(aws_lambda_function.ecs_agent_monitor[0].function_name, null) : null
}

output "lambda_function_arn" {
  description = "Lambda 関数 ARN"
  value       = var.enable_monitoring ? try(aws_lambda_function.ecs_agent_monitor[0].arn, null) : null
}

output "lambda_role_name" {
  description = "Lambda 実行 IAM ロール名"
  value       = var.enable_monitoring ? try(aws_iam_role.lambda_role[0].name, null) : null
}

output "lambda_role_arn" {
  description = "Lambda 実行 IAM ロール ARN"
  value       = var.enable_monitoring ? try(aws_iam_role.lambda_role[0].arn, null) : null
}

# ==================================================
# サブスクリプション フィルター情報
# ==================================================

output "subscription_filter_name" {
  description = "CloudWatch ログ サブスクリプション フィルター名"
  value       = var.enable_monitoring ? try(aws_cloudwatch_log_subscription_filter.ecs_agent_monitor[0].name, null) : null
}

output "subscription_filter_arn" {
  description = "CloudWatch ログ サブスクリプション フィルター ARN"
  value       = var.enable_monitoring ? try(aws_cloudwatch_log_subscription_filter.ecs_agent_monitor[0].arn, null) : null
}

# ==================================================
# 設定情報
# ==================================================

output "cluster_arn" {
  description = "監視対象のECSクラスターARN"
  value       = var.cluster_arn
}

output "monitoring_enabled" {
  description = "ECSエージェント監視が有効かどうか"
  value       = var.enable_monitoring
}

output "slack_token_configured" {
  description = "Slack Bot Token Secret ARNが設定されているかどうか"
  value       = var.slack_token_secret_arn != ""
  sensitive   = false
}
