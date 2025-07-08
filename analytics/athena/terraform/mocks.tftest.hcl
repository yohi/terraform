# AWS認証情報なしで実行可能なモックテスト

# モックプロバイダーの設定
mock_provider "aws" {
  # AWS caller identity
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  # AWS region
  mock_data "aws_region" {
    defaults = {
      name = "ap-northeast-1"
    }
  }

  # S3バケット存在確認（既存バケット使用時）
  mock_data "aws_s3_bucket" {
    defaults = {
      bucket                      = "test-dev-analytics-logs"
      bucket_domain_name          = "test-dev-analytics-logs.s3.amazonaws.com"
      bucket_regional_domain_name = "test-dev-analytics-logs.s3.ap-northeast-1.amazonaws.com"
      hosted_zone_id              = "Z2M4EHUR26P7ZW"
      region                      = "ap-northeast-1"
      arn                         = "arn:aws:s3:::test-dev-analytics-logs"
    }
  }

  # S3バケットリソース
  mock_resource "aws_s3_bucket" {
    defaults = {
      id                          = "test-dev-analytics-logs"
      bucket                      = "test-dev-analytics-logs"
      bucket_domain_name          = "test-dev-analytics-logs.s3.amazonaws.com"
      bucket_regional_domain_name = "test-dev-analytics-logs.s3.ap-northeast-1.amazonaws.com"
      hosted_zone_id              = "Z2M4EHUR26P7ZW"
      region                      = "ap-northeast-1"
      arn                         = "arn:aws:s3:::test-dev-analytics-logs"
      tags = {
        Name        = "test-dev-analytics-logs"
        Project     = "test"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
    }
  }

  # S3バケット暗号化設定
  mock_resource "aws_s3_bucket_server_side_encryption_configuration" {
    defaults = {
      id     = "test-dev-analytics-logs"
      bucket = "test-dev-analytics-logs"
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  # S3バケットバージョニング設定
  mock_resource "aws_s3_bucket_versioning" {
    defaults = {
      id     = "test-dev-analytics-logs"
      bucket = "test-dev-analytics-logs"
      versioning_configuration = {
        status = "Enabled"
      }
    }
  }

  # S3バケットパブリックアクセスブロック
  mock_resource "aws_s3_bucket_public_access_block" {
    defaults = {
      id                      = "test-dev-analytics-logs"
      bucket                  = "test-dev-analytics-logs"
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
  }

  # Glue Catalogデータベース
  mock_resource "aws_glue_catalog_database" {
    defaults = {
      id          = "test_dev_analytics_logs"
      name        = "test_dev_analytics_logs"
      description = "Analytics database for test-dev-analytics"
    }
  }

  # IAMロール（athena_role）
  mock_resource "aws_iam_role" {
    defaults = {
      id                 = "test-dev-analytics-athena-role"
      name               = "test-dev-analytics-athena-role"
      arn                = "arn:aws:iam::123456789012:role/test-dev-analytics-athena-role"
      path               = "/"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"athena.amazonaws.com\"}}]}"
    }
  }

  # IAMロールポリシーアタッチメント
  mock_resource "aws_iam_role_policy_attachment" {
    defaults = {
      id         = "test-dev-analytics-athena-role-20240101123456789012345678"
      role       = "test-dev-analytics-athena-role"
      policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
    }
  }

  # IAMロールポリシー
  mock_resource "aws_iam_role_policy" {
    defaults = {
      id     = "test-dev-analytics-athena-role:test-dev-analytics-athena-s3-policy"
      name   = "test-dev-analytics-athena-s3-policy"
      role   = "test-dev-analytics-athena-role"
      policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":[\"arn:aws:s3:::test-dev-analytics-logs/*\"]}]}"
    }
  }

  # Glue Crawler
  mock_resource "aws_glue_crawler" {
    defaults = {
      id            = "test-dev-analytics-django-web-crawler"
      name          = "test-dev-analytics-django-web-crawler"
      database_name = "test_dev_analytics_logs"
      role          = "arn:aws:iam::123456789012:role/test-dev-analytics-glue-crawler-role"
      s3_target = {
        path = "s3://test-dev-analytics-logs/firelens/firelens/fluent-bit-logs/django_web/"
      }
    }
  }

  # Athena Workgroup
  mock_resource "aws_athena_workgroup" {
    defaults = {
      id          = "test-dev-analytics"
      name        = "test-dev-analytics"
      description = "Athena workgroup for test-dev-analytics"
      tags = {
        Name        = "test-dev-analytics"
        Project     = "test"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
      configuration = {
        enforce_workgroup_configuration = true
        publish_cloudwatch_metrics      = true
        result_configuration = {
          output_location = "s3://test-dev-analytics-logs/athena-query-results/"
          encryption_configuration = {
            encryption_option = "SSE_S3"
          }
        }
      }
    }
  }

  # Athena Named Query
  mock_resource "aws_athena_named_query" {
    defaults = {
      id          = "12345678-1234-1234-1234-123456789012"
      name        = "test-dev-analytics-create-table-django-web"
      description = "Create table for django_web logs"
      database    = "test_dev_analytics_logs"
      workgroup   = "test-dev-analytics"
      query       = "CREATE EXTERNAL TABLE test_dev_django_web ..."
    }
  }

  # IAMポリシー
  mock_resource "aws_iam_policy" {
    defaults = {
      id          = "arn:aws:iam::123456789012:policy/test-dev-analytics-athena-admin-policy"
      name        = "test-dev-analytics-athena-admin-policy"
      arn         = "arn:aws:iam::123456789012:policy/test-dev-analytics-athena-admin-policy"
      path        = "/"
      description = "Athena admin policy for test-dev-analytics"
      policy      = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"athena:*\"],\"Resource\":[\"*\"]}]}"
    }
  }
}

# Test 1: 基本的なモックテスト
run "mock_basic_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket = true
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket name should match expected value"
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "test_dev_analytics_logs"
    error_message = "Glue database name should match expected value"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "test-dev-analytics"
    error_message = "Athena workgroup name should match expected value"
  }

  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 3
    error_message = "Should create 3 Glue crawlers for default log types"
  }
}

# Test 2: DDLクエリ作成モックテスト
run "mock_ddl_queries_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket = true
    create_ddl_queries = true
  }

  assert {
    condition     = length(aws_athena_named_query.create_table) == 3
    error_message = "Should create CREATE TABLE queries for each log type"
  }

  assert {
    condition     = length(aws_athena_named_query.create_views) == 3
    error_message = "Should create CREATE VIEW queries for each log type"
  }

  assert {
    condition     = length(aws_athena_named_query.sample_queries) == 3
    error_message = "Should create sample queries for each log type"
  }
}

