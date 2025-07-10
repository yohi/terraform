# ==================================================
# ECS Monitoring モジュール - 統合テスト
# ==================================================

# 実際のAWSプロバイダーを使用
provider "aws" {
  region = "ap-northeast-1"
  # 実際のAWS認証情報を使用
}

# 共通変数の定義
variables {
  project_name = "integration-test"
  environment  = "dev"

  # 実際のECSクラスターARNを環境変数から取得
  cluster_arn = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/test-cluster"

  # 実際のSlack Token Secret ARNを環境変数から取得
  slack_token_secret_arn = "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:slack-token-test"

  common_tags = {
    Project     = "integration-test"
    Environment = "dev"
    Purpose     = "integration-testing"
    ManagedBy   = "Terraform"
  }
}

# ==================================================
# 統合テスト - リソース作成
# ==================================================

run "create_monitoring_resources" {
  command = apply

  variables {
    project_name          = "integration-test-20241201-1400"
    environment           = "dev"
    slack_channel         = "#test-alerts"
    log_retention_in_days = 7
    lambda_timeout        = 30
    enable_monitoring     = true
  }

  # EventBridge ルールの作成確認
  assert {
    condition     = output.eventbridge_rule_name != null
    error_message = "EventBridge rule should be created"
  }

  assert {
    condition     = output.eventbridge_rule_arn != null
    error_message = "EventBridge rule ARN should not be null"
  }

  # CloudWatch ログ グループの作成確認
  assert {
    condition     = output.log_group_name != null
    error_message = "CloudWatch log group should be created"
  }

  assert {
    condition     = output.log_group_arn != null
    error_message = "CloudWatch log group ARN should not be null"
  }

  # Lambda 関数の作成確認
  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function should be created"
  }

  assert {
    condition     = output.lambda_function_arn != null
    error_message = "Lambda function ARN should not be null"
  }

  # Lambda IAM ロールの作成確認
  assert {
    condition     = output.lambda_role_name != null
    error_message = "Lambda IAM role should be created"
  }

  assert {
    condition     = output.lambda_role_arn != null
    error_message = "Lambda IAM role ARN should not be null"
  }

  # サブスクリプション フィルターの作成確認
  assert {
    condition     = output.subscription_filter_name != null
    error_message = "Subscription filter should be created"
  }

  # 設定値の確認
  assert {
    condition     = output.monitoring_enabled == true
    error_message = "Monitoring should be enabled"
  }

  assert {
    condition     = output.slack_token_configured == true
    error_message = "Slack token should be configured"
  }

  assert {
    condition     = output.cluster_arn == var.cluster_arn
    error_message = "Cluster ARN should match input value"
  }
}

# ==================================================
# 統合テスト - リソース名の検証
# ==================================================

run "verify_resource_names" {
  command = plan

  variables {
    project_name      = "integration-test-20241201-1400"
    environment       = "dev"
    enable_monitoring = true
  }

  # リソース名の命名規則確認
  assert {
    condition     = can(regex("^integration-test-.*-dev-ecs-instance-state-change-rule$", output.eventbridge_rule_name))
    error_message = "EventBridge rule name should follow naming convention"
  }

  assert {
    condition     = can(regex("^integration-test-.*-dev-ecs-agent-monitor$", output.lambda_function_name))
    error_message = "Lambda function name should follow naming convention"
  }

  assert {
    condition     = can(regex("^/aws/events/integration-test-.*-dev-ecs-instance-state-change-rule$", output.log_group_name))
    error_message = "CloudWatch log group name should follow naming convention"
  }
}

# ==================================================
# 統合テスト - 監視無効化
# ==================================================

run "monitoring_disabled_integration" {
  command = apply

  variables {
    project_name      = "integration-test-disabled-20241201-1400"
    environment       = "dev"
    enable_monitoring = false
  }

  # 監視無効時は出力値がnullになることを確認
  assert {
    condition     = output.eventbridge_rule_name == null
    error_message = "EventBridge rule name should be null when monitoring is disabled"
  }

  assert {
    condition     = output.lambda_function_name == null
    error_message = "Lambda function name should be null when monitoring is disabled"
  }

  assert {
    condition     = output.log_group_name == null
    error_message = "Log group name should be null when monitoring is disabled"
  }

  assert {
    condition     = output.monitoring_enabled == false
    error_message = "Monitoring enabled should be false"
  }
}

# ==================================================
# 統合テスト - Lambda 環境変数の確認
# ==================================================

run "lambda_environment_variables" {
  command = plan

  variables {
    project_name      = "integration-test-20241201-1400"
    environment       = "dev"
    slack_channel     = "#custom-alerts"
    enable_monitoring = true
  }

  # Lambda 環境変数の設定確認（実際のリソースで確認）
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].environment[0].variables.SLACK_CHANNEL == "#custom-alerts"
    error_message = "Lambda should have correct SLACK_CHANNEL environment variable"
  }

  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].environment[0].variables.SLACK_TOKEN_SECRET_ARN == var.slack_token_secret_arn
    error_message = "Lambda should have correct SLACK_TOKEN_SECRET_ARN environment variable"
  }
}

