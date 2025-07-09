# ==================================================
# ECS Monitoring モジュール - モック設定
# ==================================================

# モックプロバイダーの設定
mock_provider "aws" {
  alias = "fake"

  # AWS caller identity のモック
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  # AWS region のモック
  mock_data "aws_region" {
    defaults = {
      name        = "ap-northeast-1"
      description = "Asia Pacific (Tokyo)"
    }
  }

  # EventBridge ルールのモック
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn           = "arn:aws:events:ap-northeast-1:123456789012:rule/test-ecs-instance-state-change-rule"
      name          = "test-ecs-instance-state-change-rule"
      description   = "Test ECS instance state change rule"
      event_pattern = "{\"source\":[\"aws.ecs\"],\"detail-type\":[\"ECS Container Instance State Change\"]}"
      state         = "ENABLED"
      tags          = {}
    }
  }

  # CloudWatch ログ グループのモック
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn               = "arn:aws:logs:ap-northeast-1:123456789012:log-group:/aws/events/test-ecs-instance-state-change-rule"
      name              = "/aws/events/test-ecs-instance-state-change-rule"
      retention_in_days = 30
      tags              = {}
    }
  }

  # EventBridge ターゲットのモック
  mock_resource "aws_cloudwatch_event_target" {
    defaults = {
      arn       = "arn:aws:logs:ap-northeast-1:123456789012:log-group:/aws/events/test-ecs-instance-state-change-rule"
      rule      = "test-ecs-instance-state-change-rule"
      target_id = "EcsInstanceStateChangeLogTarget"
    }
  }

  # Lambda 関数のモック
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:ap-northeast-1:123456789012:function:test-ecs-agent-monitor"
      function_name = "test-ecs-agent-monitor"
      role          = "arn:aws:iam::123456789012:role/test-ecs-agent-monitor-role"
      handler       = "lambda_function.lambda_handler"
      runtime       = "python3.9"
      timeout       = 60
      memory_size   = 128

      environment = [
        {
          variables = {
            SLACK_CHANNEL          = "#alerts"
            SLACK_TOKEN_SECRET_ARN = "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:slack-token-test"
          }
        }
      ]

      tags = {}
    }
  }

  # Lambda IAM ロールのモック
  mock_resource "aws_iam_role" {
    defaults = {
      arn                = "arn:aws:iam::123456789012:role/test-ecs-agent-monitor-role"
      name               = "test-ecs-agent-monitor-role"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"}}]}"
      tags               = {}
    }
  }

  # Lambda IAM ロールポリシーアタッチメントのモック
  mock_resource "aws_iam_role_policy_attachment" {
    defaults = {
      policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      role       = "test-ecs-agent-monitor-role"
    }
  }

  # Lambda IAM ロールポリシーのモック（SSM）
  mock_resource "aws_iam_role_policy" {
    defaults = {
      name   = "test-ecs-agent-monitor-role-ssm-policy"
      role   = "test-ecs-agent-monitor-role"
      policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"ssm:SendCommand\"],\"Resource\":[\"arn:aws:ec2:ap-northeast-1:123456789012:instance/*\",\"arn:aws:ssm:ap-northeast-1:123456789012:document/AWS-RunShellScript\"]}]}"
    }
  }

  # Lambda パーミッションのモック
  mock_resource "aws_lambda_permission" {
    defaults = {
      statement_id  = "AllowExecutionFromCloudWatch"
      action        = "lambda:InvokeFunction"
      function_name = "test-ecs-agent-monitor"
      principal     = "logs.ap-northeast-1.amazonaws.com"
      source_arn    = "arn:aws:logs:ap-northeast-1:123456789012:log-group:/aws/events/test-ecs-instance-state-change-rule:*"
    }
  }

  # CloudWatch ログ サブスクリプション フィルターのモック
  mock_resource "aws_cloudwatch_log_subscription_filter" {
    defaults = {
      arn             = "arn:aws:logs:ap-northeast-1:123456789012:log-group:/aws/events/test-ecs-instance-state-change-rule:subscription-filter:test-ecs-agent-monitor-filter"
      name            = "test-ecs-agent-monitor-filter"
      log_group_name  = "/aws/events/test-ecs-instance-state-change-rule"
      filter_pattern  = "{ $.detail.agentConnected is false }"
      destination_arn = "arn:aws:lambda:ap-northeast-1:123456789012:function:test-ecs-agent-monitor"
    }
  }

  # ローカルファイルのモック
  mock_resource "local_file" {
    defaults = {
      content  = "# Mock Lambda function code\nprint('Hello from mock Lambda')"
      filename = "/tmp/lambda_function.py"
    }
  }

  # null リソースのモック
  mock_resource "null_resource" {
    defaults = {
      id = "mock-null-resource"
    }
  }

  # アーカイブファイルのモック
  mock_data "archive_file" {
    defaults = {
      output_path = "/tmp/lambda_function.zip"
      type        = "zip"
    }
  }
}

# ==================================================
# モック設定の使用例
# ==================================================

# 基本的なモック設定を使用したテスト例
run "example_mock_usage" {
  command = plan

  # モックプロバイダーを使用
  providers = {
    aws = aws.fake
  }

  variables {
    project_name           = "mock-test"
    environment            = "dev"
    cluster_arn            = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/test-cluster"
    slack_token_secret_arn = "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:slack-token-test"
    common_tags = {
      Project     = "test-project"
      Environment = "dev"
      Purpose     = "testing"
      ManagedBy   = "Terraform"
      TestType    = "unit"
    }
    enable_monitoring = true
  }

  # モックデータを使用したアサーション例
  assert {
    condition     = aws_cloudwatch_event_rule.ecs_instance_state_change[0].state == "ENABLED"
    error_message = "EventBridge rule should be enabled"
  }

  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].runtime == "python3.9"
    error_message = "Lambda runtime should be python3.9"
  }

  assert {
    condition     = aws_cloudwatch_log_group.ecs_agent_monitor[0].retention_in_days == 30
    error_message = "Log retention should be 30 days"
  }
}

# ==================================================
# カスタムモック設定の例
# ==================================================

# 特定のテストケース用のカスタムモック設定
run "custom_mock_example" {
  command = plan

  # モックプロバイダーを使用
  providers = {
    aws = aws.fake
  }

  variables {
    project_name           = "custom-mock-test"
    environment            = "stg"
    cluster_arn            = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/custom-cluster"
    slack_token_secret_arn = "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:custom-slack-token"
    lambda_timeout         = 120
    lambda_runtime         = "python3.11"
    enable_monitoring      = true
  }

  # カスタム設定のアサーション
  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].timeout == 120
    error_message = "Lambda timeout should be 120 seconds"
  }

  assert {
    condition     = aws_lambda_function.ecs_agent_monitor[0].runtime == "python3.11"
    error_message = "Lambda runtime should be python3.11"
  }
}
