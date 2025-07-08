# Analytics/Athena Basic Tests
# 基本的なリソース作成と設定を検証

# Test 1: 基本的なAthena設定
run "basic_athena_setup" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    aws_region         = "ap-northeast-1"
    auto_create_bucket = true
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "test_dev_analytics_logs"
    error_message = "Glue database name should be project_env_app_logs format"
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].bucket == "test-dev-analytics-logs"
    error_message = "S3 bucket name should match input"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "test-dev-analytics"
    error_message = "Athena workgroup name should follow naming convention"
  }

  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 3
    error_message = "Should create 3 Glue crawlers for default log types"
  }

  assert {
    condition     = aws_iam_role.athena_role.name == "test-dev-analytics-athena-role"
    error_message = "Athena IAM role name should follow naming convention"
  }

  assert {
    condition     = aws_iam_role.glue_crawler_role.name == "test-dev-analytics-glue-crawler-role"
    error_message = "Glue crawler IAM role name should follow naming convention"
  }
}

# Test 2: カスタムAthenaデータベース名
run "custom_athena_database_name" {
  command = apply

  variables {
    project_name         = "test"
    environment          = "dev"
    app                  = "analytics"
    logs_bucket_name     = "test-dev-analytics-logs"
    logs_s3_prefix       = "firelens/firelens/fluent-bit-logs"
    athena_database_name = "custom_analytics_db"
    auto_create_bucket   = true
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "custom_analytics_db"
    error_message = "Glue database name should use custom name when provided"
  }

  assert {
    condition     = output.athena_database_name == "custom_analytics_db"
    error_message = "Output should reflect custom database name"
  }
}

# Test 3: DDLクエリ作成設定
run "ddl_queries_creation" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    create_ddl_queries = true
    auto_create_bucket = true
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

# Test 4: QuickSight統合設定
run "quicksight_integration" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "firelens/firelens/fluent-bit-logs"
    enable_quicksight  = true
    auto_create_bucket = true
  }

  assert {
    condition     = aws_iam_role.quicksight_role.name == "test-dev-analytics-quicksight-role"
    error_message = "QuickSight IAM role should be created when enabled"
  }

  assert {
    condition     = output.quicksight_role_arn != ""
    error_message = "QuickSight role ARN should be output"
  }
}

# Test 5: Crawler スケジュール設定
run "crawler_schedule_configuration" {
  command = apply

  variables {
    project_name                = "test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "test-dev-analytics-logs"
    logs_s3_prefix              = "firelens/firelens/fluent-bit-logs"
    enable_crawler_schedule     = true
    crawler_schedule_expression = "cron(0 2 * * ? *)"
    auto_create_bucket          = true
  }

  assert {
    condition     = aws_glue_crawler.log_crawlers["django_web"].schedule == "cron(0 2 * * ? *)"
    error_message = "Crawler schedule should be set when enabled"
  }

  assert {
    condition     = aws_glue_crawler.log_crawlers["nginx_web"].schedule == "cron(0 2 * * ? *)"
    error_message = "All crawlers should have the same schedule"
  }
}

# Test 6: 本番環境設定
run "production_environment_configuration" {
  command = apply

  variables {
    project_name       = "myapp"
    environment        = "prd"
    app                = "analytics"
    logs_bucket_name   = "myapp-prd-analytics-logs"
    logs_s3_prefix     = "production/logs"
    retention_period   = "7-years"
    monitoring_level   = "high"
    auto_create_bucket = true
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "myapp_prd_analytics_logs"
    error_message = "Production database name should follow naming convention"
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].tags["Environment"] == "prd"
    error_message = "S3 bucket should have correct environment tag"
  }

  assert {
    condition     = aws_s3_bucket.logs_bucket[0].tags["RetentionPeriod"] == "7-years"
    error_message = "S3 bucket should have correct retention period tag"
  }

  assert {
    condition     = aws_athena_workgroup.main.tags["MonitoringLevel"] == "high"
    error_message = "Athena workgroup should have correct monitoring level tag"
  }
}

# Test 7: カスタムログタイプ設定
run "custom_log_types" {
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
          path = {
            type        = "string"
            description = "Request path"
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
    error_message = "Crawler name should match custom log type"
  }

  assert {
    condition     = output.athena_table_names["api"] == "test-dev-api"
    error_message = "Output should include custom log type table name"
  }
}

# Test 8: 既存バケット使用設定
run "existing_bucket_usage" {
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

# Test 9: Athena Workgroup設定詳細
run "athena_workgroup_detailed_configuration" {
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
    condition     = aws_athena_workgroup.main.configuration[0].enforce_workgroup_configuration == true
    error_message = "Athena workgroup should enforce configuration"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].publish_cloudwatch_metrics == true
    error_message = "Athena workgroup should publish CloudWatch metrics"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].result_configuration[0].output_location == "s3://test-dev-analytics-logs/athena-query-results/"
    error_message = "Athena workgroup should have correct result location"
  }

  assert {
    condition     = aws_athena_workgroup.main.configuration[0].result_configuration[0].encryption_configuration[0].encryption_option == "SSE_S3"
    error_message = "Athena workgroup should have correct encryption configuration"
  }
}

# Test 10: 出力値の検証
run "output_validation" {
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
    condition     = output.athena_console_url == "https://ap-northeast-1.console.aws.amazon.com/athena/home?region=ap-northeast-1#/query-editor"
    error_message = "Athena console URL should be correct"
  }

  assert {
    condition     = output.athena_query_results_location == "s3://test-dev-analytics-logs/athena-query-results/"
    error_message = "Athena query results location should be correct"
  }

  assert {
    condition     = length(keys(output.s3_data_locations)) == 3
    error_message = "Should output S3 locations for all log types"
  }

  assert {
    condition     = output.glue_database_name == "test_dev_analytics_logs"
    error_message = "Glue database name output should be correct"
  }

  assert {
    condition     = length(keys(output.glue_crawler_names)) == 3
    error_message = "Should output all crawler names"
  }
}
