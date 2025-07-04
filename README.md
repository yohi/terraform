# Terraform Infrastructure Collection

このプロジェクトは、AWS環境でよく使用されるTerraformモジュールとツールを提供する包括的なインフラストラクチャ管理ソリューションです。

## 🆕 最新の更新内容

**2024年12月最新版の特徴：**
- ✅ **Terraform 1.0以降対応** - 最新のTerraform構文とプロバイダー使用
- ✅ **AWS Provider 5.x対応** - 最新のAWSプロバイダーに対応
- ✅ **動作確認済み** - 各モジュールで`terraform plan`での動作確認済み
- ✅ **統合されたタグ戦略** - 一貫したタグ管理によるリソース追跡
- ✅ **セキュリティ強化** - 最小権限原則とセキュリティベストプラクティス
- ✅ **自動化スクリプト** - AWS確認付きデプロイメントスクリプト
- ✅ **包括的な監視** - CloudWatch、SNS通知、詳細なログ分析

## 📁 プロジェクト構成

### 主要モジュール

#### 🚀 EC2 Auto Scaling Group
**場所**: `ec2/auto_scaling_group/`

**最新の機能強化 (feature/ec2__auto_scaling_group ブランチ):**
- 🔄 **インスタンスリフレッシュ機能** - Rolling更新による無停止デプロイ
- 📊 **高度なスケーリングポリシー** - ターゲット追跡とステップスケーリング
- 🏷️ **柔軟なタグ管理** - インスタンスレベルでのタグ制御
- 📉 **0台スケールダウン対応** - 完全なコスト最適化
- 🔔 **包括的なアラーム設定** - CPU、メモリ、ネットワーク監視
- 🔐 **セキュリティ強化** - KMS暗号化、IAM最小権限

**主な機能：**
- **スケーリングポリシー**:
  - シンプルスケーリング（CPU使用率ベース）
  - ターゲット追跡スケーリング（複数メトリクス対応）
  - ステップスケーリング（段階的調整）
- **インスタンスリフレッシュ**:
  - Rolling更新戦略
  - 最小ヘルシー割合設定
  - チェックポイント機能
- **監視・アラート**:
  - 4種類のCloudWatchアラーム（CPU High/Low、Scale Up/Down）
  - SNS通知統合
  - 詳細メトリクス収集
- **高可用性**:
  - マルチAZ配置
  - ロードバランサー統合
  - ヘルスチェック自動化

**設定例:**
```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project           = "myapp"
  env              = "prod"
  app              = "web"
  launch_template_id = "lt-12345678"

  # スケーリング設定
  desired_capacity = 2
  min_size         = 1  # 本番環境では2推奨
  max_size         = 8  # desired_capacity * 2 (自動計算)

  # インスタンスリフレッシュ
  enable_instance_refresh = true
  instance_refresh_min_healthy_percentage = 90
  instance_refresh_instance_warmup = 300

  # 高度なスケーリング
  enable_scale_up_policy   = true
  enable_scale_down_policy = true
  target_tracking_target_value = 70.0

  # 通知設定
  enable_notifications = true
  notification_email_addresses = ["devops@company.com"]

  # セキュリティ
  sns_kms_key_id = "alias/sns-encryption-key"
}
```

#### 🖥️ EC2 Launch Template
**場所**: `ec2/launch_template/`
- セキュアなEC2インスタンス起動テンプレート
- 監視エージェント統合（CloudWatch、Mackerel）
- 自動化されたユーザーデータスクリプト
- セキュリティグループとIAMロール管理
- IMDSv2強制設定

#### ⚖️ Application Load Balancer (ALB)
**場所**: `load_balancer/alb/`
- 高性能なロードバランサー構成
- ECS統合の実装例
- SSL/TLS終端処理
- ヘルスチェック設定

#### 📊 Athena Analytics
**場所**: `analytics/athena/`
- 複数タイプのログ（Django、Nginx、Error）の分析
- パーティション射影による高速クエリ
- 自動スケジュール実行のGlue Crawler
- 事前定義されたクエリテンプレート
- S3データの効率的な分析

### 🛠️ 自動化ツール

#### デプロイメントスクリプト
- **`apply_with_confirmation.sh`** - AWS確認付きTerraform適用
- **`plan_with_confirmation.sh`** - AWS確認付きTerraform計画
- **`search_terraform_resources.sh`** - Terraformリソース検索・集計

