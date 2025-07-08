# Analytics/Athena Integration Tests
# 実際のAWSリソースを使用した統合テスト（実際のコスト発生の可能性あり）

# Test 1: 基本的な統合テスト
run "basic_integration_test" {
  command = apply

  variables {
    project_name       = "integration-test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "integration-test-dev-analytics-logs"
    logs_s3_prefix     = "test/logs"
    auto_create_bucket = true
  }

  # AWSリソースの作成確認
  assert {
    condition     = length(aws_s3_bucket.logs_bucket) > 0 && aws_s3_bucket.logs_bucket[0].bucket == "integration-test-dev-analytics-logs"
    error_message = "S3 bucket should be created successfully"
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "integration_test_dev_analytics_logs"
    error_message = "Glue database should be created successfully"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "integration-test-dev-analytics"
    error_message = "Athena workgroup should be created successfully"
  }

  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 3
    error_message = "All Glue crawlers should be created successfully"
  }

  # IAMロールの作成確認
  assert {
    condition     = aws_iam_role.athena_role.name == "integration-test-dev-analytics-athena-role"
    error_message = "Athena IAM role should be created successfully"
  }

  assert {
    condition     = aws_iam_role.glue_crawler_role.name == "integration-test-dev-analytics-glue-crawler-role"
    error_message = "Glue crawler IAM role should be created successfully"
  }

  # 出力値の確認
  assert {
    condition     = output.aws_account_id != ""
    error_message = "AWS account ID should be populated"
  }

  assert {
    condition     = output.athena_console_url != ""
    error_message = "Athena console URL should be populated"
  }

  # 基本統合テストでのS3バケット暗号化設定確認（セキュリティ重要）
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption) > 0 && aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Basic test S3 bucket encryption should be configured"
  }

  # 基本統合テストでのS3バケットパブリックアクセスブロック確認（セキュリティ重要）
  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_acls == true
    error_message = "Basic test S3 bucket public access should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_policy == true
    error_message = "Basic test S3 bucket public policy should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.ignore_public_acls == true
    error_message = "Basic test S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.restrict_public_buckets == true
    error_message = "Basic test S3 bucket should restrict public buckets"
  }
}

# Test 2: 完全な機能統合テスト
run "complete_feature_integration_test" {
  command = apply

  variables {
    project_name                = "integration-test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "integration-test-dev-analytics-logs"
    logs_s3_prefix              = "test/logs"
    auto_create_bucket          = true
    create_ddl_queries          = true
    enable_quicksight           = true
    enable_crawler_schedule     = true
    crawler_schedule_expression = "cron(0 2 * * ? *)"
  }

  # DDLクエリの作成確認
  assert {
    condition     = length(aws_athena_named_query.create_table) == 3
    error_message = "CREATE TABLE queries should be created"
  }

  assert {
    condition     = length(aws_athena_named_query.create_views) == 3
    error_message = "CREATE VIEW queries should be created"
  }

  # QuickSightロールの作成確認
  assert {
    condition     = aws_iam_role.quicksight_role.name == "integration-test-dev-analytics-quicksight-role"
    error_message = "QuickSight IAM role should be created"
  }

  # クローラースケジュール設定確認
  assert {
    condition     = aws_glue_crawler.log_crawlers["django_web"].schedule == "cron(0 2 * * ? *)"
    error_message = "Crawler schedule should be set correctly"
  }

  # S3バケット暗号化設定確認
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption) > 0 && aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "S3 bucket encryption should be configured"
  }

  # S3バケットパブリックアクセスブロック確認（全設定）
  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_acls == true
    error_message = "S3 bucket public access should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_policy == true
    error_message = "S3 bucket public policy should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.ignore_public_acls == true
    error_message = "S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.restrict_public_buckets == true
    error_message = "S3 bucket should restrict public buckets"
  }
}

