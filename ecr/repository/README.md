# 🐳 ECR Repository Terraform Module

**最新の更新**: 2024年12月 - 完全動作確認済み

Amazon ECR（Elastic Container Registry）リポジトリを作成・管理するTerraformモジュールです。単一・複数リポジトリ対応、ライフサイクル管理、セキュリティ設定を自動化します。

## 📋 概要

企業レベルのコンテナレジストリ環境を構築します。ライフサイクルポリシー、セキュリティスキャン、暗号化、クロスアカウントアクセス、レプリケーションを統合管理し、DevOpsワークフローを最適化します。

## ✨ 2024年12月の特徴

### 🐳 **コンテナレジストリ機能**
- ✅ **単一・複数リポジトリ** - 一括作成・管理
- ✅ **ライフサイクル管理** - 自動クリーンアップ・コスト最適化
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 🔐 **セキュリティ機能**
- ✅ **脆弱性スキャン** - プッシュ時自動スキャン
- ✅ **暗号化設定** - AES256・KMS暗号化
- ✅ **アクセス制御** - IAMベースのきめ細かい権限管理

### 🌍 **高可用性・運用**
- ✅ **レプリケーション** - 複数リージョン対応
- ✅ **プル経由キャッシュ** - パフォーマンス向上
- ✅ **統合タグ戦略** - 一貫したリソース管理

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ECR Repository Module                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        ┌────────▼─────────┐   ┌────────▼─────────┐   ┌────────▼─────────┐
        │   Repository     │   │   Lifecycle      │   │   Security       │
        │   Management     │   │   Management     │   │   Configuration  │
        │                  │   │                  │   │                  │
        │ ├─ Single/Multi  │   │ ├─ Auto Cleanup  │   │ ├─ Vuln Scanning │
        │ ├─ Naming        │   │ ├─ Age Limits    │   │ ├─ Encryption    │
        │ ├─ Tagging       │   │ ├─ Count Limits  │   │ ├─ Access Control│
        │ └─ Configuration │   │ └─ Custom Rules  │   │ └─ Cross Account │
        └──────────────────┘   └──────────────────┘   └──────────────────┘
                 │                      │                      │
                 └──────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
           ┌────────▼─────────┐ ┌────────▼─────────┐ ┌────────▼─────────┐
           │   Replication    │ │   Pull Through   │ │   Push/Pull      │
           │   Management     │ │   Cache          │ │   Commands       │
           │                  │ │                  │ │                  │
           │ ├─ Multi-Region  │ │ ├─ Performance   │ │ ├─ Docker Push   │
           │ ├─ Cross Account │ │ ├─ Cost Savings  │ │ ├─ Docker Pull   │
           │ ├─ Async Sync    │ │ ├─ Upstream      │ │ ├─ AWS CLI      │
           │ └─ Permissions   │ │ └─ Caching       │ │ └─ Automation    │
           └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 🚀 主要機能

### 🐳 **リポジトリ管理**
- **単一・複数リポジトリ** - 一括作成・設定管理
- **命名規則** - 一貫したプロジェクト・環境ベース命名
- **イメージタグ管理** - MUTABLE/IMMUTABLE設定
- **統合タグ戦略** - プロジェクト・環境・コスト管理

### 🔄 **ライフサイクル管理**
- **自動クリーンアップ** - 古いイメージの自動削除
- **カスタムルール** - 柔軟なポリシー設定
- **コスト最適化** - ストレージ使用量の自動最適化
- **タグベース管理** - 本番・開発環境別保持期間

### 🔐 **セキュリティ・コンプライアンス**
- **脆弱性スキャン** - プッシュ時自動スキャン
- **暗号化設定** - AES256・KMS暗号化選択
- **アクセス制御** - IAMベースのきめ細かい権限
- **クロスアカウント** - 安全な組織間共有

### 🌍 **高可用性・パフォーマンス**
- **リージョン間レプリケーション** - 災害対策・レイテンシ最適化
- **プル経由キャッシュ** - パフォーマンス向上・コスト削減
- **プッシュ・プル自動化** - CI/CDパイプライン統合
- **モニタリング統合** - CloudWatch・Mackerel連携

