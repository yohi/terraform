# ⚙️ ECS Cluster Terraform Module

**最新の更新**: 2024年12月 - 完全動作確認済み

Amazon ECS（Elastic Container Service）クラスターを作成・管理するTerraformモジュールです。Container Insights、Execute Command、キャパシティプロバイダー、Service Connectを統合した企業レベルのコンテナオーケストレーション環境を構築します。

## 📋 概要

スケーラブルで監視可能なコンテナクラスター環境を構築します。Fargate・Fargate Spot対応、Container Insights統合、Execute Command機能、Service Connect、CloudWatch統合を自動化し、本格的なコンテナワークロードの運用を支援します。

## ✨ 2024年12月の特徴

### ⚙️ **クラスター管理機能**
- ✅ **Fargate・Fargate Spot** - コスト最適化・高可用性
- ✅ **Container Insights** - 統合監視・メトリクス収集
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 🔧 **運用機能**
- ✅ **Execute Command** - セキュアなコンテナアクセス
- ✅ **Service Connect** - サービスディスカバリー・通信
- ✅ **キャパシティプロバイダー** - 柔軟なリソース管理

### 📊 **監視・ログ機能**
- ✅ **CloudWatch統合** - ログ・メトリクス自動収集
- ✅ **統合タグ戦略** - 一貫したリソース管理
- ✅ **セキュリティログ** - KMS暗号化対応

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ECS Cluster Module                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        ┌────────▼─────────┐   ┌────────▼─────────┐   ┌────────▼─────────┐
        │   Cluster        │   │   Capacity       │   │   Monitoring     │
        │   Management     │   │   Providers      │   │   & Logging      │
        │                  │   │                  │   │                  │
        │ ├─ Cluster Core  │   │ ├─ Fargate       │   │ ├─ Container     │
        │ ├─ Naming        │   │ ├─ Fargate Spot  │   │ │   Insights      │
        │ ├─ Configuration │   │ ├─ Strategy      │   │ ├─ Execute CMD   │
        │ └─ Service       │   │ └─ Weights       │   │ └─ CloudWatch    │
        │   Connect        │   │                  │   │   Logs           │
        └──────────────────┘   └──────────────────┘   └──────────────────┘
                 │                      │                      │
                 └──────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
           ┌────────▼─────────┐ ┌────────▼─────────┐ ┌────────▼─────────┐
           │   Security       │ │   Service        │ │   Task           │
           │   & Access       │ │   Discovery      │ │   Orchestration  │
           │                  │ │                  │   │                  │
           │ ├─ IAM Roles     │ │ ├─ Service       │ │ ├─ Task Definition│
           │ ├─ KMS           │ │ │   Connect       │ │ ├─ Task Placement │
           │ ├─ Execute CMD   │ │ ├─ Cloud Map     │ │ ├─ Auto Scaling  │
           │ └─ Security      │ │ └─ Load Balancer │ │ └─ Health Checks │
           │   Groups         │ │   Integration    │ │                  │
           └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 🚀 主要機能

### ⚙️ **クラスター管理**
- **Fargate・Fargate Spot** - サーバーレスコンテナ実行環境
- **キャパシティプロバイダー** - 柔軟なリソース管理・コスト最適化
- **クラスター設定** - 命名規則・タグ管理・設定管理
- **統合タグ戦略** - プロジェクト・環境・コスト管理

### 📊 **監視・ログ機能**
- **Container Insights** - CPU・メモリ・ネットワーク監視
- **CloudWatch統合** - ログ・メトリクス自動収集
- **Execute Command** - セキュアなコンテナアクセス・デバッグ
- **KMS暗号化** - ログ・通信の暗号化

### 🔧 **運用機能**
- **Service Connect** - サービスディスカバリー・通信管理
- **Auto Scaling** - トラフィック対応・リソース最適化
- **Health Checks** - 自動回復・可用性確保
- **Task Placement** - 効率的なリソース配置

### 🌍 **高可用性・スケーラビリティ**
- **マルチAZ配置** - 障害耐性・可用性確保
- **スポットインスタンス** - コスト削減・柔軟性
- **動的スケーリング** - 負荷対応・リソース効率化
- **ロードバランシング** - トラフィック分散・パフォーマンス

## 🔧 前提条件

### 📋 必要な環境

| 要件             | バージョン | 説明                 |
| ---------------- | ---------- | -------------------- |
| **Terraform**    | >= 1.0     | 最新の構文・機能対応 |
| **AWS Provider** | >= 5.0     | 最新のECS機能        |
| **AWS CLI**      | >= 2.0     | 認証・操作用         |

### 🔑 必要な権限

