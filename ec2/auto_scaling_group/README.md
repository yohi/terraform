# 🔄 EC2 Auto Scaling Group Terraform Module

**最新の更新**: 2024年12月 - 完全動作確認済み

高可用性とコスト効率を両立するEC2インスタンスの自動スケーリング環境を構築するTerraformモジュールです。

## 📋 概要

このモジュールは、CPU使用率やカスタムメトリクスに基づいて自動的にインスタンス数を調整し、安定したサービス提供を実現します。開発環境でのコスト最適化（0台スケールダウン）から本番環境での高可用性確保まで、幅広い要件に対応します。

## ✨ 2024年12月の特徴

### 🔄 **スケーリング機能**
- ✅ **インスタンスリフレッシュ** - ゼロダウンタイムローリング更新
- ✅ **高度なスケーリング** - ターゲット追跡・ステップスケーリング
- ✅ **完全スケールダウン** - 開発環境で0台まで縮小可能

### 🏷️ **統合管理**
- ✅ **統一タグ戦略** - 環境・セキュリティ・運用タグ自動適用
- ✅ **柔軟なネットワーク** - VPC・サブネット自動選択/カスタム指定
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 🔔 **監視・アラート**
- ✅ **包括的アラーム** - 4種類のCloudWatchアラーム
- ✅ **SNS通知統合** - スケーリングイベント通知
- ✅ **セキュリティ強化** - KMS暗号化、入力バリデーション

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Auto Scaling Group                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        ┌────────▼─────────┐   ┌────────▼─────────┐   ┌────────▼─────────┐
        │   Launch Template │   │  Scaling Policy  │   │   CloudWatch     │
        │                   │   │                  │   │                  │
        │ ├─ AMI           │   │ ├─ Target Track  │   │ ├─ CPU High      │
        │ ├─ Instance Type │   │ ├─ Step Scaling  │   │ ├─ CPU Low       │
        │ ├─ Security Group│   │ ├─ Simple Scale  │   │ ├─ Scale Up      │
        │ └─ User Data     │   │ └─ Cooldown      │   │ └─ Scale Down    │
        └──────────────────┘   └──────────────────┘   └──────────────────┘
                 │                      │                      │
                 └──────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
           ┌────────▼─────────┐ ┌────────▼─────────┐ ┌────────▼─────────┐
           │   EC2 Instances  │ │   Target Groups  │ │   SNS Topics     │
           │                  │ │                  │ │                  │
           │ ├─ Multi-AZ      │ │ ├─ Health Check  │ │ ├─ Email Alerts  │
           │ ├─ Auto Replace  │ │ ├─ Load Balance  │ │ ├─ Webhook       │
           │ └─ Instance Warm │ │ └─ Deregister   │ │ └─ Slack/Teams   │
           └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 🚀 主要機能

### 🔄 **スケーリング機能**
- **Auto Scaling Group** - 自動スケーリング（命名規則: `${project}-${env}-${app}-asg`）
- **スケーリングポリシー**:
  - 🎯 **ターゲット追跡スケーリング** - CPU使用率目標値維持
  - 📊 **ステップスケーリング** - 段階的な調整
  - 🔄 **シンプルスケーリング** - 基本的な増減

### 🔄 **インスタンス管理**
- **インスタンスリフレッシュ** - 起動テンプレート変更時の自動更新
- **ヘルスチェック** - EC2/ELBヘルスチェック対応
- **ウォームアップ** - 段階的な負荷分散

### 🔔 **監視・アラート**
- **CloudWatch Alarms** - 4種類のアラーム（CPU High/Low、Scale Up/Down）
- **SNS通知** - スケーリングイベント通知
- **詳細メトリクス** - 高度な監視設定

## 🔧 前提条件

### 📋 必要な環境