# Test 3: QuickSight統合モックテスト（無効化）
# run "mock_quicksight_integration_test" {
#   command = apply

#   variables {
#     project_name       = "test"
#     environment        = "dev"
#     app                = "analytics"
#     logs_bucket_name   = "test-dev-analytics-logs"
#     logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
#     auto_create_bucket = true
#     enable_quicksight  = true
#   }

#   assert {
#     condition     = aws_iam_role.quicksight_role[0].name == "test-dev-quicksight-role"
#     error_message = "QuickSight IAM role should be created"
#   }

#   assert {
#     condition     = output.quicksight_role_arn == "arn:aws:iam::123456789012:role/test-dev-quicksight-role"
#     error_message = "QuickSight role ARN should be correct"
#   }
# }

# Test 4: 既存バケット使用モックテスト
run "mock_existing_bucket_test" {
  command = apply

  variables {
    project_name           = "test"
    environment            = "dev"
    app                    = "analytics"
    logs_bucket_name       = "existing-logs-bucket"
    logs_s3_prefix         = "app/logs"
    auto_create_bucket     = false
    skip_bucket_validation = true
  }

  assert {
    condition     = length(aws_s3_bucket.logs_bucket) == 0
    error_message = "Should not create S3 bucket when using existing bucket"
  }

  assert {
    condition     = output.logs_bucket_name == "existing-logs-bucket"
    error_message = "Output should show existing bucket name"
  }

  assert {
    condition     = output.s3_data_locations["django_web"] == "s3://existing-logs-bucket/app/logs/django_web/"
    error_message = "S3 locations should use existing bucket"
  }
}

# Test 5: カスタムログタイプモックテスト
run "mock_custom_log_types_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "custom/logs"
    auto_create_bucket = true

    log_types = {
      api = {
        table_name_suffix = "api"
        description       = "API server logs"
        schema = {
          timestamp = {
            type        = "string"
            description = "Request timestamp"
          }
          method = {
            type        = "string"
            description = "HTTP method"
          }
          status = {
            type        = "int"
            description = "HTTP status code"
          }
        }
      }
    }
  }

  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 1
    error_message = "Should create 1 crawler for custom log type"
  }

  assert {
    condition     = aws_glue_crawler.log_crawlers["api"].name == "test-dev-analytics-api-crawler"
    error_message = "API crawler name should be correct"
  }

  assert {
    condition     = output.athena_table_names["api"] == "test-dev-api"
    error_message = "API table name should be correct"
  }
}