| 権限                    | 説明                           |
| ----------------------- | ------------------------------ |
| **ECS Full Access**     | クラスター・サービス作成・管理 |
| **CloudWatch Logs**     | ログ管理・監視設定             |
| **IAM Role Management** | タスク実行ロール・権限管理     |
| **KMS Key Access**      | 暗号化設定（KMS使用時）        |

## 📊 設定項目

### 🔑 必須変数

| 変数名         | 説明                    | デフォルト値 | 必須 |
| -------------- | ----------------------- | ------------ | ---- |
| `project_name` | プロジェクト名          | `""`         | ✅    |
| `environment`  | 環境名（dev, stg, prd） | `""`         | ✅    |

### ⚙️ クラスター基本設定

| 変数名                           | 説明                     | デフォルト値 | 開発環境推奨 | 本番環境推奨 |
| -------------------------------- | ------------------------ | ------------ | ------------ | ------------ |
| `app`                            | アプリケーション名       | `""`         | アプリ名     | アプリ名     |
| `cluster_name`                   | カスタムクラスター名     | `""`         | 自動生成     | 自動生成     |
| `enable_container_insights`      | Container Insights有効化 | `true`       | `true`       | `true`       |
| `enable_execute_command_logging` | Execute Commandログ記録  | `true`       | `true`       | `true`       |
| `execute_command_kms_key_id`     | Execute Command用KMSキー | `""`         | -            | 専用KMSキー  |

### 🔧 キャパシティプロバイダー設定

| 変数名                               | 説明                     | デフォルト値                  | 開発環境推奨       | 本番環境推奨                  |
| ------------------------------------ | ------------------------ | ----------------------------- | ------------------ | ----------------------------- |
| `capacity_providers`                 | キャパシティプロバイダー | `["FARGATE", "FARGATE_SPOT"]` | `["FARGATE_SPOT"]` | `["FARGATE", "FARGATE_SPOT"]` |
| `default_capacity_provider_strategy` | デフォルト戦略           | 自動設定                      | Spot重視設定       | 安定性重視設定                |

### 📊 監視・ログ設定

| 変数名                               | 説明                    | デフォルト値         | 推奨設定             |
| ------------------------------------ | ----------------------- | -------------------- | -------------------- |
| `execute_command_log_group_name`     | Execute Commandログ群名 | 自動生成             | プロジェクト固有名   |
| `execute_command_log_retention_days` | ログ保持期間            | `7`                  | 開発:`7`, 本番:`30`  |
| `enable_execute_command_s3_bucket`   | S3ログ出力              | `false`              | 監査要件により`true` |
| `execute_command_s3_bucket_name`     | S3バケット名            | `""`                 | 監査用バケット       |
| `execute_command_s3_key_prefix`      | S3キープレフィックス    | `"execute-command/"` | 環境別プレフィックス |

### 🌐 Service Connect設定

| 変数名                      | 説明                          | デフォルト値 | 推奨設定                  |
| --------------------------- | ----------------------------- | ------------ | ------------------------- |
| `enable_service_connect`    | Service Connect有効化         | `false`      | マイクロサービス時`true`  |
| `service_connect_namespace` | Service Connectネームスペース | `""`         | 環境別ネームスペース      |
| `service_connect_log_level` | Service Connectログレベル     | `"info"`     | 開発:`debug`, 本番:`info` |

### 🏷️ タグ・命名設定

