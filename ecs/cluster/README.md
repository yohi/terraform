# ECS Cluster Terraform Module

このモジュールは、Amazon ECS クラスターを作成するためのTerraformコードです。

## 機能

- ECSクラスターの作成
- Container Insightsの設定
- Execute Command機能の設定
- キャパシティプロバイダーの設定（FARGATE, FARGATE_SPOT）
- Service Connectの設定（オプション）
- CloudWatchログの設定

## 使用方法

### 基本的な使用例

```hcl
module "ecs_cluster" {
  source = "./ecs/cluster/terraform"

  project_name = "my-project"
  environment  = "stg"
  app          = "web"

  common_tags = {
    Project     = "my-project"
    Environment = "stg"
    Owner       = "team-name"
    Terraform   = "true"
  }
}
```

### 高度な設定例

```hcl
module "ecs_cluster" {
  source = "./ecs/cluster/terraform"

  project_name = "my-project"
  environment  = "prd"
  cluster_name = "production-cluster"  # オプション（指定しない場合は "my-project-prd-ecs" になります）

  # キャパシティプロバイダー戦略
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 4
      base              = 0
    }
  ]

  # Container Insights有効化
  enable_container_insights = true

  # Execute Command設定
  enable_execute_command_logging = true
  execute_command_kms_key_id     = "alias/aws/ecs"

  common_tags = {
    Project     = "my-project"
    Environment = "prd"
    Owner       = "devops-team"
    Terraform   = "true"
  }
}
```

## 入力変数

| 変数名                           | 説明                          | 型             | デフォルト値                  | 必須 |
| -------------------------------- | ----------------------------- | -------------- | ----------------------------- | ---- |
| `project_name`                   | プロジェクト名                | `string`       | -                             | ✓    |
| `environment`                    | 環境名                        | `string`       | -                             | ✓    |
| `app`                            | アプリケーション名            | `string`       | `""`                          | -    |
| `cluster_name`                   | ECSクラスター名               | `string`       | `""`                          | -    |
| `capacity_providers`             | キャパシティプロバイダー      | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` | -    |
| `enable_container_insights`      | Container Insights有効化      | `bool`         | `true`                        | -    |
| `enable_execute_command_logging` | Execute Commandログ記録有効化 | `bool`         | `true`                        | -    |

詳細な変数については `variables.tf` を参照してください。

## 出力値

| 出力名               | 説明                               |
| -------------------- | ---------------------------------- |
| `cluster_id`         | ECSクラスターID                    |
| `cluster_name`       | ECSクラスター名                    |
| `cluster_arn`        | ECSクラスターARN                   |
| `capacity_providers` | 設定されたキャパシティプロバイダー |

詳細な出力については `outputs.tf` を参照してください。

## 前提条件

- Terraform >= 1.0
- AWS Provider >= 5.0
- 適切なAWS認証情報の設定

## セキュリティ考慮事項

- Execute Command用のKMSキーを指定することを推奨
- CloudWatchログの保持期間を適切に設定
- 本番環境では適切なIAMロールとポリシーを設定

## リソース

このモジュールは以下のAWSリソースを作成します：

- `aws_ecs_cluster` - ECSクラスター
- `aws_ecs_cluster_capacity_providers` - キャパシティプロバイダー設定
- `aws_cloudwatch_log_group` - Execute Command用ロググループ（オプション）

## 注意事項

- クラスター削除時は、関連するサービスとタスクが停止していることを確認してください
- Container Insightsを有効にするとCloudWatchの課金が発生します
- FARGATE_SPOTを使用する場合、タスクが中断される可能性があります
