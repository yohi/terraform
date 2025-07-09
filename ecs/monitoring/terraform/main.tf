# ==================================================
# ローカル変数
# ==================================================

locals {
  # リソース名のプレフィックス
  name_prefix = var.resource_name_prefix != "" ? var.resource_name_prefix : "${var.project_name}-${var.environment}"

  # EventBridge ルール名
  eventbridge_rule_name = "${local.name_prefix}-ecs-instance-state-change-rule"

  # CloudWatch ログ グループ名
  log_group_name = var.log_group_name != "" ? var.log_group_name : "/aws/events/${local.eventbridge_rule_name}"

  # Lambda 関数名
  lambda_function_name = "${local.name_prefix}-ecs-agent-monitor"

  # Lambda IAM ロール名
  lambda_role_name = "${local.name_prefix}-ecs-agent-monitor-role"

  # サブスクリプション フィルター名
  subscription_filter_name = "${local.name_prefix}-ecs-agent-monitor-filter"
}

# ==================================================
# データソース
# ==================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ==================================================
# EventBridge ルール
# ==================================================

resource "aws_cloudwatch_event_rule" "ecs_instance_state_change" {
  count       = var.enable_monitoring ? 1 : 0
  name        = local.eventbridge_rule_name
  description = "${var.project_name}のECSインスタンス状態変更取得ルール"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Container Instance State Change"]
    detail = {
      clusterArn = [var.cluster_arn]
    }
  })

  state = "ENABLED"

  tags = merge(
    var.common_tags,
    {
      Name      = local.eventbridge_rule_name
      ManagedBy = "Terraform"
    }
  )
}

# ==================================================
# CloudWatch ログ グループ
# ==================================================

resource "aws_cloudwatch_log_group" "ecs_agent_monitor" {
  count             = var.enable_monitoring ? 1 : 0
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = merge(
    var.common_tags,
    {
      Name      = local.log_group_name
      ManagedBy = "Terraform"
    }
  )
}

# ==================================================
# EventBridge ターゲット（CloudWatch ログ グループ）
# ==================================================

resource "aws_cloudwatch_event_target" "log_group" {
  count     = var.enable_monitoring ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ecs_instance_state_change[0].name
  target_id = "EcsInstanceStateChangeLogTarget"
  arn       = aws_cloudwatch_log_group.ecs_agent_monitor[0].arn
}

# ==================================================
# Lambda 実行用 IAM ロール
# ==================================================

resource "aws_iam_role" "lambda_role" {
  count = var.enable_monitoring ? 1 : 0
  name  = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name      = local.lambda_role_name
      ManagedBy = "Terraform"
    }
  )
}

# ==================================================
# Lambda 基本実行ポリシー
# ==================================================

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count      = var.enable_monitoring ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==================================================
# Lambda SSM 実行ポリシー
# ==================================================

resource "aws_iam_role_policy" "lambda_ssm_policy" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.lambda_role_name}-ssm-policy"
  role  = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:document/AWS-RunShellScript"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# ==================================================
# Lambda Secrets Manager アクセス ポリシー
# ==================================================

resource "aws_iam_role_policy" "lambda_secrets_policy" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.lambda_role_name}-secrets-policy"
  role  = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.slack_token_secret_arn
      }
    ]
  })
}

# ==================================================
# Lambda 関数
# ==================================================

resource "aws_lambda_function" "ecs_agent_monitor" {
  count            = var.enable_monitoring ? 1 : 0
  filename         = data.archive_file.lambda_zip[0].output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_role[0].arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256

  environment {
    variables = {
      SLACK_CHANNEL          = var.slack_channel
      SLACK_TOKEN_SECRET_ARN = var.slack_token_secret_arn
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name      = local.lambda_function_name
      ManagedBy = "Terraform"
    }
  )
}

# ==================================================
# Lambda 関数のソースコード
# ==================================================

