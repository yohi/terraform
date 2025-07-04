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

| 変数名                      | 説明                                                                            | デフォルト値 |
| --------------------------- | ------------------------------------------------------------------------------- | ------------ |
| `min_size`                  | 最小インスタンス数（0に設定することで完全なスケールダウンが可能）                | `0`          |
| `desired_capacity`          | 希望インスタンス数（最大インスタンス数は2倍に自動設定）                          | `2`          |
| `health_check_type`         | ヘルスチェックタイプ（EC2またはELB）                                            | `"EC2"`      |
| `health_check_grace_period` | ヘルスチェック猶予期間（秒）                                                    | `300`        |
| `default_cooldown`          | デフォルトクールダウン時間（秒）                                                | `300`        |

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
  env     = "prod"
  app     = "frontend"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # スケーリング設定
  # 最小インスタンス数: 0（スケールダウンが可能）
  # 希望インスタンス数: 4
  # 最大インスタンス数: 8（desired_capacityの2倍）
  min_size = 0
  desired_capacity = 4

  # 通知設定
  enable_notifications = true
  notification_email_addresses = [
    "devops@company.com",
    "alerts@company.com"
  ]

  # タグ設定
  common_tags = {
    Environment = "prod"
    Project     = "my-webapp"
    Owner       = "DevOps Team"
  }
}
```

### ALBとの統合例

```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "my-webapp"
  env     = "prod"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # ALBターゲットグループ
  target_group_arns = [
    "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/my-app-tg/1234567890123456"
  ]

  # ヘルスチェック（ALB使用時）
  health_check_type = "ELB"
  health_check_grace_period = 300
}
```

### ターゲット追跡スケーリング例

```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "my-webapp"
  env     = "prod"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # ターゲット追跡スケーリング
  enable_scale_up_policy = true
  scale_up_policy_type   = "TargetTrackingScaling"
  target_tracking_target_value = 50.0
  target_tracking_metric_type  = "ASGAverageCPUUtilization"
}
```

### カスタムサブネット指定例

```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "my-webapp"
  env     = "prod"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # カスタムサブネット指定
  subnet_ids = [
    "subnet-12345678",
    "subnet-87654321",
    "subnet-abcdef12"
  ]

  # タグ設定
  common_tags = {
    Environment = "prod"
    Project     = "my-webapp"
    Owner       = "DevOps Team"
  }

  # 追加タグ（インスタンスにプロパゲート）
  additional_tags = {
    "Backup" = {
      propagate_at_launch = true
    }
    "Monitoring" = {
      propagate_at_launch = true
    }
  }
}
```

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

## トラブルシューティング

### よくある問題

1. **起動テンプレートが見つからない**
   - `launch_template_id` が正しく設定されているか確認してください
   - 起動テンプレートが同じリージョンに存在するか確認してください

2. **インスタンスが起動しない**
   - 起動テンプレートのセキュリティグループ設定を確認してください
   - サブネットの設定を確認してください
   - IAMロールの権限を確認してください

3. **スケーリングが動作しない**
   - CloudWatchアラームの設定を確認してください
   - スケーリングポリシーが正しく設定されているか確認してください
   - クールダウン時間の設定を確認してください

4. **通知が届かない**
   - SNSトピックのサブスクリプションが確認済みか確認してください
   - メールアドレスが正しく設定されているか確認してください

5. **タグが正しく適用されない**
   - `common_tags`は全リソースに適用されます
   - `additional_tags`はオートスケーリンググループのインスタンスにのみ適用されます
   - `propagate_at_launch`の設定を確認してください

### デバッグコマンド

```bash
# Terraformの構文チェック
terraform validate

# プランの詳細表示
terraform plan -detailed-exitcode

# 状態の確認
terraform show

# CloudWatchログの確認
aws logs describe-log-groups --log-group-name-prefix "/aws/autoscaling"

# Auto Scaling Groupの活動履歴
aws autoscaling describe-scaling-activities --auto-scaling-group-name <ASG_NAME>

# アラームの状態確認
aws cloudwatch describe-alarms --alarm-names <ALARM_NAME>
```

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
