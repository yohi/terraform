# EC2 Auto Scaling Group Terraform Module

このモジュールは、AWS Auto Scaling Group（オートスケーリンググループ）を作成・管理するためのTerraformモジュールです。

## 最新の更新内容

**2024年12月最新版の特徴：**
- ✅ **Terraform 1.0以降対応** - 最新のTerraform構文とプロバイダーを使用
- ✅ **AWS Provider 5.x対応** - 最新のAWSプロバイダーに対応
- ✅ **動作確認済み** - `terraform plan`で動作確認済み
- ✅ **詳細なタグ管理** - common_tagsとadditional_tagsによる柔軟なタグ設定
- ✅ **柔軟なサイズ設定** - min_size、desired_capacity、max_sizeの独立した設定が可能
- ✅ **VPCサブネット対応** - デフォルトVPCサブネットの自動選択またはカスタムサブネット指定

## 機能

- **Auto Scaling Group**: EC2インスタンスの自動スケーリング（名前形式: `${project}-${env}-${app}-asg`、appは省略可能）
- **スケーリングポリシー**: CPU使用率に基づく自動スケールアップ・ダウン
- **CloudWatch Alarms**: システム監視とアラート（4種類のアラーム対応）
- **SNS通知**: スケーリングイベントの通知（オプション）
- **インスタンスリフレッシュ**: 起動テンプレート変更時の自動更新
- **ロードバランサー統合**: ALB/NLB/CLBとの統合
- **ターゲット追跡スケーリング**: CPU使用率ベースの自動スケーリング

## 前提条件

- **Terraform**: バージョン 1.0 以降
- **AWS Provider**: バージョン 5.x 以降
- **事前作成リソース**: 起動テンプレートが作成済みであること
- **IAM権限**: 適切なIAMロールとポリシーが設定されていること

## 使用方法

### 1. 設定ファイルの準備

```bash
# 設定例ファイルをコピー
cp terraform.tfvars.example terraform.tfvars

# 設定を編集
vi terraform.tfvars
```

### 2. 必須設定項目

最低限、以下の項目を設定してください：

```hcl
# 起動テンプレートID（必須）
launch_template_id = "lt-0123456789abcdef0"

# プロジェクト情報
project = "your-project-name"
env     = "dev"
```

### 3. デプロイ

```bash
# 初期化
terraform init

# プランの確認
terraform plan

# 適用
terraform apply
```

## 主要な設定項目

### 基本設定

| 変数名               | 説明               | デフォルト値       | 必須 |
| -------------------- | ------------------ | ------------------ | ---- |
| `launch_template_id` | 起動テンプレートID | -                  | ✅    |
| `project`            | プロジェクト名     | `"myproject"`      |      |
| `env`                | 環境名             | `"dev"`            |      |
| `app`                | アプリケーション名 | `""`（省略可能）   |      |
| `aws_region`         | AWSリージョン      | `"ap-northeast-1"` |      |

### スケーリング設定

| 変数名                      | 説明                                                              | デフォルト値 |
| --------------------------- | ----------------------------------------------------------------- | ------------ |
| `min_size`                  | 最小インスタンス数（0に設定することで完全なスケールダウンが可能） | `0`          |
| `desired_capacity`          | 希望インスタンス数（最大インスタンス数は2倍に自動設定）           | `2`          |
| `health_check_type`         | ヘルスチェックタイプ（EC2またはELB）                              | `"EC2"`      |
| `health_check_grace_period` | ヘルスチェック猶予期間（秒）                                      | `300`        |
| `default_cooldown`          | デフォルトクールダウン時間（秒）                                  | `300`        |

### ネットワーク設定

| 変数名               | 説明                                                     | デフォルト値 |
| -------------------- | -------------------------------------------------------- | ------------ |
| `subnet_ids`         | サブネットIDリスト（空の場合はデフォルトVPCを使用）      | `[]`         |
| `availability_zones` | アベイラビリティーゾーン（空の場合は利用可能なAZを使用） | `[]`         |