| 要件             | バージョン | 説明                 |
| ---------------- | ---------- | -------------------- |
| **Terraform**    | >= 1.0     | 最新の構文・機能対応 |
| **AWS Provider** | >= 5.0     | 最新のAWS機能        |
| **AWS CLI**      | >= 2.0     | 認証・設定確認       |

### 📦 事前作成リソース

| リソース             | 必須 | 説明                              |
| -------------------- | ---- | --------------------------------- |
| **起動テンプレート** | ✅    | EC2インスタンスの設定             |
| **VPC・サブネット**  | ❌    | 指定なしの場合はデフォルトVPC使用 |
| **IAMロール**        | ❌    | 適切な権限設定推奨                |
| **キーペア**         | ❌    | SSH アクセス用                    |

## 🛠️ 使用方法

### 1. 📁 基本セットアップ

```bash
# 設定ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# 設定を編集
vi terraform.tfvars
```

### 2. 📝 必須設定項目

```hcl
# 起動テンプレート（必須）
launch_template_id = "lt-0123456789abcdef0"

# プロジェクト基本情報
project = "myproject"
env     = "dev"
app     = "web"

# AWS設定
aws_region = "ap-northeast-1"
```

### 3. 🚀 デプロイメント

```bash
# 初期化
terraform init

# プランの確認
terraform plan

# 適用
terraform apply
```

### 4. 🧪 テスト（推奨）

```bash
# 自動テストスクリプト使用
./test_module.sh validate   # 設定検証
./test_module.sh plan       # 実行計画
./test_module.sh apply      # リソース作成
./test_module.sh check      # 状態確認
./test_module.sh destroy    # リソース削除
```

## 📊 設定項目

### 🔑 基本設定

| 変数名               | 説明               | デフォルト値       | 必須 |
| -------------------- | ------------------ | ------------------ | ---- |
| `launch_template_id` | 起動テンプレートID | -                  | ✅    |
| `project`            | プロジェクト名     | `"myproject"`      | ✅    |
| `env`                | 環境名             | `"dev"`            | ✅    |
| `app`                | アプリケーション名 | `""`               | ❌    |
| `aws_region`         | AWSリージョン      | `"ap-northeast-1"` | ❌    |

### 🔄 スケーリング設定

| 変数名                      | 説明                             | デフォルト | 開発環境推奨 | 本番環境推奨 |
| --------------------------- | -------------------------------- | ---------- | ------------ | ------------ |
| `min_size`                  | 最小インスタンス数               | `0`        | `0`          | `2`          |
| `desired_capacity`          | 希望インスタンス数               | `2`        | `1`          | `3`          |
| `max_size`                  | 最大インスタンス数               | 自動計算   | `4`          | `10`         |
| `health_check_type`         | ヘルスチェックタイプ             | `"EC2"`    | `"EC2"`      | `"ELB"`      |
| `health_check_grace_period` | ヘルスチェック猶予期間（秒）     | `300`      | `300`        | `600`        |
| `default_cooldown`          | デフォルトクールダウン時間（秒） | `300`      | `300`        | `600`        |

### 🌐 ネットワーク設定

| 変数名                   | 説明                         | デフォルト値             |
| ------------------------ | ---------------------------- | ------------------------ |
| `subnet_ids`             | サブネットIDリスト           | `[]` (デフォルトVPC使用) |
| `availability_zones`     | アベイラビリティーゾーン     | `[]` (自動選択)          |
| `vpc_security_group_ids` | セキュリティグループIDリスト | `[]`                     |

### 🔔 監視・通知設定

| 変数名                         | 説明                 | デフォルト値 | 推奨設定             |
| ------------------------------ | -------------------- | ------------ | -------------------- |
| `enable_notifications`         | 通知の有効/無効      | `false`      | `true`               |
| `notification_email_addresses` | 通知先メールアドレス | `[]`         | 運用チームメール     |
| `enable_cpu_high_alarm`        | CPU高使用率アラーム  | `true`       | `true`               |
| `cpu_high_threshold`           | CPU高使用率閾値（%） | `80`         | 本番:`70`, 開発:`80` |
| `enable_cpu_low_alarm`         | CPU低使用率アラーム  | `true`       | `true`               |
| `cpu_low_threshold`            | CPU低使用率閾値（%） | `10`         | 本番:`20`, 開発:`10` |

