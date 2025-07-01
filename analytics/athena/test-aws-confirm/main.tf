# Get current AWS account information for validation
data "aws_caller_identity" "current" {}

# AWS Account validation with Y/N confirmation (runs during plan and apply)
data "external" "aws_account_validation" {
  program = ["bash", "${path.module}/aws_account_check.sh"]
}

# Local values to display account information
locals {
  account_info = {
    account_id = data.aws_caller_identity.current.account_id
    user_id    = data.aws_caller_identity.current.user_id
    arn        = data.aws_caller_identity.current.arn
  }
}



# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket = local.athena_results_bucket_name
  tags   = local.tags

  depends_on = [data.external.aws_account_validation]
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "delete_old_results"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Athena workgroup
resource "aws_athena_workgroup" "main" {
  name = "${local.project_env}-analytics"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = local.tags
}

# Athena database
resource "aws_athena_database" "logs" {
  name   = local.athena_database_name
  bucket = aws_s3_bucket.athena_results.bucket

  encryption_configuration {
    encryption_option = "SSE_S3"
  }

  depends_on = [aws_athena_workgroup.main]
}

# IAM role for Athena
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
      }
    ]
  })

  tags = local.tags
}

# IAM policy for Athena to access S3
resource "aws_iam_role_policy" "athena_s3_policy" {
  name = "${local.project_env}-athena-s3-policy"
  role = aws_iam_role.athena_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
          "arn:aws:s3:::${local.logs_bucket_name}",
          "arn:aws:s3:::${local.logs_bucket_name}/*",
          "arn:aws:s3:::${aws_s3_bucket.athena_results.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.athena_results.bucket}/*"
        ]
      },
      {
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
        Resource = "*"
      }
    ]
  })
}

# Athena named query for creating tables (one for each log type)
resource "aws_athena_named_query" "create_table" {
  for_each = var.log_types

  name      = "${local.project_env}_${each.value.table_name_suffix}_create_table"
  database  = aws_athena_database.logs.name
  workgroup = aws_athena_workgroup.main.name
  query = templatefile("${path.module}/../templates/create_table.sql", {
    table_name    = "${local.project_env}_${each.value.table_name_suffix}"
    database_name = local.athena_database_name
    s3_location   = "s3://${local.logs_bucket_name}/${var.logs_s3_prefix}/${each.key}/"
    schema_fields = each.value.schema
  })

  description = "Create table for ${each.value.description}"
}

# Athena named query for adding partitions (one for each log type)
resource "aws_athena_named_query" "add_partitions" {
  for_each = var.log_types

  name      = "${local.project_env}_${each.value.table_name_suffix}_add_partitions"
  database  = aws_athena_database.logs.name
  workgroup = aws_athena_workgroup.main.name
  query = templatefile("${path.module}/../templates/add_partitions.sql", {
    table_name    = "${local.project_env}_${each.value.table_name_suffix}"
    database_name = local.athena_database_name
    s3_location   = "s3://${local.logs_bucket_name}/${var.logs_s3_prefix}/${each.key}/"
  })

  description = "Add partitions for ${each.value.description}"
}

# Athena named query for sample queries (one for each log type)
resource "aws_athena_named_query" "sample_queries" {
  for_each = var.log_types

  name      = "${local.project_env}_${each.value.table_name_suffix}_sample_queries"
  database  = aws_athena_database.logs.name
  workgroup = aws_athena_workgroup.main.name
  query = templatefile("${path.module}/../templates/sample_queries_${each.key}.sql", {
    table_name    = "${local.project_env}_${each.value.table_name_suffix}"
    database_name = local.athena_database_name
  })

  description = "Sample queries for ${each.value.description}"
}

# All tables overview query
resource "aws_athena_named_query" "all_tables_overview" {
  name      = "${local.project_env}_all_tables_overview"
  database  = aws_athena_database.logs.name
  workgroup = aws_athena_workgroup.main.name
  query = templatefile("${path.module}/../templates/all_tables_overview.sql", {
    database_name = local.athena_database_name
    table_names   = [for k, v in var.log_types : "${local.project_env}_${v.table_name_suffix}"]
  })

  description = "Overview queries for all log tables"
}
