# AWS Account Information (for validation before applying changes)
output "aws_account_id" {
  description = "Current AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_account_name" {
  description = "Current AWS Account Name"
  value       = "Use 'aws organizations describe-account --account-id ${data.aws_caller_identity.current.account_id}' to get account name"
}

output "aws_user_id" {
  description = "Current AWS User/Role ID"
  value       = data.aws_caller_identity.current.user_id
}

output "aws_arn" {
  description = "Current AWS User/Role ARN"
  value       = data.aws_caller_identity.current.arn
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "environment" {
  description = "Environment name"
  value       = var.env
}

output "project_env" {
  description = "Combined project and environment name"
  value       = local.project_env
}

output "athena_database_name" {
  description = "Name of the Athena database"
  value       = aws_athena_database.logs.name
}

output "athena_table_names" {
  description = "Map of log types to Athena table names"
  value = {
    for k, v in var.log_types : k => "${local.project_env}_${v.table_name_suffix}"
  }
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "athena_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.bucket
}

output "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.arn
}

output "athena_role_arn" {
  description = "ARN of the IAM role for Athena"
  value       = aws_iam_role.athena_role.arn
}

output "logs_s3_locations" {
  description = "Map of log types to S3 locations"
  value = {
    for k, v in var.log_types : k => "s3://${local.logs_bucket_name}/${var.logs_s3_prefix}/${k}/"
  }
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket where logs are stored"
  value       = local.logs_bucket_name
}

output "athena_console_url" {
  description = "URL to access Athena console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/athena/home?region=${var.aws_region}#/query-editor"
}

output "created_named_queries" {
  description = "List of created Athena named queries"
  value = merge(
    {
      for k, v in aws_athena_named_query.create_table :
      "create_table_${k}" => v.name
    },
    {
      for k, v in aws_athena_named_query.add_partitions :
      "add_partitions_${k}" => v.name
    },
    {
      for k, v in aws_athena_named_query.sample_queries :
      "sample_queries_${k}" => v.name
    },
    {
      "all_tables_overview" = aws_athena_named_query.all_tables_overview.name
    }
  )
}