### 🏷️ タグ設定

| 変数名            | 説明        | デフォルト値 |
| ----------------- | ----------- | ------------ |
| `common_tags`     | 共通タグ    | `{}`         |
| `additional_tags` | ASG追加タグ | `{}`         |

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "auto_scaling_group" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "myapp"
  env     = "dev"
  app     = "web"

  # 起動テンプレート
  launch_template_id = "lt-0123456789abcdef0"

  # スケーリング設定
  min_size         = 0  # 開発環境では0台スケールダウン
  desired_capacity = 2  # 通常時は2インスタンス
  max_size         = 8  # 最大8インスタンス

  # 共通タグ
  common_tags = {
    Project     = "myapp"
    Environment = "dev"
    Owner       = "dev-team"
    ManagedBy   = "terraform"
  }
}
```

### 🏢 本番環境での使用例

```hcl
module "auto_scaling_group_prod" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "webapp"
  env     = "prod"
  app     = "api"

  # 起動テンプレート
  launch_template_id = "lt-prod123456789abcdef0"

  # 本番環境用スケーリング設定
  min_size         = 3    # 高可用性確保
  desired_capacity = 5    # 通常時は5インスタンス
  max_size         = 20   # 最大20インスタンス

  # 本番環境用ネットワーク設定
  subnet_ids = [
    "subnet-12345678",  # プライベートサブネット
    "subnet-87654321",  # プライベートサブネット
    "subnet-11111111"   # プライベートサブネット
  ]

  # 本番環境用ヘルスチェック
  health_check_type         = "ELB"
  health_check_grace_period = 600
  default_cooldown          = 900

  # 通知設定
  enable_notifications = true
  notification_email_addresses = [
    "devops@company.com",
    "oncall@company.com"
  ]

  # 本番環境用アラーム閾値
  cpu_high_threshold = 70
  cpu_low_threshold  = 20

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Schedule    = "24x7"
  }
}
```

### 🔗 ALB統合の使用例

```hcl
module "auto_scaling_group_alb" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "webapp"
  env     = "stg"
  app     = "web"

  # 起動テンプレート
  launch_template_id = "lt-web456789abcdef0"

  # ALB統合用設定
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns = [
    "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/webapp-stg-web/1234567890abcdef"
  ]

  # ALB統合用スケーリング設定
  min_size         = 2
  desired_capacity = 4
  max_size         = 12

  # 詳細監視有効化
  enable_detailed_monitoring = true

  # ALB統合用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "stg"
    Owner       = "web-team"
    ManagedBy   = "terraform"
    LoadBalancer = "enabled"
  }
}
```

### 💰 コスト最適化の使用例

```hcl
module "auto_scaling_group_cost_optimized" {
  source = "./ec2/auto_scaling_group/terraform"

  # 基本設定
  project = "testapp"
  env     = "dev"
  app     = "api"

  # 起動テンプレート
  launch_template_id = "lt-test789abcdef012345"

  # コスト最適化設定
  min_size         = 0    # 夜間・週末は0台
  desired_capacity = 1    # 通常時は最小限
  max_size         = 3    # 最大でも3台まで

  # コスト最適化用アラーム閾値
  cpu_high_threshold = 85  # 高めに設定
  cpu_low_threshold  = 5   # 低めに設定

