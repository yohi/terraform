# 🚀 ECS Service and Task Definition Terraform Module

**最新の更新**: 2024年12月 - 完全動作確認済み

Amazon ECS サービスとタスク定義を作成・管理するTerraformモジュールです。IAMロール、セキュリティグループ、CloudWatchログ、Auto Scaling、ロードバランサー統合を自動化し、本格的なコンテナワークロードの運用を支援します。

## 📋 概要

スケーラブルで監視可能なECSサービス環境を構築します。タスク定義、サービス設定、IAMロール、セキュリティグループ、CloudWatch統合、Auto Scaling、ロードバランサー連携を自動化し、DevOpsワークフローを最適化します。

## ✨ 2024年12月の特徴

### 🚀 **サービス・タスク管理**
- ✅ **タスク定義・サービス** - 一括作成・管理
- ✅ **IAM統合** - 実行ロール・タスクロール自動作成
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 🔧 **運用機能**
- ✅ **Auto Scaling** - CPU・メモリベース自動スケーリング
- ✅ **Circuit Breaker** - 障害対応・自動復旧
- ✅ **Execute Command** - セキュアなコンテナアクセス

### 🌍 **統合機能**
- ✅ **ロードバランサー統合** - ALB・NLB対応
- ✅ **CloudWatch統合** - ログ・メトリクス自動収集
- ✅ **統合タグ戦略** - 一貫したリソース管理

## 🚀 主要機能

### 🚀 **サービス・タスク管理**
- **タスク定義管理** - CPU・メモリ・ネットワーク設定
- **サービス管理** - 希望タスク数・配置戦略・デプロイメント
- **IAM統合** - 実行ロール・タスクロール自動作成・管理
- **セキュリティグループ** - 適切なアクセス制御・通信許可

### 🔧 **運用・監視機能**
- **CloudWatch統合** - ログ・メトリクス自動収集・監視
- **Auto Scaling** - CPU・メモリ使用率ベース自動スケーリング
- **Health Check** - アプリケーション健全性監視・自動復旧
- **Execute Command** - セキュアなコンテナアクセス・デバッグ

### 🌍 **統合・デプロイメント**
- **ロードバランサー統合** - ALB・NLB との統合・トラフィック分散
- **Circuit Breaker** - 障害検出・自動復旧・サービス保護
- **Rolling Update** - ゼロダウンタイムデプロイメント
- **Service Connect** - サービス間通信・ディスカバリー

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "ecs_service" {
  source = "./ecs/service/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "dev"
  app          = "web"
  cluster_name = "webapp-dev-ecs"

  # コンテナ設定
  container_image = "nginx:latest"
  container_port  = 80
  desired_count   = 2

  # 基本ネットワーク設定
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # 共通タグ
  common_tags = {
    Project     = "webapp"
    Environment = "dev"
    Owner       = "dev-team"
    ManagedBy   = "terraform"
  }
}
```

### 🏢 本番環境での使用例（ALB統合+Auto Scaling）

```hcl
module "ecs_service_prod" {
  source = "./ecs/service/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "prod"
  app          = "api"
  cluster_name = "webapp-prod-ecs"

  # VPC・ネットワーク設定
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-private1", "subnet-private2"]

  # コンテナ設定（本番環境）
  container_image  = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/webapp-api:latest"
  container_port   = 8080
  task_cpu         = 1024
  task_memory      = 2048
  container_cpu    = 1024
  container_memory = 2048

  # 環境変数
  environment_variables = {
    ENV         = "production"
    LOG_LEVEL   = "warn"
    PORT        = "8080"
    NODE_ENV    = "production"
  }

  # シークレット（Parameter Store）
  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:ssm:ap-northeast-1:123456789012:parameter/webapp/prod/db-password"
    },
    {
      name      = "API_KEY"
      valueFrom = "arn:aws:ssm:ap-northeast-1:123456789012:parameter/webapp/prod/api-key"
    }
  ]

  # サービス設定（本番環境）
  desired_count    = 5
  launch_type      = "FARGATE"
  assign_public_ip = false

  # ロードバランサー統合
  target_group_arn                    = module.alb.target_group_arn
  load_balancer_container_port        = 8080
  health_check_grace_period_seconds   = 120

  # Auto Scaling設定
  enable_auto_scaling         = true
  min_capacity               = 3
  max_capacity               = 50
  target_cpu_utilization     = 70
  target_memory_utilization  = 80

  # ログ設定
  enable_logging        = true
  log_retention_in_days = 90

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    CriticalService = "true"
  }
}
```

### カスタムコンテナ定義を使用する場合

```hcl
module "ecs_service" {
  source = "./ecs/service/terraform"

  project_name = "my-project"
  environment  = "stg"
  app          = "complex-app"
  cluster_name = "my-project-stg-ecs"

