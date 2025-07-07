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
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "app" {
  description = "Application name (catalog name)"
  value       = var.app
}

output "project_env" {
  description = "Combined project and environment name"
  value       = local.project_env
}

output "athena_database_name" {
  description = "Name of the Athena database"
  value       = local.athena_database_name
}

output "athena_table_names" {
  description = "Map of log types to Athena table names"
  value = {
    for k, v in var.log_types : k => "${local.project_env}-${v.table_name_suffix}"
  }
}

output "athena_data_source_name" {
  description = "Name of the Athena data source (default: AwsDataCatalog)"
  value       = "AwsDataCatalog"
}

output "athena_catalog_name" {
  description = "Name of the Athena catalog"
  value       = var.app
}

output "s3_prefix_database_name" {
  description = "Database name derived from S3 prefix"
  value       = local.default_database_name
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for logs and Athena query results"
  value       = local.logs_bucket
}

output "athena_query_results_location" {
  description = "S3 location where Athena query results are stored"
  value       = "s3://${local.logs_bucket}/athena-query-results/"
}

output "athena_role_arn" {
  description = "ARN of the IAM role for Athena"
  value       = aws_iam_role.athena_role.arn
}

output "logs_s3_locations" {
  description = "Map of log types to S3 locations"
  value = {
    for k, v in var.log_types : k => "s3://${local.logs_bucket}/${var.logs_s3_prefix}/${k}/"
  }
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
    # add_partitions は「保存したクエリ」に不要のため無効化
    # {
    #   for k, v in aws_athena_named_query.add_partitions :
    #   "add_partitions_${k}" => v.name
    # },
    {
      for k, v in aws_athena_named_query.sample_queries :
      "sample_queries_${k}" => v.name
    },
    {
      "all_tables_overview" = aws_athena_named_query.all_tables_overview.name
    },
    {
      "current_day_all_data" = aws_athena_named_query.current_day_all_data.name
    }
  )
}

# Outputs for Athena Analytics Infrastructure
# index.htmlの手順に準拠した構成の出力情報

# AWS Glue Database情報（手順1）
output "glue_database_name" {
  description = "AWS Glue Catalog Database name"
  value       = aws_glue_catalog_database.main.name
}

output "glue_database_arn" {
  description = "AWS Glue Catalog Database ARN"
  value       = "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.main.name}"
}

# S3バケット情報（手順2）
output "s3_bucket_name" {
  description = "S3 bucket name for data storage"
  value       = local.logs_bucket
}

output "s3_data_locations" {
  description = "S3 locations for each log type (CSV file folders)"
  value = {
    for log_type, config in var.log_types :
    log_type => "s3://${local.logs_bucket}/${var.logs_s3_prefix}/${log_type}/"
  }
}

output "s3_athena_results_location" {
  description = "S3 location for Athena query results"
  value       = "s3://${local.logs_bucket}/athena-query-results/"
}

# AWS Glue Crawler情報（手順3）
output "glue_crawler_names" {
  description = "AWS Glue Crawler names for each log type"
  value = {
    for log_type, crawler in aws_glue_crawler.log_crawlers :
    log_type => crawler.name
  }
}

output "glue_crawler_role_arn" {
  description = "IAM role ARN for Glue Crawlers"
  value       = aws_iam_role.glue_crawler_role.arn
}

# Athena設定情報（手順4）

output "athena_named_queries" {
  description = "Athena named queries for table creation, partitions, and views"
  value = {
    create_table = {
      for log_type, query in aws_athena_named_query.create_table :
      log_type => {
        name = query.name
        id   = query.id
      }
    }
    # add_partitions は「保存したクエリ」に不要のため無効化
    # add_partitions = {
    #   for log_type, query in aws_athena_named_query.add_partitions :
    #   log_type => {
    #     name = query.name
    #     id   = query.id
    #   }
    # }
    create_views = {
      for log_type, query in aws_athena_named_query.create_views :
      log_type => {
        name = query.name
        id   = query.id
      }
    }
    sample_queries = {
      for log_type, query in aws_athena_named_query.sample_queries :
      log_type => {
        name = query.name
        id   = query.id
      }
    }
    all_tables_overview = {
      name = aws_athena_named_query.all_tables_overview.name
      id   = aws_athena_named_query.all_tables_overview.id
    }
    current_day_all_data = {
      name = aws_athena_named_query.current_day_all_data.name
      id   = aws_athena_named_query.current_day_all_data.id
    }
  }
}