## 🔧 前提条件

### 📋 必要な環境

| 要件 | バージョン | 説明 |
|------|------------|------|
| **Terraform** | >= 1.0 | 最新の構文・機能対応 |
| **AWS Provider** | >= 5.0 | 最新のECR機能 |
| **AWS CLI** | >= 2.0 | 認証・イメージ操作 |

### 🔑 必要な権限

| 権限 | 説明 |
|------|------|
| **ECR Full Access** | リポジトリ作成・管理 |
| **IAM Policy Management** | アクセス権限設定 |
| **KMS Key Management** | 暗号化設定（KMS使用時） |

## 📊 設定項目

### 🔑 必須変数

| 変数名 | 説明 | デフォルト値 | 必須 |
|--------|------|-------------|------|
| `project_name` | プロジェクト名 | `""` | ✅ |
| `environment` | 環境名（dev, stg, prd） | `""` | ✅ |

### 🐳 リポジトリ基本設定

| 変数名 | 説明 | デフォルト値 | 開発環境推奨 | 本番環境推奨 |
|--------|------|-------------|-------------|-------------|
| `app` | アプリケーション名 | `""` | アプリ名 | アプリ名 |
| `repository_name` | カスタムリポジトリ名 | `""` | 自動生成 | 自動生成 |
| `image_tag_mutability` | タグ変更可能性 | `"MUTABLE"` | `"MUTABLE"` | `"IMMUTABLE"` |
| `scan_on_push` | プッシュ時スキャン | `true` | `true` | `true` |
| `encryption_type` | 暗号化タイプ | `"AES256"` | `"AES256"` | `"KMS"` |
| `kms_key_id` | KMSキーID | `""` | - | 専用KMSキー |

### 🔄 ライフサイクル管理

| 変数名 | 説明 | デフォルト値 | 開発環境推奨 | 本番環境推奨 |
|--------|------|-------------|-------------|-------------|
| `enable_lifecycle_policy` | ライフサイクルポリシー有効化 | `true` | `true` | `true` |
| `untagged_image_count_limit` | タグなしイメージ保持数 | `10` | `5` | `3` |
| `tagged_image_count_limit` | タグ付きイメージ保持数 | `20` | `10` | `50` |
| `image_age_limit_days` | イメージ保持期間（日） | `30` | `14` | `90` |
| `lifecycle_policy_rules` | カスタムライフサイクルルール | `""` | カスタム設定 | 複雑なルール |

### 🔐 セキュリティ・アクセス制御

| 変数名 | 説明 | デフォルト値 | 推奨設定 |
|--------|------|-------------|----------|
| `enable_repository_policy` | リポジトリポリシー有効化 | `false` | クロスアカウント時`true` |
| `allowed_principals` | アクセス許可プリンシパル | `[]` | 必要なアカウント・ロール |
| `allowed_actions` | 許可アクション | `[]` | 最小権限の原則 |
| `enable_force_delete` | 強制削除許可 | `false` | 開発環境のみ`true` |

### 🌍 レプリケーション・キャッシュ

| 変数名 | 説明 | デフォルト値 | 推奨設定 |
|--------|------|-------------|----------|
| `enable_replication` | レプリケーション有効化 | `false` | 本番環境では`true` |
| `replication_destinations` | レプリケーション先リージョン | `[]` | 複数リージョン |
| `enable_pull_through_cache` | プル経由キャッシュ | `false` | パフォーマンス重視時`true` |
| `upstream_registry_url` | アップストリームレジストリURL | `""` | DockerHub等 |

### 📊 複数リポジトリ設定

| 変数名 | 説明 | デフォルト値 | 推奨設定 |
|--------|------|-------------|----------|
| `repositories` | 複数リポジトリ定義 | `[]` | 詳細設定オブジェクト |
| `repository_configs` | 共通設定テンプレート | `{}` | 環境別設定 |