### 通知設定

| 変数名                         | 説明                 | デフォルト値 |
| ------------------------------ | -------------------- | ------------ |
| `enable_notifications`         | 通知の有効/無効      | `false`      |
| `notification_email_addresses` | 通知先メールアドレス | `[]`         |

### アラーム設定

| 変数名                  | 説明                 | デフォルト値 |
| ----------------------- | -------------------- | ------------ |
| `enable_cpu_high_alarm` | CPU高使用率アラーム  | `true`       |
| `cpu_high_threshold`    | CPU高使用率閾値（%） | `80`         |
| `enable_cpu_low_alarm`  | CPU低使用率アラーム  | `true`       |
| `cpu_low_threshold`     | CPU低使用率閾値（%） | `10`         |

### スケーリングポリシー設定

| 変数名                     | 説明                           | デフォルト値      |
| -------------------------- | ------------------------------ | ----------------- |
| `enable_scale_up_policy`   | スケールアップポリシーの有効化 | `true`            |
| `scale_up_policy_type`     | スケールアップポリシータイプ   | `"SimpleScaling"` |
| `enable_scale_down_policy` | スケールダウンポリシーの有効化 | `true`            |
| `scale_down_policy_type`   | スケールダウンポリシータイプ   | `"SimpleScaling"` |

### タグ設定

| 変数名            | 説明                                        | デフォルト値 |
| ----------------- | ------------------------------------------- | ------------ |
| `common_tags`     | すべてのリソースに適用される共通タグ        | `{}`         |
| `additional_tags` | ASGに追加するタグ（プロパゲート設定を含む） | `{}`         |

## 使用例

### 基本的な使用例

```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "my-webapp"
  env     = "prd"
  app     = "frontend"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # スケーリング設定
  min_size         = 2  # 本番環境では最小2インスタンス
  desired_capacity = 4  # 通常時は4インスタンス

  # ALBとの統合
  target_group_arns = [
    "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/my-app-tg/1234567890123456"
  ]
  health_check_type = "ELB"

  # 通知設定
  enable_notifications = true
  notification_email_addresses = [
    "devops@company.com"
  ]

  # 運用管理タグ
  owner_team    = "DevOps"
  owner_email   = "devops@company.com"
  cost_center   = "engineering"
  billing_code  = "PROJ-2024-webapp"

  # 共通タグ
  common_tags = {
    Environment = "prd"
    Service     = "frontend"
    CriticalityLevel = "high"
  }
}
```

### 開発環境での使用例

```hcl
module "auto_scaling_group_dev" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "my-webapp"
  env     = "dev"
  app     = "api"

  # 起動テンプレート
  launch_template_id = "lt-0987654321fedcba0"

  # 開発環境では費用を抑えた設定
  min_size         = 0  # 夜間は完全停止可能
  desired_capacity = 1  # 通常は1インスタンス

  # スケジュール設定（業務時間のみ）
  schedule = "business-hours"

  # 簡易監視
  monitoring_level = "basic"

  # 通知は開発チームのみ
  enable_notifications = true
  notification_email_addresses = [
    "dev-team@company.com"
  ]

  # 運用管理タグ
  owner_team   = "Development"
  owner_email  = "dev-team@company.com"
  cost_center  = "engineering"

  common_tags = {
    Environment = "dev"
    Service     = "api"
    CriticalityLevel = "low"
  }
}
```

### 高可用性構成の例

