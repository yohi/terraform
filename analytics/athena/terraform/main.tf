# Terraform configuration for Athena Analytics
# Terraform and provider configuration moved to versions.tf

# Get current AWS account information for validation
data "aws_caller_identity" "current" {}

# AWS Region data
data "aws_region" "current" {}

# ==================================================
# Terraform-native validation (replaces bash scripts)
# ==================================================

# AWS Account validation using native Terraform
locals {
  # Account validation check
  current_account_id         = data.aws_caller_identity.current.account_id
  account_validation_enabled = var.expected_aws_account_id != ""

  # Account validation with custom error message
  account_validation_check = var.expected_aws_account_id == "" ? true : (
    local.current_account_id == var.expected_aws_account_id
  )

  # Custom validation error message
  _ = local.account_validation_enabled && !local.account_validation_check ? tobool("AWS Account validation failed. Expected: ${var.expected_aws_account_id}, Current: ${local.current_account_id}. Please verify you are using the correct AWS account.") : true
}

# S3 bucket existence check using native Terraform
data "aws_s3_bucket" "logs_bucket_check" {
  count  = var.skip_bucket_validation ? 0 : 1
  bucket = var.logs_bucket_name

  # This will fail if bucket doesn't exist, which is intentional for validation
}

# S3 bucket logic consolidated into main locals block below

# 既存のログバケットを参照（存在する場合）
data "aws_s3_bucket" "existing_logs" {
  count  = local.bucket_exists ? 1 : 0
  bucket = var.logs_bucket_name
}

# S3バケットの作成（存在しない場合、auto_create_bucketがtrueの場合）
resource "aws_s3_bucket" "logs_bucket" {
  count  = local.should_create_bucket ? 1 : 0
  bucket = var.logs_bucket_name

  tags = merge(local.common_tags, {
    Name      = var.logs_bucket_name
    Purpose   = "Data storage for Athena analysis"
    Component = "storage"
  })
}