### 🏷️ タグ・命名設定

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `common_tags` | すべてのリソースに適用される共通タグ | `{}` |
| `naming_prefix` | 命名プレフィックス | `""` |
| `naming_suffix` | 命名サフィックス | `""` |

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "ecr_repository" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "dev"
  app          = "frontend"

  # リポジトリ設定
  scan_on_push = true
  encryption_type = "AES256"

  # ライフサイクル設定
  enable_lifecycle_policy = true
  untagged_image_count_limit = 5
  tagged_image_count_limit = 10
  image_age_limit_days = 14

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
module "ecr_repository_prod" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "prod"
  app          = "api"

  # セキュリティ設定（本番環境）
  image_tag_mutability = "IMMUTABLE"
  scan_on_push = true
  encryption_type = "KMS"
  kms_key_id = "alias/webapp-prod-ecr-key"

  # ライフサイクル設定（本番環境）
  enable_lifecycle_policy = true
  untagged_image_count_limit = 3
  tagged_image_count_limit = 50
  image_age_limit_days = 90

  # レプリケーション設定
  enable_replication = true
  replication_destinations = [
    "us-east-1",
    "us-west-2",
    "ap-southeast-1"
  ]

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

### 🔄 複数リポジトリの使用例

```hcl
module "ecr_repositories_multi" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "microservices"
  environment  = "stg"

  # 複数リポジトリ定義
  repositories = [
    {
      name                 = "microservices-stg-frontend"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = "AES256"
      kms_key_id          = ""
      lifecycle_policy = {
        untagged_count_limit = 5
        tagged_count_limit   = 15
        age_limit_days       = 21
      }
    },
    {
      name                 = "microservices-stg-backend"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = "AES256"
      kms_key_id          = ""
      lifecycle_policy = {
        untagged_count_limit = 3
        tagged_count_limit   = 10
        age_limit_days       = 14
      }
    },
    {
      name                 = "microservices-stg-worker"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
      encryption_type      = "AES256"
      kms_key_id          = ""
      lifecycle_policy = {
        untagged_count_limit = 2
        tagged_count_limit   = 5
        age_limit_days       = 7
      }
    }
  ]

  # 共通設定
  enable_lifecycle_policy = true

  # ステージング環境用タグ
  common_tags = {
    Project     = "microservices"
    Environment = "stg"
    Owner       = "qa-team"
    ManagedBy   = "terraform"
    TestEnv     = "true"
  }
}
```

### 🌐 クロスアカウントアクセスの使用例

```hcl
module "ecr_shared_repository" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "shared"
  environment  = "prod"
  app          = "base-images"

  # セキュリティ設定
  image_tag_mutability = "IMMUTABLE"
  scan_on_push = true
  encryption_type = "KMS"
  kms_key_id = "alias/shared-ecr-key"

  # クロスアカウントアクセス設定
  enable_repository_policy = true
  allowed_principals = [
    "arn:aws:iam::123456789012:root",  # 開発アカウント
    "arn:aws:iam::987654321098:root",  # 本番アカウント
    "arn:aws:iam::555666777888:root"   # テストアカウント
  ]
  allowed_actions = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:DescribeImages",
    "ecr:GetRepositoryPolicy"
  ]

  # 長期保持設定
  enable_lifecycle_policy = true
  untagged_image_count_limit = 1
  tagged_image_count_limit = 100
  image_age_limit_days = 365

  # 共有リポジトリ用タグ
  common_tags = {
    Project     = "shared"
    Environment = "prod"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
    SharedResource = "true"
    CostCenter  = "platform"
  }
}
```

### 🔧 カスタムライフサイクルポリシーの使用例

```hcl
module "ecr_custom_lifecycle" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "webapp"
  environment  = "prod"
  app          = "api"

  # カスタムライフサイクルポリシー
  enable_lifecycle_policy = true
  lifecycle_policy_rules = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "本番リリースイメージを100個保持"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 100
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "開発用イメージを10個保持"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "feature-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "古いイメージを30日で削除"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countNumber = 30
          countUnit   = "days"
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "タグなしイメージを1個保持"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    LifecycleManaged = "true"
  }
}
```

### 🌍 高可用性・レプリケーションの使用例