```hcl
module "auto_scaling_group_ha" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "mission-critical"
  env     = "prd"
  app     = "core"

  # 起動テンプレート
  launch_template_id = "lt-0abcdef123456789"

  # 高可用性設定
  min_size         = 4  # 最小4インスタンス
  desired_capacity = 6  # 通常は6インスタンス

  # 複数AZにまたがる配置
  availability_zones = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d"
  ]

  # 厳格なヘルスチェック
  health_check_type = "ELB"
  health_check_grace_period = 600

  # インスタンス保護
  protect_from_scale_in = true

  # 詳細監視
  monitoring_level = "detailed"

  # 機密データの取り扱い
  data_classification = "confidential"
  backup_required = true

  # アラーム設定
  enable_cpu_high_alarm = true
  cpu_high_threshold = 70  # より低い閾値

  # 通知設定（複数チーム）
  enable_notifications = true
  notification_email_addresses = [
    "sre@company.com",
    "devops@company.com",
    "oncall@company.com"
  ]

  # 運用管理タグ
  owner_team   = "SRE"
  owner_email  = "sre@company.com"
  cost_center  = "production"
  billing_code = "CRIT-2024-core"

  common_tags = {
    Environment = "prd"
    Service     = "core"
    CriticalityLevel = "critical"
    ComplianceScope = "pci"
  }
}
```

### ターゲット追跡スケーリング例

```hcl
module "auto_scaling_group_target_tracking" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "analytics"
  env     = "prd"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # スケーリング設定
  min_size         = 2
  desired_capacity = 4

  # ターゲット追跡スケーリング
  enable_scale_up_policy = true
  scale_up_policy_type = "TargetTrackingScaling"
  target_tracking_target_value = 60.0  # CPU使用率60%を目標
  target_tracking_metric_type = "ASGAverageCPUUtilization"
  target_tracking_scale_out_cooldown = 300
  target_tracking_scale_in_cooldown = 300

  # 通知設定
  enable_notifications = true
  notification_email_addresses = [
    "analytics-team@company.com"
  ]

  # 運用管理タグ
  owner_team   = "Analytics"
  owner_email  = "analytics-team@company.com"
  cost_center  = "data-engineering"

  common_tags = {
    Environment = "prd"
    Service     = "analytics"
    WorkloadType = "batch"
  }
}
```

## 💡 設定のベストプラクティス

### 1. 環境別設定の推奨値

| 項目                        | 開発環境 | ステージング環境 | 本番環境 |
| --------------------------- | -------- | ---------------- | -------- |
| `min_size`                  | 0        | 1                | 2以上    |
| `desired_capacity`          | 1        | 2                | 4以上    |
| `health_check_grace_period` | 300      | 300              | 600      |
| `monitoring_level`          | basic    | detailed         | detailed |
| `backup_required`           | false    | true             | true     |

### 2. セキュリティ設定

```hcl
# 機密データを扱う場合
data_classification = "confidential"
backup_required = true

# SNS暗号化
sns_kms_key_id = "alias/sns-encryption-key"

# 詳細監視
monitoring_level = "detailed"
```

### 3. コスト最適化

```hcl
# 開発環境でのコスト削減
min_size = 0  # 夜間停止可能
schedule = "business-hours"

# スケジュール設定での自動停止
# 別途Lambda関数やEventBridgeと組み合わせて使用
```

## 📊 監視とアラート

このモジュールでは以下の監視項目が自動で設定されます：

- **CPU使用率アラーム**: 高使用率・低使用率の検知
- **スケーリングイベント**: インスタンス起動・停止の通知
- **ヘルスチェック**: インスタンス健全性の監視
- **CloudWatch メトリクス**: 詳細な使用状況の記録

### アラート設定例

```hcl
# CPU使用率アラーム
enable_cpu_high_alarm = true
cpu_high_threshold = 80
cpu_high_evaluation_periods = 2

# スケーリングアラーム
enable_scale_up_alarm = true
scale_up_alarm_threshold = 70
```

## 🛠️ トラブルシューティング

### よくある問題と解決方法

1. **インスタンスが起動しない**
   - 起動テンプレートIDを確認
   - IAM権限を確認
   - サブネットの可用性を確認

2. **スケーリングが動作しない**
   - CloudWatch Alarmの状態を確認
   - スケーリングポリシーの設定を確認
   - クールダウン時間を確認

3. **通知が届かない**
   - SNS トピックの設定を確認
   - Email サブスクリプションの確認待ち状態をチェック
   - IAM権限を確認

### デバッグ用コマンド

