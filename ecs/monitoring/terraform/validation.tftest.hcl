# ==================================================
# ECS Monitoring モジュール - 入力検証テスト
# ==================================================

# モックプロバイダーを使用してテストを実行
provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "ap-northeast-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# 共通変数の定義
variables {
  project_name           = "test-project"
  cluster_arn            = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/test-cluster"
  slack_token_secret_arn = "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:slack-token-test"

  common_tags = {
    Project     = "test-project"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "Terraform"
  }
}

# ==================================================
# 環境変数（environment）のバリデーションテスト
# ==================================================

run "valid_environment_dev" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment dev should be valid"
  }
}

run "valid_environment_stg" {
  command = plan

  variables {
    environment       = "stg"
    enable_monitoring = true
  }

  assert {
    condition     = var.environment == "stg"
    error_message = "Environment stg should be valid"
  }
}

run "valid_environment_rls" {
  command = plan

  variables {
    environment       = "rls"
    enable_monitoring = true
  }

  assert {
    condition     = var.environment == "rls"
    error_message = "Environment rls should be valid"
  }
}

run "valid_environment_prd" {
  command = plan

  variables {
    environment       = "prd"
    enable_monitoring = true
  }

  assert {
    condition     = var.environment == "prd"
    error_message = "Environment prd should be valid"
  }
}

run "invalid_environment_production" {
  command = plan

  variables {
    environment       = "production"
    enable_monitoring = true
  }

  expect_failures = [
    "var.environment",
  ]
}

run "invalid_environment_test" {
  command = plan

  variables {
    environment       = "test"
    enable_monitoring = true
  }

  expect_failures = [
    "var.environment",
  ]
}

# ==================================================
# ログ保持期間（log_retention_in_days）のバリデーションテスト
# ==================================================

run "valid_log_retention_1_day" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 1
    enable_monitoring     = true
  }

  assert {
    condition     = var.log_retention_in_days == 1
    error_message = "Log retention 1 day should be valid"
  }
}

run "valid_log_retention_30_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 30
    enable_monitoring     = true
  }

  assert {
    condition     = var.log_retention_in_days == 30
    error_message = "Log retention 30 days should be valid"
  }
}

run "valid_log_retention_365_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 365
    enable_monitoring     = true
  }

  assert {
    condition     = var.log_retention_in_days == 365
    error_message = "Log retention 365 days should be valid"
  }
}

run "valid_log_retention_3653_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 3653
    enable_monitoring     = true
  }

  assert {
    condition     = var.log_retention_in_days == 3653
    error_message = "Log retention 3653 days should be valid"
  }
}

run "invalid_log_retention_2_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 2
    enable_monitoring     = true
  }

  expect_failures = [
    "var.log_retention_in_days",
  ]
}

run "invalid_log_retention_100_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 100
    enable_monitoring     = true
  }

  expect_failures = [
    "var.log_retention_in_days",
  ]
}

# ==================================================
# Lambda タイムアウト（lambda_timeout）のバリデーションテスト
# ==================================================

run "valid_lambda_timeout_1_second" {
  command = plan

  variables {
    environment       = "dev"
    lambda_timeout    = 1
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_timeout == 1
    error_message = "Lambda timeout 1 second should be valid"
  }
}

run "valid_lambda_timeout_60_seconds" {
  command = plan

  variables {
    environment       = "dev"
    lambda_timeout    = 60
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_timeout == 60
    error_message = "Lambda timeout 60 seconds should be valid"
  }
}

run "valid_lambda_timeout_900_seconds" {
  command = plan

  variables {
    environment       = "dev"
    lambda_timeout    = 900
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_timeout == 900
    error_message = "Lambda timeout 900 seconds should be valid"
  }
}

run "invalid_lambda_timeout_0_seconds" {
  command = plan

  variables {
    environment       = "dev"
    lambda_timeout    = 0
    enable_monitoring = true
  }

  expect_failures = [
    "var.lambda_timeout",
  ]
}

run "invalid_lambda_timeout_901_seconds" {
  command = plan

  variables {
    environment       = "dev"
    lambda_timeout    = 901
    enable_monitoring = true
  }

  expect_failures = [
    "var.lambda_timeout",
  ]
}

# ==================================================
# Lambda ランタイム（lambda_runtime）のバリデーションテスト
# ==================================================

run "valid_lambda_runtime_python38" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.8"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_runtime == "python3.8"
    error_message = "Lambda runtime python3.8 should be valid"
  }
}

run "valid_lambda_runtime_python39" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.9"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_runtime == "python3.9"
    error_message = "Lambda runtime python3.9 should be valid"
  }
}

run "valid_lambda_runtime_python310" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.10"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_runtime == "python3.10"
    error_message = "Lambda runtime python3.10 should be valid"
  }
}

run "valid_lambda_runtime_python311" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.11"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_runtime == "python3.11"
    error_message = "Lambda runtime python3.11 should be valid"
  }
}

run "invalid_lambda_runtime_python37" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.7"
    enable_monitoring = true
  }

  expect_failures = [
    "var.lambda_runtime",
  ]
}

run "invalid_lambda_runtime_python312" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "python3.12"
    enable_monitoring = true
  }

  expect_failures = [
    "var.lambda_runtime",
  ]
}

run "invalid_lambda_runtime_nodejs" {
  command = plan

  variables {
    environment       = "dev"
    lambda_runtime    = "nodejs18.x"
    enable_monitoring = true
  }

  expect_failures = [
    "var.lambda_runtime",
  ]
}

# ==================================================
# 必須変数のテスト
# ==================================================

run "required_project_name" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.project_name != ""
    error_message = "Project name should not be empty"
  }
}

run "required_cluster_arn" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.cluster_arn != ""
    error_message = "Cluster ARN should not be empty"
  }
}

run "required_slack_token_secret_arn" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.slack_token_secret_arn != ""
    error_message = "Slack token secret ARN should not be empty"
  }
}

# ==================================================
# オプション変数のデフォルト値テスト
# ==================================================

run "default_aws_region" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.aws_region == "ap-northeast-1"
    error_message = "Default AWS region should be ap-northeast-1"
  }
}

run "default_slack_channel" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.slack_channel == "#alerts"
    error_message = "Default Slack channel should be #alerts"
  }
}

run "default_log_retention" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.log_retention_in_days == 30
    error_message = "Default log retention should be 30 days"
  }
}

run "default_lambda_timeout" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_timeout == 60
    error_message = "Default Lambda timeout should be 60 seconds"
  }
}

run "default_lambda_runtime" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.lambda_runtime == "python3.9"
    error_message = "Default Lambda runtime should be python3.9"
  }
}

run "default_enable_monitoring" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = var.enable_monitoring == true
    error_message = "Default monitoring should be enabled"
  }
}

run "default_subscription_filter_pattern" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.subscription_filter_pattern == "{ $.detail.agentConnected is false }"
    error_message = "Default subscription filter pattern should match expected value"
  }
}

# ==================================================
# 空文字列のデフォルト値テスト
# ==================================================

run "default_app_empty" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.app == ""
    error_message = "Default app should be empty string"
  }
}

run "default_resource_name_prefix_empty" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.resource_name_prefix == ""
    error_message = "Default resource name prefix should be empty string"
  }
}

run "default_log_group_name_empty" {
  command = plan

  variables {
    environment       = "dev"
    enable_monitoring = true
  }

  assert {
    condition     = var.log_group_name == ""
    error_message = "Default log group name should be empty string"
  }
}