# S3バケットのライフサイクル設定
resource "aws_s3_bucket_lifecycle_configuration" "logs_bucket_lifecycle" {
  count  = local.should_create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket[0].id

  rule {
    id     = "athena_query_results"
    status = "Enabled"

    filter {
      prefix = "athena-results/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "log_data_lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # 7 years for compliance
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "default_lifecycle"
    status = "Enabled"

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 730 # 2 years default retention
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

# S3バケットの暗号化設定
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_bucket_encryption" {
  count  = local.should_create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3バケットのバージョニング設定
resource "aws_s3_bucket_versioning" "logs_bucket_versioning" {
  count  = local.should_create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットのパブリックアクセスブロック設定
resource "aws_s3_bucket_public_access_block" "logs_bucket_pab" {
  count  = local.should_create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Local values for consistent naming and tagging
locals {
  project_env = "${var.project}-${var.env}"
  # プロジェクト、環境、アプリケーション名を組み合わせたデータベース名を使用
  # 例: rcs_prd_web_logs のように環境と案件が明確になる命名規則
  default_database_name = "${var.project}_${var.env}_${var.app}_logs"
  athena_database_name  = var.athena_database_name != "" ? var.athena_database_name : local.default_database_name

  # ==================================================
  # S3 bucket validation logic (replaces external bash scripts)
  # ==================================================
  # Determine if bucket exists (using try to handle case where data source is not created)
  bucket_exists = !var.skip_bucket_validation && length(data.aws_s3_bucket.logs_bucket_check) > 0

  # Determine if we should create a new bucket
  should_create_bucket = !local.bucket_exists && var.auto_create_bucket && !var.skip_bucket_validation

  # Validation: If require_bucket_exists is true, bucket must exist
  bucket_requirement_check = var.require_bucket_exists ? local.bucket_exists : true

  # Validation error if bucket is required but doesn't exist
  _bucket_validation = var.require_bucket_exists && !local.bucket_exists && !var.skip_bucket_validation ? tobool("S3 bucket '${var.logs_bucket_name}' is required but does not exist. Please create it first or set require_bucket_exists=false.") : true

  # ログ用バケットとAthena結果用バケットを同じにする
  logs_bucket = local.bucket_exists ? data.aws_s3_bucket.existing_logs[0].bucket : var.logs_bucket_name
  # 実際に使用するAthenaデータベース名（既存または新規作成）
  actual_athena_database_name = local.athena_database_name

  # ==================================================
  # テーブル名生成ロジック
  # ==================================================
  # Glue Crawlerによって作成されるテーブル名: ${project_env}-${table_name_suffix}
  # 例: rcs-prd-django_web, rcs-prd-nginx_web, rcs-prd-error
  #
  # 注意: table_prefix = "${local.project_env}-" が設定されており、
  # S3パス構造（/django_web/, /nginx_web/, /error/）から table_name_suffix が決定される
  # ==================================================

  # ==================================================
  # タグ戦略の実装
  # ==================================================

  # 基本タグ（すべてのリソースに適用）
  base_tags = {
    "ManagedBy"   = "terraform"
    "Project"     = var.project
    "Environment" = var.env
    "Application" = var.app
    "AccountId"   = data.aws_caller_identity.current.account_id
    "Region"      = data.aws_region.current.name
  }

  # 運用管理タグ
  operational_tags = {
    "Owner"      = var.owner_team
    "CostCenter" = var.cost_center
    "Schedule"   = var.schedule
  }

  # セキュリティ・コンプライアンス タグ
  security_tags = {
    "DataClassification" = var.data_classification
    "Encryption"         = "required"
  }

  # 環境固有タグ
  env_tags = {
    "CriticalityLevel" = var.env == "prod" ? "high" : "medium"
  }

  # サービス固有タグ
  service_tags = {
    "Service"   = "analytics"
    "Component" = "athena"
  }

  # 最終的な共通タグ（優先度: 追加タグ > 環境固有 > セキュリティ > 運用 > サービス > 基本）
  common_tags = merge(
    local.base_tags,
    local.service_tags,
    local.operational_tags,
    local.security_tags,
    local.env_tags,
    var.tags
  )

  # Account information for reference
  account_info = {
    account_id = data.aws_caller_identity.current.account_id
    user_id    = data.aws_caller_identity.current.user_id
    arn        = data.aws_caller_identity.current.arn
    region     = data.aws_region.current.name
  }

  # Sample query file mappings for each log type
  sample_query_files = {
    django_web = "django_web/django_recent_logs.sql"
    nginx_web  = "nginx_web/nginx_recent_logs.sql"
    error      = "error_analysis/critical_errors.sql"
  }
}

# Athenaデータベース存在確認（locals定義後に実行）
# データベースチェックは不要（Glue Catalog DatabaseがAthenaからもアクセス可能）
# data "external" "athena_database_check" {
#   program    = ["bash", "${path.module}/check_athena_database.sh", local.athena_database_name]
#   depends_on = [data.aws_caller_identity.current]
# }

# AWS Glue Database（index.html手順1に準拠）
resource "aws_glue_catalog_database" "main" {
  name        = local.athena_database_name
  description = "Database for ${var.project} ${var.env} analytics data"

  catalog_id = data.aws_caller_identity.current.account_id

  tags = local.common_tags
}

# IAM role for Glue Crawler（index.html手順3に準拠）
resource "aws_iam_role" "glue_crawler_role" {
  name = "${local.project_env}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Glue Crawler
resource "aws_iam_role_policy_attachment" "glue_crawler_service_role" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# IAM policy for Glue Crawler S3 access
resource "aws_iam_role_policy" "glue_crawler_s3_policy" {
  name = "${local.project_env}-glue-crawler-s3-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.logs_bucket}",
          "arn:aws:s3:::${local.logs_bucket}/*"
        ]
      }
    ]
  })
}

# AWS Glue Crawlers（各ログタイプ用、index.html手順3に準拠）
resource "aws_glue_crawler" "log_crawlers" {
  for_each = var.log_types

  database_name = aws_glue_catalog_database.main.name
  name          = "${local.project_env}-${each.key}-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  # スケジュール設定（有効時のみ）
  schedule = var.enable_crawler_schedule ? var.crawler_schedule_expression : null

  s3_target {
    path = "s3://${local.logs_bucket}/${var.logs_s3_prefix}/${each.key}/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables = {
        TableThreshold = 1
      }
    }
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  table_prefix = "${local.project_env}-"

  # 同時実行数制限設定
  lineage_configuration {
    crawler_lineage_settings = "DISABLE"
  }

  lake_formation_configuration {
    use_lake_formation_credentials = false
  }

  tags = merge(local.common_tags, {
    LogType         = each.key
    Purpose         = "Schema discovery"
    ScheduleEnabled = var.enable_crawler_schedule ? "yes" : "no"
  })
}