```hcl
module "ecr_ha_repository" {
  source = "./ecr/repository/terraform"

  # プロジェクト基本設定
  project_name = "global-app"
  environment  = "prod"
  app          = "frontend"

  # 高可用性設定
  image_tag_mutability = "IMMUTABLE"
  scan_on_push = true
  encryption_type = "KMS"
  kms_key_id = "alias/global-app-ecr-key"

  # レプリケーション設定
  enable_replication = true
  replication_destinations = [
    "us-east-1",      # 北米東部
    "us-west-2",      # 北米西部
    "eu-west-1",      # ヨーロッパ
    "ap-southeast-1", # アジア太平洋
    "ap-northeast-1"  # 日本
  ]

  # プル経由キャッシュ設定
  enable_pull_through_cache = true
  upstream_registry_url = "docker.io"

  # 災害対策用ライフサイクル設定
  enable_lifecycle_policy = true
  untagged_image_count_limit = 2
  tagged_image_count_limit = 200
  image_age_limit_days = 180

  # グローバル本番環境用タグ
  common_tags = {
    Project     = "global-app"
    Environment = "prod"
    Owner       = "global-devops"
    ManagedBy   = "terraform"
    GlobalService = "true"
    DR_Required = "true"
    CostCenter  = "global-ops"
  }
}
```

## 🔧 Docker操作コマンド

### 📥 ログイン・認証

```bash
# ECRへのログイン
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}

# プロファイル指定でのログイン
aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}
```

### 🏗️ イメージビルド・プッシュ

```bash
# イメージビルド
docker build -t ${PROJECT_NAME}-${ENV}-${APP} .

# イメージタグ付け
docker tag ${PROJECT_NAME}-${ENV}-${APP}:latest \
  ${ECR_REGISTRY_URL}/${PROJECT_NAME}-${ENV}-${APP}:latest

# イメージプッシュ
docker push ${ECR_REGISTRY_URL}/${PROJECT_NAME}-${ENV}-${APP}:latest

# 複数タグでのプッシュ
docker tag ${PROJECT_NAME}-${ENV}-${APP}:latest \
  ${ECR_REGISTRY_URL}/${PROJECT_NAME}-${ENV}-${APP}:v1.0.0
docker push ${ECR_REGISTRY_URL}/${PROJECT_NAME}-${ENV}-${APP}:v1.0.0
```

### 📦 イメージ取得・管理

```bash
# イメージ一覧取得
aws ecr describe-images --repository-name ${PROJECT_NAME}-${ENV}-${APP}

# イメージプル
docker pull ${ECR_REGISTRY_URL}/${PROJECT_NAME}-${ENV}-${APP}:latest

# イメージ削除
aws ecr batch-delete-image \
  --repository-name ${PROJECT_NAME}-${ENV}-${APP} \
  --image-ids imageTag=v1.0.0
```

## 🔍 監視・メトリクス

### 📊 CloudWatch統合

```json
{
  "MetricName": "RepositoryImageCount",
  "Namespace": "AWS/ECR",
  "Dimensions": [
    {
      "Name": "RepositoryName",
      "Value": "${PROJECT_NAME}-${ENV}-${APP}"
    }
  ]
}
```

### 📈 監視設定例

```hcl
# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "ecr_image_count" {
  alarm_name          = "${var.project_name}-${var.environment}-ecr-image-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RepositoryImageCount"
  namespace           = "AWS/ECR"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors ECR image count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    RepositoryName = module.ecr_repository.repository_name
  }
}
```

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題 | 原因 | 解決方法 |
|------|------|----------|
| **ログインできない** | AWS認証・権限の問題 | IAM権限・AWS CLI設定確認 |
| **プッシュできない** | リポジトリが存在しない | リポジトリ作成・名前確認 |
| **イメージが見つからない** | タグ・リポジトリ名の問題 | タグ名・リポジトリ名確認 |
| **スキャンが動作しない** | スキャン設定の問題 | `scan_on_push` 設定確認 |
| **ライフサイクルポリシーが動作しない** | ポリシー設定の問題 | JSONシンタックス・ルール確認 |

### 🔍 デバッグ手順

