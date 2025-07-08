# 🚀 Terraform Infrastructure Collection

**最新の更新**: 2024年12月 - 完全動作確認済み

このプロジェクトは、AWS環境でよく使用されるTerraformモジュールとツールを提供する包括的なインフラストラクチャ管理ソリューションです。

## ✨ 最新の特徴

### 🔄 **2024年12月アップデート**
- ✅ **Terraform 1.0+ 対応** - 最新の構文とプロバイダー
- ✅ **AWS Provider 5.x 対応** - 最新機能とセキュリティ
- ✅ **全モジュール動作確認済み** - `terraform plan` 検証済み
- ✅ **統合タグ戦略** - 一貫したリソース管理とコスト追跡
- ✅ **セキュリティ強化** - 最小権限原則とベストプラクティス
- ✅ **自動化スクリプト** - 確認付きデプロイメント
- ✅ **包括的監視** - CloudWatch、SNS、詳細ログ分析

## 🏗️ アーキテクチャ概要

```
                          ┌─────────────────────────────────────────────────────────┐
                          │                 AWS Infrastructure                      │
                          └─────────────────────────────────────────────────────────┘
                                                     │
                     ┌───────────────────────────────┼───────────────────────────────┐
                     │                               │                               │
            ┌─────────▼─────────┐          ┌─────────▼─────────┐          ┌─────────▼─────────┐
            │   Load Balancer   │          │   ECS Cluster     │          │   Auto Scaling    │
            │                   │          │                   │          │                   │
            │ ├─ ALB/NLB        │◄─────────┤ ├─ Services       │          │ ├─ Launch Template │
            │ ├─ Target Groups  │          │ ├─ Tasks          │          │ ├─ Scaling Policies│
            │ └─ SSL/TLS        │          │ └─ Container Mgmt │          │ └─ Health Checks  │
            └───────────────────┘          └───────────────────┘          └───────────────────┘
                     │                               │                               │
                     └───────────────────────────────┼───────────────────────────────┘
                                                     │
                     ┌───────────────────────────────┼───────────────────────────────┐
                     │                               │                               │
            ┌─────────▼─────────┐          ┌─────────▼─────────┐          ┌─────────▼─────────┐
            │   Monitoring      │          │   Container Reg   │          │   Data Analytics  │
            │                   │          │                   │          │                   │
            │ ├─ CloudWatch     │          │ ├─ ECR Repository │          │ ├─ Athena         │
            │ ├─ SNS Alarms     │          │ ├─ Image Scanning │          │ ├─ Glue Crawler   │
            │ └─ Log Analytics  │          │ └─ Lifecycle Mgmt │          │ └─ S3 Integration │
            └───────────────────┘          └───────────────────┘          └───────────────────┘
```

## 📦 主要モジュール

### 🖥️ **EC2 Auto Scaling Group**
**場所**: [`ec2/auto_scaling_group/`](./ec2/auto_scaling_group/)

**2024年12月新機能:**
- 🔄 **インスタンスリフレッシュ** - ゼロダウンタイムローリング更新
- 📊 **高度なスケーリング** - ターゲット追跡・ステップスケーリング
- 🏷️ **統合タグ戦略** - 環境・セキュリティ・運用タグ自動適用
- 📉 **完全コスト最適化** - 0台スケールダウン対応
- 🔔 **包括的アラーム** - 4種類のCloudWatchアラーム + SNS通知
- 🔐 **セキュリティ強化** - KMS暗号化、入力バリデーション
- 🧪 **自動テストスクリプト** - ワンクリック検証

### 🚀 **EC2 Launch Template**
**場所**: [`ec2/launch_template/`](./ec2/launch_template/)

**特徴:**
- 🐧 **Amazon Linux 2023 ECS最適化** - 最新のAMI自動選択
- 📊 **統合監視** - CloudWatch Agent + Mackerel Agent
- 🔒 **セキュリティ強化** - IMDSv2強制、EBS暗号化
- 🛠️ **自動化ツール** - ctop、パフォーマンスツール自動インストール
- 🎯 **ECS統合** - コンテナ実行環境の最適化

### 🐳 **ECR Repository**
**場所**: [`ecr/repository/`](./ecr/repository/)