#### リソース管理
- **`create_terraform_resource_group.json`** - AWSリソースグループ設定
- **`analytics/check_aws_account.sh`** - AWS認証情報確認

## 🚀 クイックスタート

### 1. 前提条件の確認

```bash
# 必要なツールの確認
aws --version      # AWS CLI
jq --version       # JSON processor
terraform version  # Terraform 1.0+
```

### 2. AWS認証情報の設定

```bash
# AWS認証情報の設定
aws configure

# 現在のアカウント情報を確認
aws sts get-caller-identity
```

### 3. Auto Scaling Group の基本的な使用方法

```bash
# プロジェクトをクローン
git clone <repository-url>
cd teraform

# Auto Scaling Groupブランチに切り替え
git checkout feature/ec2__auto_scaling_group

# 設定ファイルを準備
cd ec2/auto_scaling_group/terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars  # 設定を編集

# AWS確認付きデプロイメント（推奨）
./plan_with_confirmation.sh
./apply_with_confirmation.sh
```

## 📋 Auto Scaling Group 詳細設定

### 基本設定項目

| 設定項目                    | 説明                   | デフォルト値           | 推奨値                   |
| --------------------------- | ---------------------- | ---------------------- | ------------------------ |
| `desired_capacity`          | 希望インスタンス数     | `2`                    | 本番: `2-4`, 開発: `1-2` |
| `min_size`                  | 最小インスタンス数     | `0`                    | 本番: `2`, 開発: `1`     |
| `max_size`                  | 最大インスタンス数     | `desired_capacity * 2` | 自動計算                 |
| `health_check_grace_period` | ヘルスチェック猶予期間 | `300`                  | ALB使用時: `600`         |
| `default_cooldown`          | デフォルトクールダウン | `300`                  | 高負荷時: `600`          |

### スケーリングポリシー設定

#### シンプルスケーリング
```hcl
# スケールアップ
enable_scale_up_policy = true
scale_up_adjustment = 1
scale_up_cooldown = 300

# スケールダウン
enable_scale_down_policy = true
scale_down_adjustment = -1
scale_down_cooldown = 300
```

#### ターゲット追跡スケーリング
```hcl
target_tracking_target_value = 70.0
target_tracking_metric_type = "ASGAverageCPUUtilization"
target_tracking_scale_out_cooldown = 300
target_tracking_scale_in_cooldown = 300
```

#### ステップスケーリング
```hcl
scale_up_policy_type = "StepScaling"
scale_up_step_adjustments = [
  {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 50
  },
  {
    scaling_adjustment          = 2
    metric_interval_lower_bound = 50
    metric_interval_upper_bound = null
  }
]
```

### インスタンスリフレッシュ設定

```hcl
enable_instance_refresh = true
instance_refresh_strategy = "Rolling"
instance_refresh_min_healthy_percentage = 90
instance_refresh_instance_warmup = 300
instance_refresh_checkpoint_delay = 3600
instance_refresh_checkpoint_percentages = [20, 50, 100]
```

### 高度なタグ管理

#### 基本タグ（全リソース共通）
```hcl
common_tags = {
  Project     = "myapp"
  Environment = "prod"
  ManagedBy   = "terraform"
  Owner       = "DevOps"
  CostCenter  = "engineering"
}
```

#### 追加タグ（インスタンス固有）
```hcl
additional_tags = {
  "Name" = {
    value = "myapp-prod-web-instance"
    propagate_at_launch = true
  }
  "Backup" = {
    value = "daily"
    propagate_at_launch = true
  }
  "Monitoring" = {
    value = "detailed"
    propagate_at_launch = true
  }
  "Schedule" = {
    value = "business-hours"
    propagate_at_launch = false
  }
}
```

## 🔧 設定戦略

### 環境別推奨設定

#### 本番環境 (prod)
```hcl
desired_capacity = 4
min_size = 2
enable_instance_refresh = true
enable_notifications = true
health_check_type = "ELB"
health_check_grace_period = 600
target_tracking_target_value = 70.0
```

#### ステージング環境 (stg)
```hcl
desired_capacity = 2
min_size = 1
enable_instance_refresh = true
enable_notifications = true
health_check_type = "ELB"
health_check_grace_period = 300
target_tracking_target_value = 80.0
```