# Test 3: カスタムログタイプ統合テスト
run "custom_log_types_integration_test" {
  command = apply

  variables {
    project_name       = "integration-test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "integration-test-dev-analytics-logs"
    logs_s3_prefix     = "test/logs"
    auto_create_bucket = true
    create_ddl_queries = true

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
      worker = {
        table_name_suffix = "worker"
        description       = "Background worker logs"
        schema = {
          timestamp = {
            type        = "string"
            description = "Task timestamp"
          }
          job_id = {
            type        = "string"
            description = "Job ID"
          }
          status = {
            type        = "string"
            description = "Job status"
          }
        }
      }
    }
  }

  # カスタムログタイプのクローラー作成確認
  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 2
    error_message = "Should create 2 crawlers for custom log types"
  }

  assert {
    condition     = aws_glue_crawler.log_crawlers["api"].name == "integration-test-dev-analytics-api-crawler"
    error_message = "API crawler should be created with correct name"
  }

  assert {
    condition     = aws_glue_crawler.log_crawlers["worker"].name == "integration-test-dev-analytics-worker-crawler"
    error_message = "Worker crawler should be created with correct name"
  }

  # カスタムログタイプのDDLクエリ作成確認
  assert {
    condition     = length(aws_athena_named_query.create_table) == 2
    error_message = "Should create CREATE TABLE queries for custom log types"
  }

  assert {
    condition     = aws_athena_named_query.create_table["api"].name == "integration-test-dev-analytics-create-table-api"
    error_message = "API CREATE TABLE query should be created"
  }

  # 出力値の確認
  assert {
    condition     = length(keys(output.athena_table_names)) == 2
    error_message = "Should output table names for custom log types"
  }

  assert {
    condition     = output.athena_table_names["api"] == "integration-test-dev-api"
    error_message = "API table name should be correct"
  }

  # カスタムログタイプ環境のS3バケット暗号化設定確認（セキュリティ重要）
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption) > 0 && aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Custom log types S3 bucket encryption should be configured"
  }

  # カスタムログタイプ環境のS3バケットパブリックアクセスブロック確認（セキュリティ重要）
  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_acls == true
    error_message = "Custom log types S3 bucket public access should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_policy == true
    error_message = "Custom log types S3 bucket public policy should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.ignore_public_acls == true
    error_message = "Custom log types S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.restrict_public_buckets == true
    error_message = "Custom log types S3 bucket should restrict public buckets"
  }
}

# Test 4: 本番環境統合テスト
run "production_environment_integration_test" {
  command = apply

  variables {
    project_name       = "integration-test"
    environment        = "prd"
    app                = "analytics"
    logs_bucket_name   = "integration-test-prd-analytics-logs"
    logs_s3_prefix     = "production/logs"
    auto_create_bucket = true
    retention_period   = "7-years"
    monitoring_level   = "high"

    # 本番環境特有のタグ
    tags = {
      CriticalityLevel = "high"
      AuditRequired    = "yes"
      BackupRequired   = "yes"
    }
  }

  # 本番環境のタグ確認
  assert {
    condition     = length(aws_s3_bucket.logs_bucket) > 0 && aws_s3_bucket.logs_bucket[0].tags["Environment"] == "prd"
    error_message = "S3 bucket should have correct environment tag"
  }

  assert {
    condition     = length(aws_s3_bucket.logs_bucket) > 0 && aws_s3_bucket.logs_bucket[0].tags["CriticalityLevel"] == "high"
    error_message = "S3 bucket should have correct criticality level tag"
  }

  assert {
    condition     = aws_athena_workgroup.main.tags["RetentionPeriod"] == "7-years"
    error_message = "Athena workgroup should have correct retention period tag"
  }

  assert {
    condition     = aws_athena_workgroup.main.tags["MonitoringLevel"] == "high"
    error_message = "Athena workgroup should have correct monitoring level tag"
  }

  # 本番環境のリソース命名確認
  assert {
    condition     = aws_glue_catalog_database.main.name == "integration_test_prd_analytics_logs"
    error_message = "Production database name should follow naming convention"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "integration-test-prd-analytics"
    error_message = "Production workgroup name should follow naming convention"
  }

  # 本番環境のS3バケット暗号化設定確認（セキュリティ重要）
  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption) > 0 && aws_s3_bucket_server_side_encryption_configuration.logs_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Production S3 bucket encryption should be configured"
  }

  # 本番環境のS3バケットパブリックアクセスブロック確認（セキュリティ重要）
  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_acls == true
    error_message = "Production S3 bucket public access should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.block_public_policy == true
    error_message = "Production S3 bucket public policy should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.ignore_public_acls == true
    error_message = "Production S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs_bucket_pab.restrict_public_buckets == true
    error_message = "Production S3 bucket should restrict public buckets"
  }
}

# Test 5: 既存バケット統合テスト
run "existing_bucket_integration_test" {
  command = apply

  variables {
    project_name           = "integration-test"
    environment            = "dev"
    app                    = "analytics"
    logs_bucket_name       = "integration-test-dev-analytics-logs"
    logs_s3_prefix         = "test/logs"
    auto_create_bucket     = false
    skip_bucket_validation = true
  }

  # 既存バケット使用時の確認
  assert {
    condition     = length(aws_s3_bucket.logs_bucket) == 0
    error_message = "Should not create S3 bucket when using existing bucket"
  }

  assert {
    condition     = output.logs_bucket_name == "integration-test-dev-analytics-logs"
    error_message = "Should use existing bucket name"
  }

  # 他のリソースは正常に作成されることを確認
  assert {
    condition     = aws_glue_catalog_database.main.name == "integration_test_dev_analytics_logs"
    error_message = "Glue database should be created even when using existing bucket"
  }

  assert {
    condition     = length(aws_glue_crawler.log_crawlers) == 3
    error_message = "Crawlers should be created even when using existing bucket"
  }
}

