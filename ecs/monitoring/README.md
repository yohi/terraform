# ECSエージェント死活監視システム

このTerraformモジュールは、ECSエージェントの死活監視を自動化するシステムを構築します。ECSエージェントが停止した場合、自動的に再起動を試行し、結果をSlackに通知します。

## 概要

このシステムは以下の流れで動作します：

1. **EventBridge**: ECSコンテナインスタンスの状態変更イベントを監視
2. **CloudWatch Logs**: イベントをログとして記録
3. **Lambda関数**: ECSエージェントが停止した場合の自動復旧処理
4. **Systems Manager**: EC2インスタンスでのECSエージェント再起動コマンド実行
5. **Slack通知**: Slack SDKを使用した通知

## アーキテクチャ

```
ECS Container Instance → EventBridge → CloudWatch Logs → Lambda → SSM → Slack
```

## 前提条件

- AWS CLI v2 がインストールされていること
- Terraform v1.0以上がインストールされていること
- Python 3.x および pip がインストールされていること（Lambda依存関係のインストール用）
- ECSクラスターが既に作成されていること
- EC2インスタンスにSSMエージェントがインストールされていること
- Slack Bot Token（xoxb-で始まるトークン）が取得済みであること

## 使用方法

### 1. 設定ファイルの準備

```bash
# 設定例ファイルをコピー
cp terraform.tfvars.example terraform.tfvars

# 設定ファイルを編集
vi terraform.tfvars
```

### 2. 必要な設定項目

```hcl
# 必須設定
project_name = "your-project"
environment  = "dev"
cluster_arn  = "arn:aws:ecs:region:account:cluster/cluster-name"
slack_token_secret_arn = "arn:aws:secretsmanager:region:account:secret:slack-token-secret-name"

# オプション設定
slack_channel         = "#alerts"
log_retention_in_days = 30
lambda_timeout        = 60
```

### 3. デプロイ

```bash
# 初期化
terraform init

# プラン確認
terraform plan

# 適用
terraform apply
```

**注意**: 初回デプロイ時、Lambda関数の依存関係（slack-sdk）が自動的にインストールされます。この処理には数分かかる場合があります。

### 4. 削除

```bash
terraform destroy
```

## 設定パラメータ

### 基本設定

| パラメータ               | 説明                                                                  | デフォルト値 | 必須 |
| ------------------------ | --------------------------------------------------------------------- | ------------ | ---- |
| `project_name`           | プロジェクト名                                                        | -            | ✓    |
| `environment`            | 環境名 (prd, rls, stg, dev)                                           | -            | ✓    |
| `cluster_arn`            | 監視対象のECSクラスターARN                                            | -            | ✓    |
| `slack_token_secret_arn` | Slack Bot Token を格納している AWS Secrets Manager のシークレット ARN | -            | ✓    |

### オプション設定

| パラメータ                    | 説明                       | デフォルト値                           |
| ----------------------------- | -------------------------- | -------------------------------------- |
| `aws_region`                  | AWSリージョン              | `ap-northeast-1`                       |
| `resource_name_prefix`        | リソース名のプレフィックス | `{project_name}-{environment}`         |
| `slack_channel`               | Slack通知先チャンネル名    | `#alerts`                              |
| `log_retention_in_days`       | CloudWatchログの保持期間   | `30`                                   |
| `lambda_timeout`              | Lambda関数のタイムアウト   | `60`                                   |
| `lambda_runtime`              | Lambda関数のランタイム     | `python3.9`                            |
| `subscription_filter_pattern` | ログフィルターパターン     | `{ $.detail.agentConnected is false }` |
| `enable_monitoring`           | 監視の有効/無効            | `true`                                 |

## 出力値

このモジュールは以下の値を出力します：

- `eventbridge_rule_name` - EventBridgeルール名
- `lambda_function_name` - Lambda関数名
- `log_group_name` - CloudWatchログ グループ名
- `subscription_filter_name` - サブスクリプションフィルター名

## 監視対象

このシステムは以下のイベントを監視します：

- ECSコンテナインスタンスの状態変更
- ECSエージェントの接続状態 (`agentConnected: false`)

## 自動復旧処理

ECSエージェントが停止した場合、以下の処理が実行されます：

1. ECSエージェントの状態確認: `sudo systemctl status ecs`
2. 停止している場合の再起動: `sudo systemctl start ecs`
3. 処理結果のSlack通知（Slack SDKを使用）

### Slack通知の内容

システムは以下の2種類の通知を送信します：

**1. 監視アラート通知**
```
⚠️ ECS Agent Monitor Alert

Instance ID: i-1234567890abcdef0
Cluster: my-cluster
Status: ECS agent disconnected - attempting restart
Command ID: 12345678-1234-1234-1234-123456789012
```

**2. エラー通知**
```
🔴 ECS Agent Monitor Error

Error: [エラー内容]
Instance ID: i-1234567890abcdef0
```

## 主な機能

- **自動復旧**: ECSエージェントが停止した場合、自動的に再起動を試行
- **Slack通知**: Slack SDKを使用したリッチな通知（絵文字、フォーマット対応）
- **エラーハンドリング**: 処理エラー時の自動通知
- **柔軟な設定**: 監視の有効/無効切り替え、ログ保持期間の設定など
- **セキュリティ**: 最小限の権限でIAMロールとポリシーを設定
- **依存関係管理**: requirements.txtを使用した自動パッケージ管理（slack-sdk >= 3.19.0）

## 権限

このシステムでは以下のIAM権限が必要です：

### Lambda実行ロール
- CloudWatch Logs への書き込み権限
- Systems Manager SendCommand の実行権限

### EC2インスタンス
- Systems Manager エージェントの実行権限
- ECSエージェントの管理権限

## トラブルシューティング

### ECSエージェントが再起動しない場合

1. EC2インスタンスでSSMエージェントが動作していることを確認
2. Lambda関数のログを確認
3. ECSエージェントの設定を確認

### Slack通知が送信されない場合

1. Slack Bot Tokenが正しいことを確認
2. Botがチャンネルに追加されていることを確認
3. Lambda関数の環境変数を確認
4. ネットワーク設定を確認

### Slack Bot Tokenの取得方法

1. [Slack API](https://api.slack.com/apps)でアプリを作成
2. 「OAuth & Permissions」から「Bot Token Scopes」に以下の権限を追加：
   - `chat:write`
   - `chat:write.public`
3. 「Install App」からワークスペースにインストール
4. 「Bot User OAuth Token」（xoxb-で始まるトークン）を取得

### CloudWatch Logsにイベントが記録されない場合

1. EventBridgeルールが有効であることを確認
2. ECSクラスターARNが正しいことを確認
3. CloudWatch Logsの権限を確認

## 参考資料

- [AWS ECS Agent 接続解除に関するトラブルシューティング](https://repost.aws/ja/knowledge-center/ecs-agent-disconnected-linux2-ami)
- [CloudWatch Alarmによるコマンド実行](https://dev.classmethod.jp/articles/run-command-triggerd-by-cloudwatch-alarm/)
- [ECS Container Instance State Change Events](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html)

## ライセンス

このプロジェクトは社内利用のためのものです。