```bash
# 1. リポジトリ確認
aws ecr describe-repositories --repository-names ${REPO_NAME}

# 2. イメージ一覧確認
aws ecr describe-images --repository-name ${REPO_NAME}

# 3. ライフサイクルポリシー確認
aws ecr get-lifecycle-policy --repository-name ${REPO_NAME}

# 4. リポジトリポリシー確認
aws ecr get-repository-policy --repository-name ${REPO_NAME}

# 5. スキャン結果確認
aws ecr describe-image-scan-findings --repository-name ${REPO_NAME} --image-id imageTag=latest
```

### 🛠️ 設定調整のガイドライン

**パフォーマンス最適化:**
```hcl
# 高パフォーマンス設定
enable_replication = true
replication_destinations = ["us-east-1", "us-west-2"]
enable_pull_through_cache = true
```

**コスト最適化:**
```hcl
# 低コスト設定
enable_lifecycle_policy = true
untagged_image_count_limit = 1
tagged_image_count_limit = 5
image_age_limit_days = 7
```

**セキュリティ強化:**
```hcl
# 高セキュリティ設定
image_tag_mutability = "IMMUTABLE"
scan_on_push = true
encryption_type = "KMS"
enable_repository_policy = true
```

## 📈 パフォーマンス最適化

### 🎯 ライフサイクルポリシー最適化

| 環境 | タグなし保持数 | タグ付き保持数 | 保持期間 | 説明 |
|------|----------------|----------------|----------|------|
| **開発** | 1-3 | 5-10 | 7-14日 | 頻繁な変更・短期保持 |
| **ステージング** | 2-5 | 10-20 | 14-30日 | テスト用・中期保持 |
| **本番** | 3-5 | 20-100 | 30-90日 | 安定運用・長期保持 |

### 💾 ストレージ最適化

```hcl
# 環境別ライフサイクル設定
locals {
  lifecycle_configs = {
    dev = {
      untagged_count_limit = 1
      tagged_count_limit   = 5
      age_limit_days       = 7
    }
    stg = {
      untagged_count_limit = 3
      tagged_count_limit   = 15
      age_limit_days       = 21
    }
    prod = {
      untagged_count_limit = 5
      tagged_count_limit   = 50
      age_limit_days       = 90
    }
  }
}
```

## 🔗 出力値

### 🐳 単一リポジトリ用出力

| 出力名 | 説明 |
|--------|------|
| `repository_url` | ECRリポジトリURL |
| `repository_arn` | ECRリポジトリARN |
| `repository_name` | ECRリポジトリ名 |
| `registry_id` | ECRレジストリID |
| `registry_url` | ECRレジストリURL |

### 🐳 複数リポジトリ用出力

| 出力名 | 説明 |
|--------|------|
| `repositories` | 全リポジトリ情報 |
| `repository_urls` | 全リポジトリURL |
| `repository_arns` | 全リポジトリARN |
| `repository_names` | 全リポジトリ名 |

### 🔧 運用用出力

| 出力名 | 説明 |
|--------|------|
| `docker_push_commands` | Dockerプッシュコマンド |
| `docker_pull_commands` | Dockerプルコマンド |
| `aws_cli_commands` | AWS CLI操作コマンド |

## 🚀 CI/CD統合

### 🔄 GitHub Actions例

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [ main, develop ]

jobs:
  build:
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

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

### 🔄 GitLab CI/CD例

```yaml
image: docker:latest

variables:
  AWS_DEFAULT_REGION: us-east-1
  ECR_REPOSITORY: $PROJECT_NAME-$CI_COMMIT_REF_SLUG

stages:
  - build
  - push

build:
  stage: build
  script:
    - docker build -t $ECR_REPOSITORY:$CI_COMMIT_SHA .
    - docker tag $ECR_REPOSITORY:$CI_COMMIT_SHA $ECR_REPOSITORY:latest

push:
  stage: push
  script:
    - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    - docker push $ECR_REGISTRY/$ECR_REPOSITORY:$CI_COMMIT_SHA
    - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

## 📝 ライセンス

このモジュールは[MIT License](LICENSE)の下で提供されています。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**テスト状況**: 全機能テスト済み
