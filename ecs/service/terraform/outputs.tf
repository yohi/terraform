# ==================================================
# ECSタスク定義情報
# ==================================================

output "task_definition_arn" {
  description = "ECSタスク定義ARN"
  value       = aws_ecs_task_definition.main.arn
}

output "task_definition_family" {
  description = "ECSタスク定義ファミリー名"
  value       = aws_ecs_task_definition.main.family
}

output "task_definition_revision" {
  description = "ECSタスク定義リビジョン"
  value       = aws_ecs_task_definition.main.revision
}

# ==================================================
# ECSサービス情報
# ==================================================

output "service_id" {
  description = "ECSサービスID"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.main.name
}

output "service_cluster" {
  description = "ECSサービスのクラスター名"
  value       = aws_ecs_service.main.cluster
}

output "service_desired_count" {
  description = "ECSサービスの希望タスク数"
  value       = aws_ecs_service.main.desired_count
}

# ==================================================
# IAMロール情報
# ==================================================

output "execution_role_arn" {
  description = "タスク実行ロールARN"
  value       = var.execution_role_arn != "" ? var.execution_role_arn : aws_iam_role.execution_role[0].arn
}

output "task_role_arn" {
  description = "タスクロールARN"
  value       = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.task_role[0].arn
}

# ==================================================
# セキュリティグループ情報
# ==================================================

output "security_group_id" {
  description = "ECSサービス用セキュリティグループID"
  value       = aws_security_group.main.id
}

output "security_group_arn" {
  description = "ECSサービス用セキュリティグループARN"
  value       = aws_security_group.main.arn
}

# ==================================================
# CloudWatchログ情報
# ==================================================

output "log_group_name" {
  description = "CloudWatchロググループ名"
  value       = var.enable_logging ? aws_cloudwatch_log_group.main[0].name : null
}

output "log_group_arn" {
  description = "CloudWatchロググループARN"
  value       = var.enable_logging ? aws_cloudwatch_log_group.main[0].arn : null
}

# ==================================================
# Auto Scaling情報
# ==================================================

output "autoscaling_target_resource_id" {
  description = "Auto Scalingターゲットのリソース ID"
  value       = var.enable_auto_scaling ? aws_appautoscaling_target.main[0].resource_id : null
}

output "autoscaling_policy_cpu_arn" {
  description = "CPU Auto ScalingポリシーARN"
  value       = var.enable_auto_scaling ? aws_appautoscaling_policy.cpu[0].arn : null
}

output "autoscaling_policy_memory_arn" {
  description = "メモリ Auto ScalingポリシーARN"
  value       = var.enable_auto_scaling ? aws_appautoscaling_policy.memory[0].arn : null
}

# ==================================================
# 名前情報
# ==================================================

output "container_name" {
  description = "メインコンテナ名"
  value       = local.container_name
}

output "container_port" {
  description = "メインコンテナポート"
  value       = var.container_port
}
