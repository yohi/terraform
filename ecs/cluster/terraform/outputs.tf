# ==================================================
# ECSクラスター情報
# ==================================================

output "cluster_id" {
  description = "ECSクラスターID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECSクラスターARN"
  value       = aws_ecs_cluster.main.arn
}

# ==================================================
# キャパシティプロバイダー情報
# ==================================================

output "capacity_providers" {
  description = "設定されたキャパシティプロバイダー"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

output "default_capacity_provider_strategy" {
  description = "デフォルトキャパシティプロバイダー戦略"
  value       = aws_ecs_cluster_capacity_providers.main.default_capacity_provider_strategy
}

# ==================================================
# CloudWatchログ情報
# ==================================================

output "execute_command_log_group_name" {
  description = "Execute Command用CloudWatchロググループ名"
  value       = var.enable_execute_command_logging ? aws_cloudwatch_log_group.execute_command[0].name : null
}

output "execute_command_log_group_arn" {
  description = "Execute Command用CloudWatchロググループARN"
  value       = var.enable_execute_command_logging ? aws_cloudwatch_log_group.execute_command[0].arn : null
}

# ==================================================
# 設定情報
# ==================================================

output "container_insights_enabled" {
  description = "Container Insightsが有効かどうか"
  value       = var.enable_container_insights
}

output "execute_command_logging_enabled" {
  description = "Execute Commandログ記録が有効かどうか"
  value       = var.enable_execute_command_logging
}

output "service_connect_enabled" {
  description = "Service Connectが有効かどうか"
  value       = var.enable_service_connect
}