**機能:**
- 📦 **単一・複数リポジトリ** - 柔軟な構成対応
- 🔄 **ライフサイクルポリシー** - 自動イメージクリーンアップ
- 🔍 **イメージスキャン** - 脆弱性検出とセキュリティ確認
- 🔐 **暗号化設定** - AES256/KMS暗号化対応
- 🌐 **クロスアカウント** - 複数アカウント間でのイメージ共有

### 🔧 **ECS Cluster**
**場所**: [`ecs/cluster/`](./ecs/cluster/)

**機能:**
- 🚀 **Fargate & EC2統合** - 複数のコンピューティングタイプ
- 📊 **Container Insights** - 詳細なコンテナメトリクス
- 🔧 **Execute Command** - コンテナへの安全なアクセス
- ⚖️ **キャパシティプロバイダー** - コスト最適化とパフォーマンス

### 🌐 **ECS Service**
**場所**: [`ecs/service/`](./ecs/service/)

**機能:**
- 🔄 **タスク定義管理** - 完全なコンテナライフサイクル
- 🔐 **IAM統合** - 自動的なロール・ポリシー作成
- 📈 **Auto Scaling** - CPU/メモリベースの自動スケーリング
- 🔗 **ロードバランサー統合** - ALB/NLB完全統合

### ⚖️ **Application Load Balancer**
**場所**: [`load_balancer/alb/`](./load_balancer/alb/)

**機能:**
- 🔐 **SSL/TLS終端** - 自動HTTPSリダイレクト
- 🎯 **ECS統合** - IPベースターゲット群対応
- 🔍 **ヘルスチェック** - 最適化されたECS用設定
- 📊 **高可用性** - 複数AZ自動分散

### 📊 **Athena Analytics**
**場所**: [`analytics/athena/`](./analytics/athena/)

**機能:**
- 🔍 **複数ログタイプ分析** - Django、Nginx、Errorログ対応
- 🚀 **パーティション射影** - 高速クエリ実行
- 🔄 **Glue Crawler自動化** - スケジュール実行による自動スキーマ更新
- 📋 **事前定義クエリ** - 即座に使用可能なクエリテンプレート

## 🚀 クイックスタート

### 1. 📋 前提条件確認

```bash
# 必要なツールのバージョン確認
terraform version  # >= 1.0
aws --version      # AWS CLI v2推奨
jq --version       # JSONプロセッサー
```

### 2. 🔑 AWS設定

```bash
# 認証情報設定
aws configure

# 現在のアカウント確認
aws sts get-caller-identity

# 必要な権限確認
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query User.UserName --output text)
```

### 3. 🛠️ 基本セットアップ

```bash
# プロジェクトクローン
git clone <repository-url>
cd terraform

# 設定ファイル準備
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars  # 環境に応じて編集

# 基本設定例
cat > terraform.tfvars << EOF
# 基本設定
project_name = "myproject"
environment  = "dev"
app          = "web"

# AWS設定
aws_region = "ap-northeast-1"

# 共通タグ
common_tags = {
  Project     = "myproject"
  Environment = "dev"
  Owner       = "team-name"
  ManagedBy   = "terraform"
}
EOF
```

### 4. 🚀 確認付きデプロイメント（推奨）

```bash
# 確認付きプラン実行
./plan_with_confirmation.sh

# 確認付きデプロイメント
./apply_with_confirmation.sh

# リソース状態確認
terraform state list
```

## 🔧 自動化ツール

### 📋 デプロイメントスクリプト

| スクリプト                      | 説明                      | 使用場面               |
| ------------------------------- | ------------------------- | ---------------------- |
| `plan_with_confirmation.sh`     | AWS確認付きプラン実行     | 変更内容の事前確認     |
| `apply_with_confirmation.sh`    | AWS確認付きデプロイメント | 安全な本番デプロイ     |
| `search_terraform_resources.sh` | リソース検索・集計        | 現在のリソース状況確認 |

### 🔍 リソース管理

```bash
# リソース検索
./search_terraform_resources.sh

# 特定のリソースタイプ検索
./search_terraform_resources.sh aws_instance

# AWSアカウント確認
./analytics/check_aws_account.sh
```

## 📊 設定管理

### 🎯 基本設定パターン