# Test 6: 出力値の詳細確認
run "detailed_output_validation" {
  command = apply

  variables {
    project_name       = "integration-test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "integration-test-dev-analytics-logs"
    logs_s3_prefix     = "test/logs"
    auto_create_bucket = true
    create_ddl_queries = true
  }

  # 基本出力値の確認
  assert {
    condition     = output.project == "integration-test"
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
    condition     = output.project_env == "integration-test-dev"
    error_message = "Project-env output should be correctly formatted"
  }

  # AWS特有の出力値確認
  assert {
    condition     = can(regex("^[0-9]{12}$", output.aws_account_id))
    error_message = "AWS account ID should be 12 digits"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/", output.athena_role_arn))
    error_message = "Athena role ARN should be valid"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/", output.glue_crawler_role_arn))
    error_message = "Glue crawler role ARN should be valid"
  }

  # S3関連の出力値確認
  assert {
    condition     = output.athena_query_results_location == "s3://integration-test-dev-analytics-logs/athena-query-results/"
    error_message = "Athena query results location should be correct"
  }

  assert {
    condition     = output.s3_data_locations["django_web"] == "s3://integration-test-dev-analytics-logs/test/logs/django_web/"
    error_message = "S3 data location should be correct"
  }

  # コンソールURL確認
  assert {
    condition     = can(regex("^https://.*console.aws.amazon.com/athena/", output.athena_console_url))
    error_message = "Athena console URL should be valid"
  }
}

# Test 7: AWS Account ID検証統合テスト
run "aws_account_validation_integration_test" {
  command = apply

  variables {
    project_name            = "integration-test"
    environment             = "dev"
    app                     = "analytics"
    logs_bucket_name        = "integration-test-dev-analytics-logs"
    logs_s3_prefix          = "test/logs"
    auto_create_bucket      = true
    expected_aws_account_id = "123456789012"
  }

  # AWS Account ID検証
  assert {
    condition     = data.aws_caller_identity.current.account_id != ""
    error_message = "AWS account ID should be retrieved"
  }

  # AWS Account ID厳密比較
  assert {
    condition     = data.aws_caller_identity.current.account_id == expected_aws_account_id
    error_message = "AWS account ID does not match expected account ID. Expected: ${expected_aws_account_id}, Actual: ${data.aws_caller_identity.current.account_id}"
  }

  # データソース確認
  assert {
    condition     = data.aws_region.current.name != ""
    error_message = "AWS region should be retrieved"
  }
}

# Test 8: リソース命名規則統合テスト
run "resource_naming_convention_integration_test" {
  command = apply

  variables {
    project_name       = "my-project"
    environment        = "stg"
    app                = "log-analytics"
    logs_bucket_name   = "my-project-stg-log-analytics-logs"
    logs_s3_prefix     = "staging/logs"
    auto_create_bucket = true
  }

  # リソース命名規則の確認
  assert {
    condition     = length(aws_s3_bucket.logs_bucket) > 0 && aws_s3_bucket.logs_bucket[0].bucket == "my-project-stg-log-analytics-logs"
    error_message = "S3 bucket name should follow project-env-app-logs pattern"
  }

  assert {
    condition     = aws_glue_catalog_database.main.name == "my_project_stg_log_analytics_logs"
    error_message = "Glue database name should follow project_env_app_logs pattern"
  }

  assert {
    condition     = aws_athena_workgroup.main.name == "my-project-stg-log-analytics"
    error_message = "Athena workgroup name should follow project-env-app pattern"
  }

  assert {
    condition     = aws_iam_role.athena_role.name == "my-project-stg-log-analytics-athena-role"
    error_message = "Athena role name should follow project-env-app-athena-role pattern"
  }

  assert {
    condition     = aws_iam_role.glue_crawler_role.name == "my-project-stg-log-analytics-glue-crawler-role"
    error_message = "Glue crawler role name should follow project-env-app-glue-crawler-role pattern"
  }

  # クローラー命名規則の確認
  assert {
    condition     = aws_glue_crawler.log_crawlers["django_web"].name == "my-project-stg-log-analytics-django-web-crawler"
    error_message = "Crawler name should follow project-env-app-logtype-crawler pattern"
  }
}