# QuickSight設定情報（手順5）
output "quicksight_role_arn" {
  description = "IAM role ARN for QuickSight integration (if enabled)"
  value       = var.enable_quicksight ? aws_iam_role.quicksight_role[0].arn : null
}

# 実行手順ガイド
output "execution_guide" {
  description = "Step-by-step execution guide based on index.html procedures"
  value = {
    step_1_glue_database       = "✅ AWS Glue Database '${aws_glue_catalog_database.main.name}' has been created"
    step_2_s3_setup            = "✅ S3 bucket '${local.logs_bucket}' is configured for data storage"
    step_3_crawler_setup       = "⚠️  Run Glue Crawlers manually or via automation: ${join(", ", [for crawler in values(aws_glue_crawler.log_crawlers) : crawler.name])}"
    step_4a_table_verification = "⚠️  After running crawlers, verify tables in Athena using named queries"
    step_4b_view_creation      = "⚠️  Create views using the provided named queries for better data analysis"
    step_5_quicksight          = var.enable_quicksight ? "✅ QuickSight IAM role created - configure QuickSight permissions manually" : "❌ QuickSight integration disabled - set enable_quicksight=true to enable"
  }
}

# 接続情報
output "connection_info" {
  description = "Connection information for accessing the analytics environment"
  value = {
    aws_region       = data.aws_region.current.name
    aws_account_id   = data.aws_caller_identity.current.account_id
    athena_workgroup = aws_athena_workgroup.main.name
    athena_database  = local.athena_database_name
    s3_bucket        = local.logs_bucket
    glue_database    = aws_glue_catalog_database.main.name
  }
}

# セキュリティ情報
output "security_info" {
  description = "Security and access control information"
  value = {
    athena_role_arn            = aws_iam_role.athena_role.arn
    glue_crawler_role_arn      = aws_iam_role.glue_crawler_role.arn
    quicksight_role_arn        = var.enable_quicksight ? aws_iam_role.quicksight_role[0].arn : null
    data_classification        = var.data_classification
    workgroup_enforce_settings = true
  }
}

# ==================================================
# 環境分離強化のためのIAMリソース出力
# ==================================================

output "workgroup_user_role_arn" {
  description = "IAM role ARN for workgroup users (environment-isolated access)"
  value       = aws_iam_role.athena_workgroup_user_role.arn
}

output "workgroup_user_role_name" {
  description = "IAM role name for workgroup users"
  value       = aws_iam_role.athena_workgroup_user_role.name
}

output "athena_admin_policy_arn" {
  description = "IAM policy ARN for Athena administrators"
  value       = aws_iam_policy.athena_admin_policy.arn
}

output "athena_admin_policy_name" {
  description = "IAM policy name for Athena administrators"
  value       = aws_iam_policy.athena_admin_policy.name
}

output "environment_isolation_info" {
  description = "Environment isolation configuration details"
  value = {
    workgroup_name      = aws_athena_workgroup.main.name
    database_name       = local.athena_database_name
    allowed_environment = var.environment
    allowed_project     = var.project_name
    allowed_app         = var.app
    access_restrictions = {
      only_assigned_workgroup = true
      only_assigned_database  = true
      deny_cross_environment  = true
    }
  }
}

output "usage_instructions" {
  description = "Usage instructions for environment-isolated Athena access"
  value = {
    for_users            = "Users should assume the role: ${aws_iam_role.athena_workgroup_user_role.arn} to access workgroup: ${aws_athena_workgroup.main.name}"
    for_admins           = "Administrators should attach the policy: ${aws_iam_policy.athena_admin_policy.name} for full access to workgroup: ${aws_athena_workgroup.main.name}"
    workgroup_url        = "https://${var.aws_region}.console.aws.amazon.com/athena/home?region=${var.aws_region}#/workgroups/details/${aws_athena_workgroup.main.name}"
    database_restriction = "Access is restricted to database: ${local.athena_database_name} only"
  }
}