# Note: AWS Athena uses AwsDataCatalog by default
# Custom data source naming is managed through database and resource naming conventions

# Athena workgroup with enhanced configuration
resource "aws_athena_workgroup" "main" {
  name = "${local.project_env}-analytics"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${local.logs_bucket}/athena-query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = local.common_tags
}

# Athena database（Glue Catalog Databaseを使用するため不要）
# AWS AthenaはGlue Data Catalogを自動的に使用するため、別途aws_athena_databaseリソースは不要
# resource "aws_athena_database" "logs" {
#   count  = jsondecode(data.external.athena_database_check.result.exists) ? 0 : 1
#   name   = local.athena_database_name
#   bucket = local.logs_bucket
#
#   encryption_configuration {
#     encryption_option = "SSE_S3"
#   }
#
#   depends_on = [aws_athena_workgroup.main, aws_glue_catalog_database.main]
# }

# IAM role for Athena with least privilege principle
resource "aws_iam_role" "athena_role" {
  name = "${local.project_env}-athena-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Athena to access S3 with least privilege
resource "aws_iam_role_policy" "athena_s3_policy" {
  name = "${local.project_env}-athena-s3-policy"
  role = aws_iam_role.athena_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::${local.logs_bucket}",
          "arn:aws:s3:::${local.logs_bucket}/*"
        ]
      },
      {
        Sid    = "S3QueryResultsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.logs_bucket}",
          "arn:aws:s3:::${local.logs_bucket}/*"
        ]
      },
      {
        Sid    = "GlueDataCatalogAccess"
        Effect = "Allow"
        Action = [
          "glue:CreateDatabase",
          "glue:DeleteDatabase",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:UpdateDatabase",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:BatchDeleteTable",
          "glue:UpdateTable",
          "glue:GetTable",
          "glue:GetTables",
          "glue:BatchCreatePartition",
          "glue:CreatePartition",
          "glue:DeletePartition",
          "glue:BatchDeletePartition",
          "glue:UpdatePartition",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.athena_database_name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.athena_database_name}/*"
        ]
      }
    ]
  })
}

# QuickSight用IAMロール（index.html手順5に準拠）
resource "aws_iam_role" "quicksight_role" {
  count = var.enable_quicksight ? 1 : 0
  name  = "${local.project_env}-quicksight-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# QuickSight用IAMポリシー
resource "aws_iam_role_policy" "quicksight_policy" {
  count = var.enable_quicksight ? 1 : 0
  name  = "${local.project_env}-quicksight-policy"
  role  = aws_iam_role.quicksight_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:BatchGetQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListQueryExecutions",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = [
          aws_athena_workgroup.main.arn,
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/${aws_athena_workgroup.main.name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.athena_database_name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.athena_database_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::${local.logs_bucket}",
          "arn:aws:s3:::${local.logs_bucket}/*"
        ]
      }
    ]
  })
}

# Athena named query for creating tables (one for each log type)
# Only created when create_ddl_queries is true to avoid DDL in saved queries
resource "aws_athena_named_query" "create_table" {
  for_each = var.create_ddl_queries ? var.log_types : {}

  name      = "${local.project_env}-${each.value.table_name_suffix}-create-table"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name

  query = templatefile("${path.module}/../templates/create_table.sql", {
    table_name        = "${local.project_env}-${each.value.table_name_suffix}"
    database_name     = local.athena_database_name
    s3_location       = "s3://${local.logs_bucket}/${var.logs_s3_prefix}/${each.key}/"
    schema_fields     = each.value.schema
    catalog_name      = var.app
    data_source       = "AwsDataCatalog"
    project_env       = local.project_env
    partition_4_value = ""
  })

  description = "${each.value.description}のテーブル作成 (${each.key})"
}

# Athena named query for adding partitions (one for each log type)
# DISABLED: パーティション追加クエリは「保存したクエリ」に不要のため無効化
# resource "aws_athena_named_query" "add_partitions" {
#   for_each = var.log_types
#
#   name      = "${local.project_env}-${each.value.table_name_suffix}-add-partitions"
#   database  = local.athena_database_name
#   workgroup = aws_athena_workgroup.main.name
#
#   query = templatefile("${path.module}/../templates/add_partitions.sql", {
#     table_name        = "${local.project_env}-${each.value.table_name_suffix}"
#     database_name     = local.athena_database_name
#     s3_location       = "s3://${local.logs_bucket}/${var.logs_s3_prefix}/${each.key}/"
#     catalog_name      = var.app
#     data_source       = "AwsDataCatalog"
#     project_env       = local.project_env
#     partition_4_value = ""
#   })
#
#   description = "${each.value.description}のパーティション追加 (${each.key})"
# }

# Athena named query for sample queries (one for each log type with dedicated template)
resource "aws_athena_named_query" "sample_queries" {
  for_each = var.log_types

  name      = "${local.project_env}-${each.value.table_name_suffix}-sample-queries"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name

  query = templatefile("${path.module}/../templates/${local.sample_query_files[each.key]}", {
    table_name        = "${local.project_env}-${each.value.table_name_suffix}"
    database_name     = local.athena_database_name
    catalog_name      = var.app
    data_source       = "AwsDataCatalog"
    project_env       = local.project_env
    partition_4_value = ""
  })

  description = "${each.value.description}のサンプルクエリ (${each.key})"
}

# Athena named query for all tables overview
resource "aws_athena_named_query" "all_tables_overview" {
  name      = "${local.project_env}-all-tables-overview"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name

  query = templatefile("${path.module}/../templates/overview/all_tables_log_count_summary.sql", {
    database_name     = local.athena_database_name
    table_names       = [for k, v in var.log_types : "${local.project_env}-${v.table_name_suffix}"]
    catalog_name      = var.app
    data_source       = "AwsDataCatalog"
    project_env       = local.project_env
    partition_4_value = ""
  })

  description = "全ログテーブルの概要クエリ"
}

# Athena View作成クエリ（index.html手順4bに準拠）
# Only created when create_ddl_queries is true to avoid DDL in saved queries
resource "aws_athena_named_query" "create_views" {
  for_each = var.create_ddl_queries ? var.log_types : {}

  name      = "${local.project_env}-${each.value.table_name_suffix}-create-view"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name

  query = templatefile("${path.module}/../templates/create_view.sql", {
    view_name         = "${local.project_env}-${each.value.table_name_suffix}-view"
    table_name        = "${local.project_env}-${each.value.table_name_suffix}"
    database_name     = local.athena_database_name
    catalog_name      = var.app
    data_source       = "AwsDataCatalog"
    project_env       = local.project_env
    partition_4_value = ""
  })

  description = "${each.value.description}のビュー作成 (${each.key})"
}

# Athena named query for current day all data
resource "aws_athena_named_query" "current_day_all_data" {
  name      = "${local.project_env}-current-day-all-data"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name

  query = templatefile("${path.module}/../templates/current_day_all_data.sql", {
    database_name     = local.athena_database_name
    table_names       = [for k, v in var.log_types : "${local.project_env}-${v.table_name_suffix}"]
    log_types         = keys(var.log_types)
    catalog_name      = var.app
    data_source       = "AwsDataCatalog"
    project_env       = local.project_env
    django_web_table  = "${local.project_env}-django_web"
    nginx_web_table   = "${local.project_env}-nginx_web"
    error_table       = "${local.project_env}-error"
    partition_4_value = ""
  })

  description = "全ログテーブルから当日の全データを取得するクエリ"
}
