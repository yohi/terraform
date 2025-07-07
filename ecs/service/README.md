# ECS Service and Task Definition Terraform Module

このモジュールは、Amazon ECS サービスとタスク定義を作成するためのTerraformコードです。

## 機能

- ECSタスク定義の作成
- ECSサービスの作成
- IAMロール（実行ロール・タスクロール）の自動作成
- セキュリティグループの作成
- CloudWatchログの設定
- Auto Scaling設定
- ロードバランサーとの統合
- Execute Command対応
- デプロイメント設定（Circuit Breaker含む）

## 使用方法

### 基本的な使用例

```hcl
module "ecs_service" {
  source = "./ecs/service/terraform"

  project_name = "my-project"
  environment  = "stg"
  app          = "web"
  cluster_name = "my-project-stg-ecs"

  # コンテナ設定
  container_image = "nginx:latest"
  container_port  = 80
  desired_count   = 2

  common_tags = {
    Project     = "my-project"
    Environment = "stg"
    Owner       = "team-name"
    ManagedBy   = "Terraform"
    Terraform   = "true"
  }
}
```

### 高度な設定例（ALB統合+Auto Scaling）

```hcl
module "ecs_service" {
  source = "./ecs/service/terraform"

  project_name = "my-project"
  environment  = "prd"
  app          = "api"
  cluster_name = "my-project-prd-ecs"

  # VPC・ネットワーク設定
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # コンテナ設定
  container_image  = "my-account.dkr.ecr.ap-northeast-1.amazonaws.com/my-api:latest"
  container_port   = 8080
  task_cpu         = 512
  task_memory      = 1024
  container_cpu    = 512
  container_memory = 1024

  # 環境変数
  environment_variables = {
    ENV         = "production"
    LOG_LEVEL   = "warn"
    PORT        = "8080"
  }

  # シークレット
  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:ssm:ap-northeast-1:123456789012:parameter/my-project/prd/db-password"
    }
  ]

  # サービス設定
  desired_count   = 3
  launch_type     = "FARGATE"
  assign_public_ip = false

  # ロードバランサー統合
  target_group_arn              = module.alb.target_group_arn
  load_balancer_container_port  = 8080
  health_check_grace_period_seconds = 60

  # Auto Scaling設定
  enable_auto_scaling         = true
  min_capacity               = 2
  max_capacity               = 20
  target_cpu_utilization     = 70
  target_memory_utilization  = 80

  # ログ設定
  enable_logging        = true
  log_retention_in_days = 30

  common_tags = {
    Project     = "my-project"
    Environment = "prd"
    Owner       = "devops-team"
    ManagedBy   = "Terraform"
    Terraform   = "true"
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

## 入力変数

### 必須変数

| 変数名         | 説明               | 型       |
| -------------- | ------------------ | -------- |
| `project_name` | プロジェクト名     | `string` |
| `environment`  | 環境名             | `string` |
| `app`          | アプリケーション名 | `string` |
| `cluster_name` | ECSクラスター名    | `string` |

### 主要な設定変数

| 変数名                   | 説明                  | 型       | デフォルト値     |
| ------------------------ | --------------------- | -------- | ---------------- |
| `container_image`        | コンテナイメージ      | `string` | `"nginx:latest"` |
| `container_port`         | コンテナポート        | `number` | `80`             |
| `task_cpu`               | タスクCPU             | `number` | `256`            |
| `task_memory`            | タスクメモリ（MiB）   | `number` | `512`            |
| `desired_count`          | 希望するタスク数      | `number` | `1`              |
| `launch_type`            | 起動タイプ            | `string` | `"FARGATE"`      |
| `assign_public_ip`       | パブリックIP割り当て  | `bool`   | `true`           |
| `enable_auto_scaling`    | Auto Scaling有効化    | `bool`   | `false`          |
| `enable_logging`         | CloudWatchログ有効化  | `bool`   | `true`           |
| `enable_execute_command` | Execute Command有効化 | `bool`   | `true`           |

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