  # カスタムコンテナ定義
  container_definitions = [
    {
      name      = "web"
      image     = "nginx:latest"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-project-stg-complex-app"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "web"
        }
      }
    },
    {
      name      = "app"
      image     = "my-app:latest"
      cpu       = 384
      memory    = 768
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "8080"
        }
      ]
    }
  ]

  # タスクリソース
  task_cpu    = 512
  task_memory = 1024

  common_tags = {
    Project     = "my-project"
    Environment = "stg"
    Owner       = "team-name"
    Terraform   = "true"
  }
}
```

## 📊 設定項目

### 🔑 必須変数

| 変数名         | 説明                    | デフォルト値 | 必須 |
| -------------- | ----------------------- | ------------ | ---- |
| `project_name` | プロジェクト名          | `""`         | ✅    |
| `environment`  | 環境名（dev, stg, prd） | `""`         | ✅    |
| `app`          | アプリケーション名      | `""`         | ✅    |
| `cluster_name` | ECSクラスター名         | `""`         | ✅    |

### 🐳 コンテナ・タスク設定

| 変数名             | 説明                | デフォルト値     | 開発環境推奨       | 本番環境推奨       |
| ------------------ | ------------------- | ---------------- | ------------------ | ------------------ |
| `container_image`  | コンテナイメージ    | `"nginx:latest"` | 開発用イメージ     | ECRイメージ        |
| `container_port`   | コンテナポート      | `80`             | アプリポート       | アプリポート       |
| `task_cpu`         | タスクCPU           | `256`            | `256`              | `1024` 以上        |
| `task_memory`      | タスクメモリ（MiB） | `512`            | `512`              | `2048` 以上        |
| `container_cpu`    | コンテナCPU         | `0`              | タスクCPUと同等    | タスクCPUと同等    |
| `container_memory` | コンテナメモリ      | `0`              | タスクメモリと同等 | タスクメモリと同等 |

### 🚀 サービス設定

| 変数名                   | 説明                  | デフォルト値 | 開発環境推奨 | 本番環境推奨 |
| ------------------------ | --------------------- | ------------ | ------------ | ------------ |
| `desired_count`          | 希望タスク数          | `1`          | `1-2`        | `3-5`        |
| `launch_type`            | 起動タイプ            | `"FARGATE"`  | `"FARGATE"`  | `"FARGATE"`  |
| `assign_public_ip`       | パブリックIP割り当て  | `true`       | `true`       | `false`      |
| `enable_execute_command` | Execute Command有効化 | `true`       | `true`       | `true`       |

### 🔧 Auto Scaling設定

| 変数名                      | 説明               | デフォルト値 | 推奨設定            |
| --------------------------- | ------------------ | ------------ | ------------------- |
| `enable_auto_scaling`       | Auto Scaling有効化 | `false`      | 本番環境では`true`  |
| `min_capacity`              | 最小タスク数       | `1`          | 開発:`1`, 本番:`3`  |
| `max_capacity`              | 最大タスク数       | `10`         | 開発:`5`, 本番:`50` |
| `target_cpu_utilization`    | 目標CPU使用率      | `70`         | `70`                |
| `target_memory_utilization` | 目標メモリ使用率   | `80`         | `80`                |

### 🌐 ネットワーク設定

| 変数名               | 説明                         | デフォルト値 | 推奨設定               |
| -------------------- | ---------------------------- | ------------ | ---------------------- |
| `vpc_id`             | VPC ID                       | `""`         | 既存VPC ID             |
| `subnet_ids`         | サブネットIDリスト           | `[]`         | プライベートサブネット |
| `security_group_ids` | セキュリティグループIDリスト | `[]`         | 適切なSG               |

### 📊 ログ・監視設定

| 変数名                  | 説明                 | デフォルト値 | 推奨設定               |
| ----------------------- | -------------------- | ------------ | ---------------------- |
| `enable_logging`        | CloudWatchログ有効化 | `true`       | `true`                 |
| `log_retention_in_days` | ログ保持期間         | `7`          | 開発:`7`, 本番:`30-90` |
| `log_group_name`        | ログ群名             | 自動生成     | プロジェクト固有名     |

### 🏷️ タグ設定

| 変数名                   | 説明                                 | デフォルト値 |
| ------------------------ | ------------------------------------ | ------------ |
| `common_tags`            | すべてのリソースに適用される共通タグ | `{}`         |
| `desired_count`          | 希望するタスク数                     | `number`     | `1`         |
| `launch_type`            | 起動タイプ                           | `string`     | `"FARGATE"` |
| `assign_public_ip`       | パブリックIP割り当て                 | `bool`       | `true`      |
| `enable_auto_scaling`    | Auto Scaling有効化                   | `bool`       | `false`     |
| `enable_logging`         | CloudWatchログ有効化                 | `bool`       | `true`      |
| `enable_execute_command` | Execute Command有効化                | `bool`       | `true`      |

詳細な変数については `variables.tf` を参照してください。

## 出力値

| 出力名                | 説明                     |
| --------------------- | ------------------------ |
| `service_name`        | ECSサービス名            |
| `task_definition_arn` | ECSタスク定義ARN         |
| `security_group_id`   | セキュリティグループID   |
| `execution_role_arn`  | タスク実行ロールARN      |
| `task_role_arn`       | タスクロールARN          |
| `log_group_name`      | CloudWatchロググループ名 |
| `container_name`      | メインコンテナ名         |

詳細な出力については `outputs.tf` を参照してください。

## 前提条件

- Terraform >= 1.0
- AWS Provider >= 5.0
- ECSクラスターが既に存在すること
- 適切なAWS認証情報の設定

## リソース

このモジュールは以下のAWSリソースを作成します：

- `aws_ecs_task_definition` - ECSタスク定義
- `aws_ecs_service` - ECSサービス
- `aws_iam_role` - タスク実行ロール・タスクロール（指定しない場合）
- `aws_iam_role_policy` - IAMポリシー
- `aws_security_group` - セキュリティグループ
- `aws_cloudwatch_log_group` - CloudWatchロググループ
- `aws_appautoscaling_target` - Auto Scalingターゲット（有効時）
- `aws_appautoscaling_policy` - Auto Scalingポリシー（有効時）

## 使用パターン

### 1. 単純なWebアプリケーション
- Fargateを使用
- パブリックサブネットにデプロイ
- ALBと統合

### 2. マイクロサービス
- プライベートサブネットにデプロイ
- Service Discoveryと組み合わせ
- Auto Scaling有効

### 3. バッチ処理
- スケジューリングと組み合わせ
- 一時的な実行

## セキュリティ考慮事項

- 本番環境ではパブリックIP割り当てを無効にすることを推奨
- 適切なセキュリティグループルールの設定
- シークレット情報はParameter StoreまたはSecrets Managerを使用
- Execute Commandは必要な場合のみ有効化

## テスト

### 統合テストの実行

このモジュールには、実際のAWSリソースを使用した統合テストが含まれています。統合テストを実行する前に、以下の準備が必要です：

**⚠️ 警告**: 統合テストは実際のAWSリソースを作成し、コストが発生する可能性があります。

#### 前提条件

1. **AWS認証情報の設定**
   ```bash
   # AWS CLI設定
   aws configure

   # または環境変数
   export AWS_ACCESS_KEY_ID=your-access-key
   export AWS_SECRET_ACCESS_KEY=your-secret-key
   export AWS_DEFAULT_REGION=ap-northeast-1
   ```

2. **ネットワークリソースの準備**
   統合テストには既存のVPCとサブネットが必要です。以下のいずれかの方法で設定してください：

   **方法1: 環境変数を使用**
   ```bash
   export TF_VAR_vpc_id=vpc-your-actual-vpc-id
   export TF_VAR_subnet_ids='["subnet-your-subnet-1", "subnet-your-subnet-2"]'
   ```

   **方法2: terraform.tfvars ファイルを作成**
   ```hcl
   # ecs/service/terraform/terraform.tfvars
   vpc_id     = "vpc-your-actual-vpc-id"
   subnet_ids = ["subnet-your-subnet-1", "subnet-your-subnet-2"]
   ```

3. **ECSクラスターの作成**
   ```bash
   aws ecs create-cluster --cluster-name test-cluster
   ```

#### テストの実行

```bash
# テストディレクトリに移動
cd ecs/service/terraform

