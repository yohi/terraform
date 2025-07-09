# ==================================================
# ECS Monitoring モジュール - 基本機能テスト
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
  project_name = "test-project"
  environment  = "dev"
  app          = "webapp"

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
# 基本リソース作成テスト
# ==================================================

run "basic_resource_creation" {
  command = plan

  variables {
    slack_channel     = "#test-alerts"
    enable_monitoring = true
  }

  # EventBridge ルールの作成確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change != null
    error_message = "EventBridge rule should be created"
  }

  # CloudWatch ログ グループの作成確認
  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor != null
    error_message = "CloudWatch log group should be created"
  }

  # Lambda 関数の作成確認
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor != null
    error_message = "Lambda function should be created"
  }

  # Lambda IAM ロールの作成確認
  assert {
    condition     = aws_iam_role.lambda_role != null
    error_message = "Lambda IAM role should be created"
  }
}

# ==================================================
# 監視無効化テスト
# ==================================================

run "monitoring_disabled" {
  command = plan

  variables {
    enable_monitoring = false
  }

  # 監視無効時はリソースが作成されないことを確認
  assert {
    condition     = length(aws_cloudwatch_event_rule.ecs_instance_state_change) == 0
    error_message = "EventBridge rule should not be created when monitoring is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.ecs_agent_monitor) == 0
    error_message = "CloudWatch log group should not be created when monitoring is disabled"
  }

  assert {
    condition     = length(aws_lambda_function.ecs_agent_monitor) == 0
    error_message = "Lambda function should not be created when monitoring is disabled"
  }
}

# ==================================================
# リソース名生成テスト
# ==================================================

run "resource_name_generation" {
  command = plan

  variables {
    project_name      = "my-project"
    environment       = "prd"
    enable_monitoring = true
  }

  # EventBridge ルール名の確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].name == "my-project-prd-ecs-instance-state-change-rule"
    error_message = "EventBridge rule name should follow naming convention"
  }

  # Lambda 関数名の確認
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].function_name == "my-project-prd-ecs-agent-monitor"
    error_message = "Lambda function name should follow naming convention"
  }

  # CloudWatch ログ グループ名の確認
  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor[0].name == "/aws/events/my-project-prd-ecs-instance-state-change-rule"
    error_message = "CloudWatch log group name should follow naming convention"
  }
}

# ==================================================
# カスタムプレフィックステスト
# ==================================================

run "custom_prefix_test" {
  command = plan

  variables {
    resource_name_prefix = "custom-prefix"
    enable_monitoring    = true
  }

  # カスタムプレフィックスを使用したリソース名の確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].name == "custom-prefix-ecs-instance-state-change-rule"
    error_message = "EventBridge rule name should use custom prefix"
  }

  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].function_name == "custom-prefix-ecs-agent-monitor"
    error_message = "Lambda function name should use custom prefix"
  }
}

# ==================================================
# Lambda 設定テスト
# ==================================================

run "lambda_configuration" {
  command = plan

  variables {
    lambda_timeout    = 120
    lambda_runtime    = "python3.11"
    enable_monitoring = true
  }

  # Lambda タイムアウトの確認
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].timeout == 120
    error_message = "Lambda timeout should be set to 120 seconds"
  }

  # Lambda ランタイムの確認
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].runtime == "python3.11"
    error_message = "Lambda runtime should be set to python3.11"
  }
}

# ==================================================
# CloudWatch ログ設定テスト
# ==================================================

run "cloudwatch_log_configuration" {
  command = plan

  variables {
    log_retention_in_days = 90
    enable_monitoring     = true
  }

  # ログ保持期間の確認
  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor[0].retention_in_days == 90
    error_message = "CloudWatch log retention should be set to 90 days"
  }
}

# ==================================================
# タグ設定テスト
# ==================================================

run "tag_configuration" {
  command = plan

  variables {
    project_name = "tag-test"
    environment  = "stg"
    common_tags = {
      Owner = "test-team"
      Cost  = "development"
    }
    enable_monitoring = true
  }

  # EventBridge ルールのタグ確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].tags.Project == "tag-test"
    error_message = "EventBridge rule should have correct Project tag"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].tags.Environment == "stg"
    error_message = "EventBridge rule should have correct Environment tag"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].tags.ManagedBy == "Terraform"
    error_message = "EventBridge rule should have ManagedBy tag"
  }

  # カスタムタグの確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].tags.Owner == "test-team"
    error_message = "EventBridge rule should have custom Owner tag"
  }
}

# ==================================================
# 出力値テスト
# ==================================================

run "output_values" {
  command = plan

  variables {
    enable_monitoring = true
  }

  # 出力値が正しく設定されていることを確認
  assert {
    condition     = output.eventbridge_rule_name != null
    error_message = "EventBridge rule name output should not be null"
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name output should not be null"
  }

  assert {
    condition     = output.log_group_name != null
    error_message = "Log group name output should not be null"
  }

  assert {
    condition     = output.subscription_filter_name != null
    error_message = "Subscription filter name output should not be null"
  }

  assert {
    condition     = output.monitoring_enabled == true
    error_message = "Monitoring enabled output should be true"
  }
}

# ==================================================
# 監視無効時の出力値テスト
# ==================================================

run "output_values_monitoring_disabled" {
  command = plan

  variables {
    enable_monitoring = false
  }

  # 監視無効時は出力値がnullになることを確認
  assert {
    condition     = output.eventbridge_rule_name == null
    error_message = "EventBridge rule name output should be null when monitoring is disabled"
  }

  assert {
    condition     = output.lambda_function_name == null
    error_message = "Lambda function name output should be null when monitoring is disabled"
  }

  assert {
    condition     = output.monitoring_enabled == false
    error_message = "Monitoring enabled output should be false"
  }
}
