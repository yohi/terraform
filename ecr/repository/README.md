# ECR Repository Terraform Module

このモジュールは、Amazon ECR（Elastic Container Registry）リポジトリを作成するためのTerraformコードです。

## 機能

- ECRリポジトリの作成（単一または複数）
- ライフサイクルポリシーの自動設定
- イメージスキャン設定
- 暗号化設定（AES256またはKMS）
- リポジトリポリシーの設定
- レプリケーション設定
- プル経由キャッシュ設定
- Docker pushコマンド生成

## 使用方法

### 基本的な使用例（単一リポジトリ）

```hcl
module "ecr_repository" {
  source = "./ecr/repository/terraform"

  project_name = "my-project"
  environment  = "dev"
  app          = "web"

  # スキャン設定
  scan_on_push = true

  # ライフサイクル設定
  enable_lifecycle_policy    = true
  untagged_image_count_limit = 5
  tagged_image_count_limit   = 10
  image_age_limit_days       = 30

  common_tags = {
    Project     = "my-project"
    Environment = "dev"
    Owner       = "team-name"
    Terraform   = "true"
  }
}
```

### 複数リポジトリの作成例

```hcl
module "ecr_repositories" {
  source = "./ecr/repository/terraform"

  project_name = "my-project"
  environment  = "prod"

  # 複数リポジトリ定義
  repositories = [
    {
      name                 = "my-project-prod-frontend"
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
      encryption_type      = "KMS"
      kms_key_id          = "alias/my-ecr-key"
    },
    {
      name                 = "my-project-prod-backend"
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
      encryption_type      = "KMS"
      kms_key_id          = "alias/my-ecr-key"
    },
    {
      name                 = "my-project-prod-worker"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
      encryption_type      = "AES256"
      kms_key_id          = ""
    }
  ]

  # ライフサイクル設定
  enable_lifecycle_policy = true
  lifecycle_policy_rules = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images"
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

  common_tags = {
    Project     = "my-project"
    Environment = "prod"
    Owner       = "devops-team"
    Terraform   = "true"
  }
}
```

### クロスアカウントアクセス設定例

```hcl
module "shared_ecr_repository" {
  source = "./ecr/repository/terraform"

  project_name = "shared"
  environment  = "common"
  app          = "base-images"

  # リポジトリポリシー設定
  enable_repository_policy = true
  allowed_principals = [
    "arn:aws:iam::123456789012:root",  # 開発アカウント
    "arn:aws:iam::987654321098:root"   # 本番アカウント
  ]
  allowed_actions = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:DescribeImages"
  ]

  # レプリケーション設定
  enable_replication = true
  replication_destinations = [
    "us-east-1",
    "us-west-2"
  ]

  common_tags = {
    Project     = "shared"
    Environment = "common"
    Owner       = "platform-team"
    Terraform   = "true"
  }
}
```

## 入力変数

### 必須変数

| 変数名         | 説明           | 型       |
| -------------- | -------------- | -------- |
| `project_name` | プロジェクト名 | `string` |
| `environment`  | 環境名         | `string` |

### 主要な設定変数

| 変数名                       | 説明                   | 型                  | デフォルト値    |
| ---------------------------- | ---------------------- | ------------------- | --------------- |
| `app`                        | アプリケーション名     | `string`            | `""`            |
| `repository_name`            | ECRリポジトリ名        | `string`            | `""` (自動生成) |
| `repositories`               | 複数リポジトリ定義     | `list(object(...))` | `[]`            |
| `image_tag_mutability`       | タグ変更可能性         | `string`            | `"MUTABLE"`     |
| `scan_on_push`               | プッシュ時スキャン     | `bool`              | `true`          |
| `encryption_type`            | 暗号化タイプ           | `string`            | `"AES256"`      |
| `enable_lifecycle_policy`    | ライフサイクルポリシー | `bool`              | `true`          |
| `untagged_image_count_limit` | タグなしイメージ保持数 | `number`            | `10`            |
| `tagged_image_count_limit`   | タグ付きイメージ保持数 | `number`            | `20`            |
| `image_age_limit_days`       | イメージ保持期間（日） | `number`            | `30`            |

詳細な変数については `variables.tf` を参照してください。

## 出力値

### 単一リポジトリ用出力

| 出力名            | 説明             |
| ----------------- | ---------------- |
| `repository_url`  | ECRリポジトリURL |
| `repository_arn`  | ECRリポジトリARN |
| `repository_name` | ECRリポジトリ名  |
| `registry_id`     | ECRレジストリID  |

### 複数リポジトリ用出力

| 出力名                     | 説明                       |
| -------------------------- | -------------------------- |
| `repository_urls`          | ECRリポジトリURLのマップ   |
| `repository_arns`          | ECRリポジトリARNのマップ   |
| `repository_names`         | ECRリポジトリ名のマップ    |
| `registry_ids`             | ECRレジストリIDのマップ    |
| `repository_image_uris`    | latest タグ付きURIのマップ |
| `repository_push_commands` | docker pushコマンドの例    |

詳細な出力については `outputs.tf` を参照してください。

## Docker操作例

### イメージのビルドとプッシュ

モジュールの出力から`repository_push_commands`を取得して実行：

```bash
# ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com

# イメージビルド
docker build -t my-project-dev-web .

# タグ付け
docker tag my-project-dev-web:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/my-project-dev-web:latest

# プッシュ
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/my-project-dev-web:latest
```

### ECSサービスとの統合例

```hcl
# ECRリポジトリ作成
module "ecr_repository" {
  source = "./ecr/repository/terraform"

  project_name = "my-project"
  environment  = "dev"
  app          = "web"
}

# ECSサービス作成（ECRイメージを使用）
module "ecs_service" {
  source = "./ecs/service/terraform"

  project_name = "my-project"
  environment  = "dev"
  app          = "web"
  cluster_name = "my-project-dev-ecs"

  # ECRリポジトリのイメージを使用
  container_image = "${module.ecr_repository.repository_url}:latest"

  depends_on = [module.ecr_repository]
}
```

## ライフサイクルポリシー

デフォルトのライフサイクルポリシーは以下のルールを適用します：

1. **タグなしイメージ**: 10個を超えるイメージを削除
2. **タグ付きイメージ**: 20個を超えるイメージを削除（主要タグを対象）
3. **古いイメージ**: 30日を超えたイメージを削除

カスタムポリシーを設定する場合は、`lifecycle_policy_rules`変数にJSON形式で指定してください。

## セキュリティ考慮事項

- 本番環境では`image_tag_mutability = "IMMUTABLE"`を推奨
- 機密イメージには`encryption_type = "KMS"`を使用
- クロスアカウントアクセスは最小権限の原則に従って設定
- イメージスキャンを有効にしてセキュリティ脆弱性を検出

## 前提条件

- Terraform >= 1.0
- AWS Provider >= 5.0
- 適切なAWS認証情報の設定
- ECRの権限（必要に応じてKMSキーへのアクセス権限）

## リソース

このモジュールは以下のAWSリソースを作成します：

- `aws_ecr_repository` - ECRリポジトリ
- `aws_ecr_lifecycle_policy` - ライフサイクルポリシー（有効時）
- `aws_ecr_repository_policy` - リポジトリポリシー（有効時）
- `aws_ecr_replication_configuration` - レプリケーション設定（有効時）
- `aws_ecr_pull_through_cache_rule` - プル経由キャッシュルール（有効時）

## 注意事項

- リポジトリ削除時は、事前にすべてのイメージを削除してください
- レプリケーション設定は慎重に設定し、コストを考慮してください
- ライフサイクルポリシーは本番環境では慎重にテストしてから適用してください