# 統合テストを実行
terraform test -file=integration.tftest.hcl
```

#### 利用可能なテストケース

- **基本的なECSサービス作成**: `create_ecs_service`
- **フル機能テスト**: `create_service_with_features` (Auto Scaling, ログ設定含む)
- **最小構成テスト**: `test_minimal_configuration`
- **タグ設定テスト**: `test_tags_integration`
- **自動生成名テスト**: `test_auto_generated_name`
- **リソースクリーンアップテスト**: `test_resource_cleanup`

#### クリーンアップ

テスト完了後は、作成されたリソースを削除してください：

```bash
# ECSクラスターの削除
aws ecs delete-cluster --cluster test-cluster

# 作成されたリソースの確認・削除
aws ecs list-services --cluster test-cluster
aws logs describe-log-groups --log-group-name-prefix /ecs/test-
```

### 単体テスト

単体テストは実際のAWSリソースを作成せずに実行できます：

```bash
# 基本的なテスト
terraform test -file=basic.tftest.hcl

# バリデーションテスト
terraform test -file=validation.tftest.hcl

# モックテスト
terraform test -file=mocks.tftest.hcl
```

## 注意事項

- タスク定義の変更時は、サービスが自動的に新しいタスクをデプロイします
- Auto Scalingを有効にする場合は適切なメトリクス監視を設定してください
- ロードバランサーと統合する場合は、ヘルスチェック設定を適切に設定してください