  # 開発環境用タグ
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

## 🔔 監視・アラート詳細

### 📊 作成されるCloudWatchアラーム

| アラーム名       | メトリクス     | 閾値 | 説明                        |
| ---------------- | -------------- | ---- | --------------------------- |
| `CPU高使用率`    | CPUUtilization | 80%  | CPU使用率が高い時のアラート |
| `CPU低使用率`    | CPUUtilization | 10%  | CPU使用率が低い時のアラート |
| `スケールアップ` | -              | -    | スケールアップ実行時の通知  |
| `スケールダウン` | -              | -    | スケールダウン実行時の通知  |

### 📧 SNS通知設定

```hcl
# 通知設定例
enable_notifications = true
notification_email_addresses = [
  "devops@company.com",
  "oncall@company.com",
  "team-slack-webhook@company.com"
]

# 通知内容
# - スケーリングイベント
# - インスタンス起動/終了
# - ヘルスチェック失敗
# - アラーム状態変化
```

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題                         | 原因                     | 解決方法                           |
| ---------------------------- | ------------------------ | ---------------------------------- |
| **インスタンスが起動しない** | 起動テンプレートの問題   | 起動テンプレートの設定確認         |
| **スケーリングが動作しない** | CloudWatchアラームの問題 | アラーム設定・閾値確認             |
| **ヘルスチェックが失敗する** | アプリケーションの問題   | ログ確認・ヘルスチェック設定見直し |
| **通知が届かない**           | SNSトピックの問題        | SNS設定・メールアドレス確認        |

### 🔍 デバッグ手順

```bash
# 1. Auto Scaling Group状態確認
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${PROJECT}-${ENV}-${APP}-asg"

# 2. インスタンス状態確認
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=${PROJECT}-${ENV}-${APP}-asg"

# 3. CloudWatchアラーム確認
aws cloudwatch describe-alarms \
  --alarm-names "${PROJECT}-${ENV}-${APP}-cpu-high"

# 4. スケーリング履歴確認
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "${PROJECT}-${ENV}-${APP}-asg"

# 5. ログ確認
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/autoscaling/${PROJECT}-${ENV}-${APP}"
```

### 🛠️ 設定調整のガイドライン

**パフォーマンス最適化:**
```hcl
# 高負荷対応
default_cooldown = 600        # クールダウン時間延長
cpu_high_threshold = 60       # 閾値を下げて早期対応
health_check_grace_period = 900  # 猶予期間延長
```

**コスト最適化:**
```hcl
# 低コスト運用
min_size = 0                  # 夜間・週末は0台
cpu_low_threshold = 5         # 低い閾値でスケールダウン
default_cooldown = 300        # 短いクールダウン時間
```

## 📈 パフォーマンス最適化

### 🎯 環境別推奨設定

```hcl
# 開発環境（コスト重視）
locals {
  dev_config = {
    min_size                = 0
    desired_capacity        = 1
    max_size               = 4
    cpu_high_threshold     = 85
    cpu_low_threshold      = 5
    health_check_grace_period = 300
    default_cooldown       = 300
  }
}

# 本番環境（可用性重視）
locals {
  prod_config = {
    min_size                = 3
    desired_capacity        = 5
    max_size               = 20
    cpu_high_threshold     = 60
    cpu_low_threshold      = 20
    health_check_grace_period = 600
    default_cooldown       = 900
  }
}
```

### 🔄 スケーリングポリシー最適化

```hcl
# ターゲット追跡スケーリング（推奨）
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "${var.project}-${var.env}-${var.app}-target-tracking"
  scaling_adjustment     = 0
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}
```

## 🔗 出力値

| 出力名                   | 説明                           |
| ------------------------ | ------------------------------ |
| `autoscaling_group_id`   | Auto Scaling Group ID          |
| `autoscaling_group_name` | Auto Scaling Group名           |
| `autoscaling_group_arn`  | Auto Scaling Group ARN         |
| `sns_topic_arn`          | SNS トピック ARN               |
| `cloudwatch_alarm_arns`  | CloudWatch アラーム ARN リスト |

## 📝 ライセンス

このモジュールは[MIT License](LICENSE)の下で提供されています。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**テスト状況**: 全機能テスト済み