#### 開発環境 (dev)
```hcl
desired_capacity = 1
min_size = 0
enable_instance_refresh = false
enable_notifications = false
health_check_type = "EC2"
health_check_grace_period = 300
```

### セキュリティベストプラクティス

1. **最小権限原則**: IAMロールとポリシーの最小権限設定
2. **暗号化**: SNS通知のKMS暗号化
3. **IMDSv2強制**: EC2メタデータサービスv2の強制使用
4. **セキュリティグループ**: 必要最小限のポート開放
5. **監査ログ**: CloudTrailとConfig連携

### 監視・アラート戦略

#### CloudWatchアラーム設定
```hcl
# CPU使用率監視
enable_cpu_high_alarm = true
cpu_high_threshold = 80
cpu_high_evaluation_periods = 2

enable_cpu_low_alarm = true
cpu_low_threshold = 10
cpu_low_evaluation_periods = 2

# カスタムメトリクス
enable_scale_up_alarm = true
scale_up_alarm_metric_name = "CPUUtilization"
scale_up_alarm_threshold = 75

enable_scale_down_alarm = true
scale_down_alarm_metric_name = "CPUUtilization"
scale_down_alarm_threshold = 25
```

#### SNS通知設定
```hcl
enable_notifications = true
notification_email_addresses = [
  "devops@company.com",
  "oncall@company.com"
]
notification_types = [
  "autoscaling:EC2_INSTANCE_LAUNCH",
  "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  "autoscaling:EC2_INSTANCE_TERMINATE",
  "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
]
```

## 🔍 リソース検索と管理

### リソース検索スクリプト

```bash
# 全てのTerraformリソースを検索
./search_terraform_resources.sh

# 特定のプロジェクトのリソースを検索
./search_terraform_resources.sh myproject

# 特定のプロジェクトと環境のリソースを検索
./search_terraform_resources.sh myproject prod
```

### 出力内容
- リソース一覧とタグ情報
- リソースタイプ別集計
- EC2インスタンス詳細
- S3バケット詳細
- Auto Scaling Group詳細
- コスト追跡情報

## 🎯 運用のベストプラクティス

### 1. デプロイメント戦略
- **Blue-Green デプロイ**: インスタンスリフレッシュ機能を活用
- **カナリアリリース**: チェックポイント機能で段階的更新
- **ロールバック**: 起動テンプレートのバージョン管理

### 2. 監視・運用
- **ダッシュボード**: CloudWatchダッシュボードの自動作成
- **アラート**: 段階的エスカレーション設定
- **ログ分析**: Athenaを使用した詳細分析

### 3. コスト最適化
- **スケジューリング**: 開発環境の自動停止
- **インスタンスタイプ**: 混合インスタンス戦略
- **スポットインスタンス**: コスト効率の向上

### 4. セキュリティ
- **定期的な更新**: インスタンスリフレッシュでのAMI更新
- **脆弱性管理**: AWS Systems Managerとの連携
- **アクセス制御**: IAMロールの定期的な見直し

## 🆘 トラブルシューティング

### よくある問題と解決策

#### 1. インスタンスが起動しない
```bash
# 起動テンプレートの確認
aws ec2 describe-launch-templates --launch-template-ids lt-12345678

# セキュリティグループの確認
aws ec2 describe-security-groups --group-ids sg-12345678
```

#### 2. スケーリングが動作しない
```bash
# スケーリングポリシーの確認
aws autoscaling describe-policies --auto-scaling-group-name myapp-prod-web-asg

# CloudWatchアラームの確認
aws cloudwatch describe-alarms --alarm-names myapp-prod-web-cpu-high
```

#### 3. インスタンスリフレッシュが失敗する
```bash
# リフレッシュ状況の確認
aws autoscaling describe-instance-refreshes --auto-scaling-group-name myapp-prod-web-asg
```

## 📚 関連ドキュメント

- [TERRAFORM-TAGS-STRATEGY.md](./TERRAFORM-TAGS-STRATEGY.md) - タグ戦略の詳細
- [AWS Auto Scaling ユーザーガイド](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📞 サポート

質問や問題がある場合は、以下の方法でお問い合わせください：

- **Issues**: GitHubのIssueページ
- **Email**: devops@company.com
- **Chat**: Slack #infrastructure チャンネル

---

**最終更新**: 2024年12月 (feature/ec2__auto_scaling_group ブランチ)
**Terraform Version**: >= 1.0
**AWS Provider Version**: >= 5.0