# Test 6: 出力値検証モックテスト
run "mock_output_validation_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket = true
  }

  assert {
    condition     = output.project == "test"
    error_message = "Project output should match input"
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Environment output should match input"
  }

  assert {
    condition     = output.app == "analytics"
    error_message = "App output should match input"
  }

  assert {
    condition     = output.project_env == "test-dev"
    error_message = "Project-env output should be correctly formatted"
  }

  assert {
    condition     = output.aws_account_id == "123456789012"
    error_message = "AWS account ID should match mock value"
  }

  assert {
    condition     = output.athena_console_url == "https://ap-northeast-1.console.aws.amazon.com/athena/home?region=ap-northeast-1#/query-editor"
    error_message = "Athena console URL should be correct"
  }

  assert {
    condition     = output.athena_query_results_location == "s3://test-dev-analytics-logs/athena-query-results/"
    error_message = "Athena query results location should be correct"
  }

  assert {
    condition     = output.glue_database_name == "test_dev_analytics_logs"
    error_message = "Glue database name should match expected value"
  }

  assert {
    condition     = output.glue_database_arn == "arn:aws:glue:ap-northeast-1:123456789012:database/test_dev_analytics_logs"
    error_message = "Glue database ARN should be correct"
  }

  assert {
    condition     = output.athena_workgroup_name == "test-dev-analytics"
    error_message = "Athena workgroup name should match expected value"
  }

  assert {
    condition     = output.logs_bucket_name == "test-dev-analytics-logs"
    error_message = "S3 bucket name should match expected value"
  }

  assert {
    condition     = output.athena_role_arn == "arn:aws:iam::123456789012:role/test-dev-analytics-athena-role"
    error_message = "Athena role ARN should be correct"
  }

  assert {
    condition     = output.athena_database_name == "test_dev_analytics_logs"
    error_message = "Athena database name should match expected value"
  }

  assert {
    condition     = output.athena_data_source_name == "AwsDataCatalog"
    error_message = "Athena data source name should be AwsDataCatalog"
  }

  assert {
    condition     = output.athena_catalog_name == "analytics"
    error_message = "Athena catalog name should match app name"
  }

  assert {
    condition     = length(output.athena_table_names) == 3
    error_message = "Should output 3 table names for default log types"
  }

  assert {
    condition     = length(output.s3_data_locations) == 3
    error_message = "Should output 3 S3 locations for default log types"
  }

  assert {
    condition     = length(output.glue_crawler_names) == 3
    error_message = "Should output 3 crawler names for default log types"
  }
}

# Test 7: S3バケット設定テスト
run "mock_s3_bucket_configuration_test" {
  command = apply

  variables {
    project_name        = "test"
    environment         = "dev"
    app                 = "analytics"
    logs_bucket_name    = "test-dev-analytics-logs"
    logs_s3_prefix      = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket  = true
    data_classification = "confidential"
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket should be created with correct name"
  }

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket encryption should be configured"
  }

  assert {
    condition     = aws_s3_bucket_versioning.logs_bucket_versioning[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket versioning should be configured"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket public access block should be configured"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab[0].block_public_acls == true
    error_message = "S3 bucket should block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab[0].block_public_policy == true
    error_message = "S3 bucket should block public policy"
  }
}

# Test 8: Athena Workgroup設定テスト
run "mock_athena_workgroup_configuration_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket = true
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "test-dev-analytics"
    error_message = "Athena workgroup should be created with correct name"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].enforce_workgroup_configuration == true
    error_message = "Athena workgroup should enforce configuration"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].publish_cloudwatch_metrics_enabled == true
    error_message = "Athena workgroup should publish CloudWatch metrics"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].result_configuration[0].output_location == "s3://test-dev-analytics-logs/athena-query-results/"
    error_message = "Athena workgroup should have correct output location"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].result_configuration[0].encryption_configuration[0].encryption_option == "SSE_S3"
    error_message = "Athena workgroup should use SSE_S3 encryption"
  }
}

# Test 9: IAMロール設定テスト
run "mock_iam_roles_test" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket = true
  }

  assert {
    condition     = aws_iam_role.athena_role.name == "test-dev-analytics-athena-role"
    error_message = "Athena IAM role should be created with correct name"
  }

  assert {
    condition     = aws_iam_role.glue_crawler_role.name == "test-dev-analytics-glue-crawler-role"
    error_message = "Glue crawler IAM role should be created with correct name"
  }

  assert {
    condition     = aws_iam_role.athena_workgroup_user_role.name == "test-dev-analytics-athena-workgroup-user-role"
    error_message = "Athena workgroup user IAM role should be created with correct name"
  }

  assert {
    condition     = aws_iam_policy.athena_admin_policy.name == "test-dev-analytics-athena-admin-policy"
    error_message = "Athena admin policy should be created with correct name"
  }
}

# Test 10: 本番環境設定テスト
run "mock_production_environment_test" {
  command = apply

  variables {
    project_name        = "production"
    environment         = "prd"
    app                 = "analytics"
    logs_bucket_name    = "production-prd-analytics-logs"
    logs_s3_prefix      = "firelens/firelens/fluent-bit-logs"
    auto_create_bucket  = true
    data_classification = "restricted"
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].bucket == "production-prd-analytics-logs"
    error_message = "S3 bucket should be created with production naming"
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "production_prd_analytics_logs"
    error_message = "Glue database should be created with production naming"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "production-prd-analytics"
    error_message = "Athena workgroup should be created with production naming"
  }

  assert {
    condition     = aws_iam_role.athena_role.name == "production-prd-analytics-athena-role"
    error_message = "Athena IAM role should be created with production naming"
  }

  assert {
    condition     = aws_iam_role.glue_crawler_role.name == "production-prd-analytics-glue-crawler-role"
    error_message = "Glue crawler IAM role should be created with production naming"
  }

  assert {
    condition     = output.project_env == "production-prd"
    error_message = "Project-env should be correctly formatted for production"
  }

  assert {
    condition     = output.athena_console_url == "https://ap-northeast-1.console.aws.amazon.com/athena/home?region=ap-northeast-1#/query-editor"
    error_message = "Athena console URL should be correct for production"
  }
}
