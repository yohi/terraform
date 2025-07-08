# Analytics/Athena Validation Tests
# 入力変数のバリデーションルールをテスト

# Test 1: 有効な環境名の検証
run "valid_environment_names" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "prd"
    app                = "analytics"
    logs_bucket_name   = "test-prd-analytics-logs"
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }

  assert {
    condition     = var.environment == "prd"
    error_message = "Valid environment name should be accepted"
  }
}

# Test 2: 無効な環境名での失敗
run "invalid_environment_name" {
  command         = plan
  expect_failures = ["var.environment"]

  variables {
    project_name       = "test"
    environment        = "invalid"
    app                = "analytics"
    logs_bucket_name   = "test-invalid-analytics-logs"
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }
}

# Test 3: 空のプロジェクト名での失敗
run "empty_project_name" {
  command         = plan
  expect_failures = ["var.project_name"]

  variables {
    project_name       = ""
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }
}

# Test 4: 空のアプリケーション名での失敗
run "empty_app_name" {
  command         = plan
  expect_failures = ["var.app"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = ""
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }
}

# Test 5: 空のS3バケット名での失敗
run "empty_logs_bucket_name" {
  command         = plan
  expect_failures = ["var.logs_bucket_name"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = ""
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }
}

# Test 6: 空のS3プレフィックスでの失敗
run "empty_logs_s3_prefix" {
  command         = plan
  expect_failures = ["var.logs_s3_prefix"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = ""
    auto_create_bucket = true
  }
}

# Test 7: S3プレフィックスが'/'で終わる場合の失敗
run "logs_s3_prefix_ends_with_slash" {
  command         = plan
  expect_failures = ["var.logs_s3_prefix"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data/"
    auto_create_bucket = true
  }
}

# Test 8: 有効なAWSリージョンの検証
run "valid_aws_regions" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    aws_region         = "us-west-2"
    auto_create_bucket = true
  }

  assert {
    condition     = var.aws_region == "us-west-2"
    error_message = "Valid AWS region should be accepted"
  }
}

# Test 9: クローラースケジュール表現の検証
run "valid_crawler_schedule_expressions" {
  command = apply

  variables {
    project_name                = "test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "test-dev-analytics-logs"
    logs_s3_prefix              = "logs/data"
    enable_crawler_schedule     = true
    crawler_schedule_expression = "cron(0 1 * * ? *)"
    auto_create_bucket          = true
  }

  assert {
    condition     = var.crawler_schedule_expression == "cron(0 1 * * ? *)"
    error_message = "Valid cron expression should be accepted"
  }
}

# Test 10: 無効なクローラー最大同時実行数での失敗
run "invalid_crawler_max_concurrent_runs_high" {
  command         = plan
  expect_failures = ["var.crawler_max_concurrent_runs"]

  variables {
    project_name                = "test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "test-dev-analytics-logs"
    logs_s3_prefix              = "logs/data"
    crawler_max_concurrent_runs = 11
    auto_create_bucket          = true
  }
}

# Test 11: 無効なクローラー最大同時実行数での失敗（低い値）
run "invalid_crawler_max_concurrent_runs_low" {
  command         = plan
  expect_failures = ["var.crawler_max_concurrent_runs"]

  variables {
    project_name                = "test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "test-dev-analytics-logs"
    logs_s3_prefix              = "logs/data"
    crawler_max_concurrent_runs = 0
    auto_create_bucket          = true
  }
}

# Test 12: 有効なクローラー最大同時実行数の検証
run "valid_crawler_max_concurrent_runs" {
  command = apply

  variables {
    project_name                = "test"
    environment                 = "dev"
    app                         = "analytics"
    logs_bucket_name            = "test-dev-analytics-logs"
    logs_s3_prefix              = "logs/data"
    crawler_max_concurrent_runs = 5
    auto_create_bucket          = true
  }

  assert {
    condition     = var.crawler_max_concurrent_runs == 5
    error_message = "Valid crawler max concurrent runs should be accepted"
  }
}

# Test 13: 複数の有効な環境値の検証
run "multiple_valid_environments" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "stg"
    app                = "analytics"
    logs_bucket_name   = "test-stg-analytics-logs"
    logs_s3_prefix     = "logs/data"
    auto_create_bucket = true
  }

  assert {
    condition     = contains(["prd", "rls", "stg", "dev"], var.environment)
    error_message = "Environment should be one of the valid values"
  }
}

# Test 14: データ分類の検証
run "valid_data_classification" {
  command = apply

  variables {
    project_name        = "test"
    environment         = "dev"
    app                 = "analytics"
    logs_bucket_name    = "test-dev-analytics-logs"
    logs_s3_prefix      = "logs/data"
    data_classification = "confidential"
    auto_create_bucket  = true
  }

  assert {
    condition     = var.data_classification == "confidential"
    error_message = "Valid data classification should be accepted"
  }
}

# Test 15: 無効なデータ分類での失敗
run "invalid_data_classification" {
  command         = plan
  expect_failures = ["var.data_classification"]

  variables {
    project_name        = "test"
    environment         = "dev"
    app                 = "analytics"
    logs_bucket_name    = "test-dev-analytics-logs"
    logs_s3_prefix      = "logs/data"
    data_classification = "invalid"
    auto_create_bucket  = true
  }
}

# Test 16: 監視レベルの検証
run "valid_monitoring_levels" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "prd"
    app                = "analytics"
    logs_bucket_name   = "test-prd-analytics-logs"
    logs_s3_prefix     = "logs/data"
    monitoring_level   = "high"
    auto_create_bucket = true
  }

  assert {
    condition     = var.monitoring_level == "high"
    error_message = "Valid monitoring level should be accepted"
  }
}

# Test 17: 無効な監視レベルでの失敗
run "invalid_monitoring_level" {
  command         = plan
  expect_failures = ["var.monitoring_level"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    monitoring_level   = "invalid"
    auto_create_bucket = true
  }
}

# Test 18: 保持期間の検証
run "valid_retention_periods" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "prd"
    app                = "analytics"
    logs_bucket_name   = "test-prd-analytics-logs"
    logs_s3_prefix     = "logs/data"
    retention_period   = "7-years"
    auto_create_bucket = true
  }

  assert {
    condition     = var.retention_period == "7-years"
    error_message = "Valid retention period should be accepted"
  }
}

# Test 19: 無効な保持期間での失敗
run "invalid_retention_period" {
  command         = plan
  expect_failures = ["var.retention_period"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    retention_period   = "invalid"
    auto_create_bucket = true
  }
}

# Test 20: スケジュールの検証
run "valid_schedule" {
  command = apply

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    schedule           = "business-hours"
    auto_create_bucket = true
  }

  assert {
    condition     = var.schedule == "business-hours"
    error_message = "Valid schedule should be accepted"
  }
}

# Test 21: 無効なスケジュールでの失敗
run "invalid_schedule" {
  command         = plan
  expect_failures = ["var.schedule"]

  variables {
    project_name       = "test"
    environment        = "dev"
    app                = "analytics"
    logs_bucket_name   = "test-dev-analytics-logs"
    logs_s3_prefix     = "logs/data"
    schedule           = "invalid"
    auto_create_bucket = true
  }
}