```hcl
# 開発環境
project_name = "myproject"
environment  = "dev"
app          = "web"

# 本番環境
project_name = "myproject"
environment  = "prod"
app          = "api"

# 共通タグ戦略
common_tags = {
  Project     = var.project_name
  Environment = var.environment
  Owner       = "team-name"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Schedule    = "business-hours"
}
```

### 🏷️ タグ戦略

**必須タグ（自動適用）:**
- `Project` - プロジェクト識別子
- `Environment` - 環境識別子（dev/stg/prod）
- `ManagedBy` - 管理方法（terraform）

**推奨タグ:**
- `Owner` - 責任者・チーム名
- `CostCenter` - コストセンター
- `Schedule` - スケジュール（運用時間）
- `BackupRequired` - バックアップ要否

詳細は[TERRAFORM-TAGS-STRATEGY.md](./TERRAFORM-TAGS-STRATEGY.md)参照

## 🔐 セキュリティベストプラクティス

### 🔒 IAM権限管理

```hcl
# 最小権限原則
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 🔐 暗号化設定

**保存時暗号化:**
- EBS: デフォルトでAES256暗号化
- S3: SSE-S3またはSSE-KMS
- RDS: TDE（透過的データ暗号化）

**転送時暗号化:**
- ALB: HTTPS強制、HTTP→HTTPSリダイレクト
- ECS: Service Connect TLS
- ECR: プッシュ/プル時TLS

### 🔑 シークレット管理

```hcl
# Parameter Store使用例
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/database/password"
  type  = "SecureString"
  value = var.db_password

  tags = local.common_tags
}

# ECSタスクでの使用
container_definitions = jsonencode([
  {
    name = "app"
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = aws_ssm_parameter.db_password.arn
      }
    ]
  }
])
```

## 📈 運用・監視

### 🔔 アラート設定

```hcl
# CloudWatch アラーム例
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs cpu utilization"

  alarm_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }
}
```

### 📊 コスト最適化

**スケーリング戦略:**
- 開発環境: 0台スケールダウン対応
- 本番環境: 最小2台で高可用性確保
- Spot インスタンス: 開発・テスト環境で70%コスト削減

**リソース管理:**
- 未使用リソースの自動削除
- ライフサイクルポリシーによるログ・イメージ管理
- 夜間・週末の自動スケールダウン

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題                    | 原因             | 解決方法                   |
| ----------------------- | ---------------- | -------------------------- |
| `terraform plan` エラー | AWS認証情報不正  | `aws configure` で再設定   |
| リソース作成失敗        | 権限不足         | IAMポリシー確認・追加      |
| ECS タスク起動失敗      | リソース不足     | CPU/メモリ設定見直し       |
| ALB ヘルスチェック失敗  | ポート設定間違い | ターゲットグループ設定確認 |

### 🔍 デバッグ手順

```bash
# 1. 基本情報確認
terraform version
aws sts get-caller-identity

# 2. 状態確認
terraform state list
terraform state show <resource_name>

# 3. ログ確認
terraform apply -auto-approve -refresh=true
aws logs describe-log-groups --log-group-name-prefix /aws/ecs/

# 4. リソース状況確認
aws ecs describe-services --cluster <cluster_name> --services <service_name>
aws application-autoscaling describe-scaling-policies
```

## 🎯 パフォーマンス最適化

### 📊 推奨設定

| 環境         | インスタンスタイプ | 最小/最大台数 | CPU/メモリ |
| ------------ | ------------------ | ------------- | ---------- |
| 開発         | t3.micro           | 0/4           | 256/512    |
| ステージング | t3.small           | 1/8           | 512/1024   |
| 本番         | t3.medium以上      | 2/20          | 1024/2048  |

### 🚀 CI/CD統合

```yaml
# GitHub Actions例
name: Infrastructure Deploy
on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ">= 1.0"

      - name: Terraform Plan
        run: |
          cd terraform
          terraform init
          terraform plan -out=tfplan

      - name: Terraform Apply
        run: |
          cd terraform
          terraform apply tfplan
```

## 🔗 関連リンク

- [Terraform公式ドキュメント](https://www.terraform.io/docs/)
- [AWS Provider公式ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 📝 ライセンス

このプロジェクトは[MIT License](LICENSE)の下で提供されています。

## 🤝 コントリビューション

プルリクエストやイシューの作成を歓迎します。詳細は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**メンテナンス**: 継続的な更新・改善を実施