resource "local_file" "lambda_source" {
  count    = var.enable_monitoring ? 1 : 0
  filename = "${path.module}/lambda_source/index.py"
  content  = <<-EOF
"""
ECSエージェントの状態を確認し、停止していたら起動させる
"""
import base64
import gzip
import json
import os
import logging

import boto3
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 環境変数
SLACK_CHANNEL = os.environ['SLACK_CHANNEL']
SLACK_TOKEN_SECRET_ARN = os.environ['SLACK_TOKEN_SECRET_ARN']

# クライアント初期化
ssm = boto3.client('ssm')
secrets_client = boto3.client('secretsmanager')


def get_slack_token() -> str:
    """
    AWS Secrets Manager からSlack トークンを取得する

    Returns:
        str: Slack Bot Token
    """
    try:
        response = secrets_client.get_secret_value(SecretId=SLACK_TOKEN_SECRET_ARN)
        secret = json.loads(response['SecretString'])
        return secret['slack_token']
    except Exception as e:
        logger.error(f"Error retrieving Slack token from Secrets Manager: {e}")
        raise


# Slack クライアント初期化
slack_client = WebClient(token=get_slack_token())


def send_slack_notification(message: str) -> None:
    """
    Slackに通知を送信する

    Args:
        message: 送信するメッセージ
    """
    try:
        response = slack_client.chat_postMessage(
            channel=SLACK_CHANNEL,
            text=message,
            username='ECS Agent Monitor',
            icon_emoji=':robot_face:'
        )
        logger.info(f"Slack notification sent successfully: {response['ts']}")
    except SlackApiError as e:
        logger.error(f"Error sending Slack notification: {e.response['error']}")
        raise


def lambda_handler(event, context) -> dict:
    """
    Lambda関数

    Args:
        event: Lambdaイベント
        context: Lambdaコンテキスト

    Returns:
        dict: レスポンス
    """
    try:
        # base64 デコード
        decoded_data = base64.b64decode(event['awslogs']['data'])

        # gzip 解凍
        decompressed_data = gzip.decompress(decoded_data)
        json_data = json.loads(decompressed_data)

        # ログイベントからinstance_idを取得
        message = json.loads(json_data['logEvents'][0]['message'])
        instance_id = message['detail']['ec2InstanceId']
        cluster_arn = message['detail']['clusterArn']

        logger.info(f"Processing ECS agent monitoring for instance: {instance_id}")

        # インスタンスで実行するコマンド
        commands = []

        # ECSエージェントの状態を確認
        commands.append('sudo systemctl status ecs')

        # ECSエージェントが停止していたら起動させる
        restart_command = '''
            if [ $? -ne 0 ]; then
                echo "ECS agent is not running, attempting to restart..."
                sudo systemctl start ecs
                if [ $? -eq 0 ]; then
                    echo "SUCCESS: ECS agent restarted successfully"
                else
                    echo "FAILED: Could not restart ECS agent"
                fi
            else
                echo "ECS agent is already running"
            fi
        '''
        commands.append(restart_command)

        # SSMコマンドを実行
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName='AWS-RunShellScript',
            Parameters={
                'commands': commands,
            },
        )

        command_id = response['Command']['CommandId']
        logger.info(f"SSM command sent with ID: {command_id}")

        # 初期通知をSlackに送信
        cluster_name = cluster_arn.split('/')[-1]
        initial_message = f":warning: ECS Agent Monitor Alert\\n\\n" \
                         f"**Instance ID:** {instance_id}\\n" \
                         f"**Cluster:** {cluster_name}\\n" \
                         f"**Status:** ECS agent disconnected - attempting restart\\n" \
                         f"**Command ID:** {command_id}"

        send_slack_notification(initial_message)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'ECS agent monitoring completed successfully',
                'instance_id': instance_id,
                'command_id': command_id
            })
        }

    except Exception as e:
        logger.error(f"Error processing ECS agent monitoring: {str(e)}")

        # エラー通知をSlackに送信
        error_message = f":red_circle: ECS Agent Monitor Error\\n\\n" \
                       f"**Error:** {str(e)}\\n" \
                       f"**Instance ID:** {instance_id if 'instance_id' in locals() else 'Unknown'}"

        try:
            send_slack_notification(error_message)
        except:
            logger.error("Failed to send error notification to Slack")

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
EOF
}

# ==================================================
# Lambda requirements.txt
# ==================================================

resource "local_file" "lambda_requirements" {
  count    = var.enable_monitoring ? 1 : 0
  filename = "${path.module}/lambda_source/requirements.txt"
  content  = <<-EOF
slack-sdk>=3.19.0
boto3>=1.28.0
EOF
}

# ==================================================
# Lambda 依存関係のインストール
# ==================================================

resource "null_resource" "install_lambda_dependencies" {
  count = var.enable_monitoring ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      rm -rf lambda_package
      mkdir -p lambda_package
      cp lambda_source/index.py lambda_package/
      cp lambda_source/requirements.txt lambda_package/
      cd lambda_package
      pip install -r requirements.txt -t .
      rm requirements.txt
    EOT
  }

  depends_on = [local_file.lambda_source, local_file.lambda_requirements]

  triggers = {
    source_hash       = local_file.lambda_source[0].content_md5
    requirements_hash = local_file.lambda_requirements[0].content_md5
  }
}

# ==================================================
# Lambda デプロイ用 ZIP ファイル
# ==================================================

data "archive_file" "lambda_zip" {
  count       = var.enable_monitoring ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_package"
  output_path = "${path.module}/lambda_deployment.zip"
  depends_on  = [null_resource.install_lambda_dependencies]
}

# ==================================================
# Lambda 実行許可（CloudWatch Logs から）
# ==================================================

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.enable_monitoring ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_agent_monitor[0].function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ecs_agent_monitor[0].arn}:*"
}

# ==================================================
# CloudWatch ログ サブスクリプション フィルター
# ==================================================

resource "aws_cloudwatch_log_subscription_filter" "ecs_agent_monitor" {
  count           = var.enable_monitoring ? 1 : 0
  name            = local.subscription_filter_name
  log_group_name  = aws_cloudwatch_log_group.ecs_agent_monitor[0].name
  filter_pattern  = var.subscription_filter_pattern
  destination_arn = aws_lambda_function.ecs_agent_monitor[0].arn
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
}
