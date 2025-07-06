# 起動テンプレートID
output "launch_template_id" {
  description = "起動テンプレートのID"
  value       = aws_launch_template.main.id
}

# 起動テンプレートARN
output "launch_template_arn" {
  description = "起動テンプレートのARN"
  value       = aws_launch_template.main.arn
}

# 起動テンプレート名
output "launch_template_name" {
  description = "起動テンプレートの名前"
  value       = aws_launch_template.main.name
}

# 最新バージョン
output "launch_template_latest_version" {
  description = "起動テンプレートの最新バージョン"
  value       = aws_launch_template.main.latest_version
}

# 使用されたAMI ID
output "ami_id" {
  description = "使用されたECS最適化AMIのID"
  value       = data.aws_ami.amazon_linux.id
}

# AMI名
output "ami_name" {
  description = "使用されたECS最適化AMIの名前"
  value       = data.aws_ami.amazon_linux.name
}

# セキュリティグループID
output "security_group_id" {
  description = "作成されたセキュリティグループのID"
  value       = aws_security_group.main.id
}

# セキュリティグループ名
output "security_group_name" {
  description = "作成されたセキュリティグループの名前"
  value       = aws_security_group.main.name
}

# Parameter Store Parameter Names
output "parameter_store_names" {
  description = "作成されたParameter Storeパラメータ名のリスト"
  value = compact([
    var.create_parameter_store && local.effective_mackerel_api_key != "" ? aws_ssm_parameter.mackerel_api_key[0].name : "",
    var.create_parameter_store && local.effective_mackerel_display_name != "" ? aws_ssm_parameter.mackerel_display_name[0].name : "",
    var.create_parameter_store && var.mackerel_organization != "" ? aws_ssm_parameter.mackerel_organization[0].name : "",
    var.create_parameter_store && local.effective_mackerel_roles != "" ? aws_ssm_parameter.mackerel_roles[0].name : "",
    var.create_parameter_store && var.mackerel_auto_retirement != "" ? aws_ssm_parameter.mackerel_auto_retirement[0].name : "",
    var.create_parameter_store && local.final_mackerel_config != "" ? aws_ssm_parameter.mackerel_agent_config[0].name : "",
    var.create_parameter_store && local.final_mackerel_sysconfig != "" ? aws_ssm_parameter.mackerel_sysconfig_config[0].name : "",
    var.create_parameter_store && local.final_cloudwatch_config != "" ? aws_ssm_parameter.cloudwatch_agent_config[0].name : ""
  ])
}

output "mackerel_parameter_prefix" {
  description = "使用されるMackerelのParameter Storeプレフィックス"
  value       = var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/mackerel/"
}

output "effective_mackerel_settings" {
  description = "実際に使用されるMackerel設定"
  value = {
    api_key      = local.effective_mackerel_api_key != "" ? "***設定済み***" : "未設定"
    display_name = local.effective_mackerel_display_name
    roles        = local.effective_mackerel_roles
    has_config   = local.final_mackerel_config != "" ? true : false
    has_sysconfig = local.final_mackerel_sysconfig != "" ? true : false
  }
}

output "effective_cloudwatch_settings" {
  description = "実際に使用されるCloudWatch Agent設定"
  value = {
    namespace               = local.effective_cloudwatch_namespace
    collection_interval     = var.cloudwatch_metrics_collection_interval
    has_config             = local.final_cloudwatch_config != "" ? true : false
    parameter_name         = var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : "AmazonCloudWatch-Agent_${var.project_name}-ecs"
  }
}