| 変数名         | 説明                                 | デフォルト値 |
| -------------- | ------------------------------------ | ------------ |
| `common_tags`  | すべてのリソースに適用される共通タグ | `{}`         |
| `cluster_tags` | クラスター固有タグ                   | `{}`         |

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "ecs_cluster" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "dev"
  app          = "web"

  # 監視設定
  enable_container_insights = true
  enable_execute_command_logging = true

  # 共通タグ
  common_tags = {
    Project     = "webapp"
    Environment = "dev"
    Owner       = "dev-team"
    ManagedBy   = "terraform"
  }
}
```

### 🏢 本番環境での使用例

```hcl
module "ecs_cluster_prod" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "prod"
  app          = "api"

  # 本番環境設定
  enable_container_insights = true
  enable_execute_command_logging = true
  execute_command_kms_key_id = "alias/webapp-prod-ecs-key"

  # キャパシティプロバイダー戦略（本番環境）
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 3
      base              = 2
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  ]

  # ログ設定
  execute_command_log_retention_days = 30
  enable_execute_command_s3_bucket = true
  execute_command_s3_bucket_name = "webapp-prod-ecs-logs"
  execute_command_s3_key_prefix = "execute-command/prod/"

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    BackupRequired = "true"
    CriticalService = "true"
  }
}
```

### 🔄 マイクロサービス環境での使用例

```hcl
module "ecs_cluster_microservices" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "microservices"
  environment  = "stg"
  app          = "platform"

  # マイクロサービス設定
  enable_container_insights = true
  enable_execute_command_logging = true

  # Service Connect設定
  enable_service_connect = true
  service_connect_namespace = "microservices-stg"
  service_connect_log_level = "debug"

  # キャパシティプロバイダー戦略
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 2
      base              = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 3
      base              = 0
    }
  ]

  # ログ設定
  execute_command_log_retention_days = 14
  execute_command_log_group_name = "/aws/ecs/microservices-stg-execute-command"

  # マイクロサービス用タグ
  common_tags = {
    Project     = "microservices"
    Environment = "stg"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
    Architecture = "microservices"
    ServiceConnect = "enabled"
  }
}
```

### 💰 コスト最適化の使用例

```hcl
module "ecs_cluster_cost_optimized" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "testapp"
  environment  = "dev"
  app          = "testing"

  # コスト最適化設定
  enable_container_insights = false  # コスト削減
  enable_execute_command_logging = true  # デバッグ用は維持

  # Fargate Spot重視設定
  capacity_providers = ["FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  ]

  # ログ設定（短期保持）
  execute_command_log_retention_days = 3
  enable_execute_command_s3_bucket = false

  # コスト最適化用タグ
  common_tags = {
    Project     = "testapp"
    Environment = "dev"
    Owner       = "dev-team"
    ManagedBy   = "terraform"
    CostOptimization = "enabled"
    Schedule    = "business-hours"
  }
}
```

### 🔐 セキュリティ強化の使用例

```hcl
module "ecs_cluster_secure" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "financial"
  environment  = "prod"
  app          = "core"

  # セキュリティ強化設定
  enable_container_insights = true
  enable_execute_command_logging = true
  execute_command_kms_key_id = "alias/financial-prod-ecs-key"

  # Fargate専用（セキュリティ優先）
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2
    }
  ]

  # 監査ログ設定
  execute_command_log_retention_days = 90
  enable_execute_command_s3_bucket = true
  execute_command_s3_bucket_name = "financial-prod-audit-logs"
  execute_command_s3_key_prefix = "ecs-execute-command/"

  # セキュリティ強化用タグ
  common_tags = {
    Project     = "financial"
    Environment = "prod"
    Owner       = "security-team"
    ManagedBy   = "terraform"
    SecurityLevel = "high"
    ComplianceRequired = "true"
    DataClassification = "sensitive"
  }
}
```

### 🎯 高パフォーマンスの使用例

```hcl
module "ecs_cluster_performance" {
  source = "./ecs/cluster/terraform"

  # プロジェクト基本設定
  project_name = "highperf"
  environment  = "prod"
  app          = "api"

  # パフォーマンス設定
  enable_container_insights = true
  enable_execute_command_logging = true

  # Fargate専用（パフォーマンス優先）
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 5  # 最低限の常時起動タスク
    }
  ]

  # Service Connect設定
  enable_service_connect = true
  service_connect_namespace = "highperf-prod"
  service_connect_log_level = "info"

  # ログ設定
  execute_command_log_retention_days = 30
  execute_command_log_group_name = "/aws/ecs/highperf-prod-execute-command"

  # パフォーマンス用タグ
  common_tags = {
    Project     = "highperf"
    Environment = "prod"
    Owner       = "performance-team"
    ManagedBy   = "terraform"
    Performance = "high"
    SLA         = "99.9"
    MonitoringLevel = "enhanced"
  }
}
```

## 🔧 キャパシティプロバイダー戦略

### 📊 戦略設定例

```hcl
# 開発環境（コスト重視）
default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
]

# ステージング環境（バランス重視）
default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  },
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
    base              = 0
  }
]

# 本番環境（安定性重視）
default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 3
    base              = 2
  },
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
]
```

### 🎯 戦略ガイドライン

| 環境                 | Fargate重み | Fargate Spot重み | Base設定 | 説明             |
| -------------------- | ----------- | ---------------- | -------- | ---------------- |
| **開発**             | 0           | 1                | 0        | 完全コスト最適化 |
| **ステージング**     | 1           | 2                | 1        | バランス重視     |
| **本番**             | 3           | 1                | 2        | 安定性重視       |
| **セキュリティ重視** | 1           | 0                | 2        | Fargate専用      |

## 🔍 監視・ログ設定

### 📊 Container Insights設定

```json
{
  "CloudWatchInsights": {
    "enabled": true,
    "logGroup": "/aws/ecs/containerinsights/${cluster_name}/performance",
    "metrics": [
      "CpuUtilized",
      "MemoryUtilized",
      "NetworkRxBytes",
      "NetworkTxBytes",
      "StorageReadBytes",
      "StorageWriteBytes"
    ]
  }
}
```

### 📈 CloudWatch Alarms設定例

```hcl
# CPU使用率アラーム
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = module.ecs_cluster.cluster_name
  }
}