```bash
# Auto Scaling Group の状態確認
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "your-asg-name"

# スケーリングアクティビティの確認
aws autoscaling describe-scaling-activities --auto-scaling-group-name "your-asg-name"

# CloudWatch Alarmの状態確認
aws cloudwatch describe-alarms --alarm-names "your-alarm-name"
```

## 🔗 関連リソース

- [AWS Auto Scaling ユーザーガイド](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Terraform AWS Provider ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [プロジェクトのタグ戦略](../../TERRAFORM-TAGS-STRATEGY.md)

## 📝 変更履歴

| 日付    | バージョン | 変更内容                       |
| ------- | ---------- | ------------------------------ |
| 2024-12 | 1.0.0      | 初回リリース                   |
| 2024-12 | 1.1.0      | ターゲット追跡スケーリング対応 |
| 2024-12 | 1.2.0      | 詳細なタグ戦略対応             |

## 出力値

主要な出力値：

### Auto Scaling Group情報
- `autoscaling_group_id`: Auto Scaling GroupのID
- `autoscaling_group_arn`: Auto Scaling GroupのARN
- `autoscaling_group_name`: Auto Scaling Groupの名前
- `autoscaling_group_availability_zones`: 使用されるアベイラビリティーゾーン
- `autoscaling_group_vpc_zone_identifier`: 使用されるサブネットID

### スケーリング情報
- `scaling_configuration`: スケーリング設定のサマリー
- `scaling_policies_enabled`: 有効なスケーリングポリシー
- `scale_up_policy_arn`: スケールアップポリシーのARN
- `scale_down_policy_arn`: スケールダウンポリシーのARN

### アラーム情報
- `alarms_enabled`: 有効なアラーム一覧
- `cpu_high_alarm_arn`: CPU高使用率アラームのARN
- `cpu_low_alarm_arn`: CPU低使用率アラームのARN
- `scale_up_alarm_arn`: スケールアップアラームのARN
- `scale_down_alarm_arn`: スケールダウンアラームのARN

### 通知情報
- `notification_configuration`: 通知設定
- `sns_topic_arn`: SNS通知トピックのARN
- `sns_subscription_arns`: SNSサブスクリプションのARN一覧

### その他
- `effective_tags`: 実際に適用されるタグ
- `asg_name_format`: Auto Scaling Groupの名前形式

## 作成されるリソース

このモジュールは以下のAWSリソースを作成します：

1. **AWS Auto Scaling Group** - メインのオートスケーリンググループ
2. **AWS Autoscaling Policy** - スケールアップ・ダウンポリシー（最大2個）
3. **AWS CloudWatch Metric Alarm** - CPU監視・スケーリング用アラーム（最大4個）
4. **AWS SNS Topic** - 通知用トピック（オプション）
5. **AWS SNS Topic Subscription** - 通知用サブスクリプション（オプション）
6. **AWS Autoscaling Notification** - ASG通知設定（オプション）

合計: **最大10個のリソース**

## セキュリティ考慮事項

- 起動テンプレートでIMDSv2を強制することを推奨します
- セキュリティグループで必要最小限のポートのみを開放してください
- IAMロールは最小権限の原則に従って設定してください
- 通知メールにはセンシティブな情報が含まれる可能性があるため、配信先を制限してください
- 共通タグには機密情報を含めないでください

## パフォーマンス最適化

- `health_check_grace_period`はアプリケーションの起動時間に合わせて調整してください
- `default_cooldown`は適切に設定してスケーリングの頻度を制御してください
- CPU使用率の閾値は実際の負荷パターンに基づいて調整してください
- ターゲット追跡スケーリングを使用することで、より効率的なスケーリングが可能です

## 貢献

このモジュールの改善提案やバグ報告は、プロジェクトのIssueまたはPull Requestでお知らせください。

## ライセンス

このモジュールは MIT License の下で公開されています。

---

**最終更新日**: 2024年12月
**動作確認済みバージョン**: Terraform 1.0+, AWS Provider 5.x