# ==================================================
# 統合テスト - IAM ポリシーの確認
# ==================================================

run "iam_policy_verification" {
  command = plan

  variables {
    project_name      = "integration-test-20241201-1400"
    environment       = "dev"
    enable_monitoring = true
  }

  # Lambda IAM ロールの信頼ポリシー確認
  assert {
    condition     = can(regex("lambda.amazonaws.com", aws_iam_role.lambda_role[0].assume_role_policy))
    error_message = "Lambda IAM role should trust lambda.amazonaws.com"
  }

  # SSM ポリシーの確認
  assert {
    condition     = aws_iam_role_policy.lambda_ssm_policy[0] != null
    error_message = "Lambda should have SSM policy attached"
  }

  # Secrets Manager ポリシーの確認
  assert {
    condition     = aws_iam_role_policy.lambda_secrets_policy[0] != null
    error_message = "Lambda should have Secrets Manager policy attached"
  }
}

# ==================================================
# 統合テスト - EventBridge ルールの設定確認
# ==================================================

run "eventbridge_rule_configuration" {
  command = plan

  variables {
    project_name      = "integration-test-20241201-1400"
    environment       = "dev"
    enable_monitoring = true
  }

  # EventBridge ルールの状態確認
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].state == "ENABLED"
    error_message = "EventBridge rule should be enabled"
  }

  # イベントパターンの確認
  assert {
    condition     = can(regex("aws.ecs", aws_cloudwatch_event_rule.ecs_instance_state_change[0].event_pattern))
    error_message = "EventBridge rule should monitor ECS events"
  }

  assert {
    condition     = can(regex("ECS Container Instance State Change", aws_cloudwatch_event_rule.ecs_instance_state_change[0].event_pattern))
    error_message = "EventBridge rule should monitor container instance state changes"
  }
}

# ==================================================
# 統合テスト - CloudWatch ログ設定の確認
# ==================================================

run "cloudwatch_log_configuration_integration" {
  command = plan

  variables {
    project_name          = "integration-test-20241201-1400"
    environment           = "dev"
    log_retention_in_days = 14
    enable_monitoring     = true
  }

  # ログ保持期間の確認
  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor[0].retention_in_days == 14
    error_message = "CloudWatch log group should have correct retention period"
  }

  # サブスクリプション フィルターの設定確認
  assert {
    condition     = aws_cloudwatch_log_subscription_filter.ecs_agent_monitor[0].filter_pattern == "{ $.detail.agentConnected is false }"
    error_message = "Subscription filter should have correct filter pattern"
  }
}

# ==================================================
# 統合テスト - カスタム設定の確認
# ==================================================

run "custom_configuration_integration" {
  command = plan

  variables {
    project_name                = "integration-test-20241201-1400"
    environment                 = "dev"
    resource_name_prefix        = "custom-prefix-20241201-1400"
    log_group_name              = "/custom/log/group/path"
    subscription_filter_pattern = "{ $.detail.lastStatus = \"STOPPED\" }"
    enable_monitoring           = true
  }

  # カスタムプレフィックスの確認
  assert {
    condition     = can(regex("^custom-prefix-.*-ecs-instance-state-change-rule$", aws_cloudwatch_event_rule.ecs_instance_state_change[0].name))
    error_message = "EventBridge rule should use custom prefix"
  }

  # カスタムログ グループ名の確認
  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor[0].name == "/custom/log/group/path"
    error_message = "CloudWatch log group should use custom name"
  }

  # カスタムフィルターパターンの確認
  assert {
    condition     = aws_cloudwatch_log_subscription_filter.ecs_agent_monitor[0].filter_pattern == "{ $.detail.lastStatus = \"STOPPED\" }"
    error_message = "Subscription filter should use custom filter pattern"
  }
}

# ==================================================
# 統合テスト - クリーンアップ（監視有効）
# ==================================================

run "cleanup_monitoring_enabled" {
  command = destroy

  variables {
    project_name      = "integration-test-20241201-1400"
    environment       = "dev"
    enable_monitoring = true
  }
}

# ==================================================
# 統合テスト - クリーンアップ（監視無効）
# ==================================================

run "cleanup_monitoring_disabled" {
  command = destroy

  variables {
    project_name      = "integration-test-disabled-20241201-1400"
    environment       = "dev"
    enable_monitoring = false
  }
}

# ==================================================
# 統合テスト - クリーンアップ（カスタム設定）
# ==================================================

run "cleanup_custom_configuration" {
  command = destroy

  variables {
    project_name                = "integration-test-20241201-1400"
    environment                 = "dev"
    resource_name_prefix        = "custom-prefix-20241201-1400"
    log_group_name              = "/custom/log/group/path"
    subscription_filter_pattern = "{ $.detail.lastStatus = \"STOPPED\" }"
    enable_monitoring           = true
  }
}