# メモリ使用率アラーム
resource "aws_cloudwatch_metric_alarm" "ecs_memory_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = module.ecs_cluster.cluster_name
  }
}
```

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題                               | 原因                             | 解決方法                |
| ---------------------------------- | -------------------------------- | ----------------------- |
| **クラスターが作成されない**       | IAM権限・設定の問題              | ECS権限・設定確認       |
| **Container Insightsが動作しない** | CloudWatch権限の問題             | IAM権限確認             |
| **Execute Commandが使えない**      | タスク定義・IAM設定の問題        | タスク定義・IAM設定確認 |
| **Service Connectが動作しない**    | ネームスペース・設定の問題       | Cloud Map・設定確認     |
| **コンテナが起動しない**           | リソース・ネットワーク設定の問題 | CloudWatch Logs確認     |

### 🔍 デバッグ手順

```bash
# 1. クラスター状態確認
aws ecs describe-clusters --clusters ${CLUSTER_NAME}

# 2. サービス一覧確認
aws ecs list-services --cluster ${CLUSTER_NAME}

# 3. タスク状態確認
aws ecs list-tasks --cluster ${CLUSTER_NAME}

# 4. タスク詳細確認
aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks ${TASK_ARN}

# 5. Container Insights確認
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/containerinsights/${CLUSTER_NAME}"

# 6. Execute Commandログ確認
aws logs get-log-events \
  --log-group-name "/aws/ecs/execute-command/${CLUSTER_NAME}" \
  --log-stream-name ${LOG_STREAM_NAME}
```

### 🛠️ パフォーマンス最適化

```bash
# タスク配置確認
aws ecs describe-tasks \
  --cluster ${CLUSTER_NAME} \
  --query 'tasks[*].{TaskArn:taskArn,AvailabilityZone:availabilityZone,CapacityProviderName:capacityProviderName}'

# キャパシティプロバイダー使用率確認
aws ecs describe-capacity-providers \
  --capacity-providers FARGATE FARGATE_SPOT
```

## 📈 パフォーマンス最適化

### 🎯 環境別推奨設定

| 環境                 | Container Insights | Execute Command | Fargate比率 | Spot比率 | 説明             |
| -------------------- | ------------------ | --------------- | ----------- | -------- | ---------------- |
| **開発**             | 無効               | 有効            | 0%          | 100%     | 最大コスト削減   |
| **ステージング**     | 有効               | 有効            | 33%         | 67%      | バランス重視     |
| **本番**             | 有効               | 有効            | 75%         | 25%      | 安定性重視       |
| **セキュリティ重視** | 有効               | 有効            | 100%        | 0%       | 最大セキュリティ |

### 💾 リソース使用量最適化

```hcl
# 環境別設定
locals {
  cluster_configs = {
    dev = {
      container_insights = false
      capacity_providers = ["FARGATE_SPOT"]
      log_retention_days = 3
    }
    stg = {
      container_insights = true
      capacity_providers = ["FARGATE", "FARGATE_SPOT"]
      log_retention_days = 14
    }
    prod = {
      container_insights = true
      capacity_providers = ["FARGATE", "FARGATE_SPOT"]
      log_retention_days = 30
    }
  }
}
```

## 🔗 出力値

### ⚙️ 基本出力

| 出力名                  | 説明               |
| ----------------------- | ------------------ |
| `cluster_id`            | ECSクラスターID    |
| `cluster_name`          | ECSクラスター名    |
| `cluster_arn`           | ECSクラスターARN   |
| `cluster_configuration` | クラスター設定情報 |

### 🔧 運用出力

| 出力名                               | 説明                                   |
| ------------------------------------ | -------------------------------------- |
| `capacity_providers`                 | 設定されたキャパシティプロバイダー     |
| `default_capacity_provider_strategy` | デフォルトキャパシティプロバイダー戦略 |
| `execute_command_log_group_name`     | Execute Commandログ群名                |
| `execute_command_log_group_arn`      | Execute Commandログ群ARN               |

### 📊 監視出力

| 出力名                       | 説明                          |
| ---------------------------- | ----------------------------- |
| `container_insights_enabled` | Container Insights有効化状態  |
| `service_connect_namespace`  | Service Connectネームスペース |
| `aws_cli_commands`           | AWS CLI操作コマンド           |

## 🚀 CI/CD統合

### 🔄 GitHub Actions例

```yaml
name: Deploy to ECS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Update ECS service
      run: |
        aws ecs update-service \
          --cluster ${{ secrets.ECS_CLUSTER_NAME }} \
          --service ${{ secrets.ECS_SERVICE_NAME }} \
          --force-new-deployment
```

## 📝 ライセンス

このモジュールは[MIT License](LICENSE)の下で提供されています。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**テスト状況**: 全機能テスト済み
