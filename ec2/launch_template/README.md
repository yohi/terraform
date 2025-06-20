# EC2 Launch Template Terraform Module

Amazon EC2の起動テンプレートを作成するTerraformモジュールです。ECS対応のAmazon Linux 2023 AMIを使用し、Mackerel・CloudWatch Agentの設定も含みます。

## 特徴

- **ECS最適化**: Amazon Linux 2023 ECS最適化AMIを自動選択
- **設定管理**: Mackerel・CloudWatch AgentをParameter Storeで管理
- **セキュリティ**: EBS暗号化、適切なセキュリティグループ設定
- **監視**: ctop、Mackerel、CloudWatch Agentの自動セットアップ
- **柔軟性**: カスタムユーザーデータ、タグ設定に対応

## 使用方法

### 基本的な使用例

```hcl
module "ec2_launch_template" {
  source = "./ec2/launch_template"

  # プロジェクト基本設定
  project = "myproject"
  env     = "production"
  app     = "web"

  # EC2設定
  instance_type = "t3.medium"
  key_name      = "my-key-pair"
  volume_size   = 50

  # ECS設定
  ecs_cluster_name = "myproject-prod-ecs"
  iam_instance_profile_name = "ecsInstanceRole"

  # Mackerel設定
  mackerel_api_key = var.mackerel_api_key
  mackerel_organization = "myorg"
  mackerel_roles = "web,production"

  # CloudWatch設定
  cloudwatch_default_namespace = "MyProject/Production"

  # タグ設定
  common_tags = {
    Environment = "production"
    Project     = "myproject"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
  }
}
```

### 設定ファイルの準備

1. `terraform.tfvars.example`をコピーして`terraform.tfvars`を作成
2. 必要な値を設定

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集
```

## 必要な IAM 権限

起動されるEC2インスタンスには以下の権限が必要です：

### ECS Task実行用ロール
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Parameter Store・CloudWatch用権限
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:CreateLogStream"
      ],
      "Resource": "*"
    }
  ]
}
```

## 変数の説明

### 必須変数

| 変数名    | 説明                         | デフォルト値  |
| --------- | ---------------------------- | ------------- |
| `project` | プロジェクト名               | `"myproject"` |
| `env`     | 環境名（dev, stg, prodなど） | `"dev"`       |

### 主要変数

| 変数名                         | 説明                      | デフォルト値 |
| ------------------------------ | ------------------------- | ------------ |
| `instance_type`                | EC2インスタンスタイプ     | `"t3.micro"` |
| `key_name`                     | EC2キーペア名             | `""`         |
| `volume_size`                  | EBSボリュームサイズ（GB） | `20`         |
| `ecs_cluster_name`             | ECSクラスター名           | 自動生成     |
| `mackerel_api_key`             | MackerelのAPIキー         | `""`         |
| `cloudwatch_default_namespace` | CloudWatchネームスペース  | 自動生成     |

その他の変数については[variables.tf](./variables.tf)を参照してください。

## 出力値

| 出力名                 | 説明                     |
| ---------------------- | ------------------------ |
| `launch_template_id`   | 起動テンプレートのID     |
| `launch_template_arn`  | 起動テンプレートのARN    |
| `launch_template_name` | 起動テンプレートの名前   |
| `security_group_id`    | セキュリティグループのID |
| `ami_id`               | 使用されたAMIのID        |

## 作成されるリソース

### AWS リソース
- EC2起動テンプレート
- セキュリティグループ
- SSM Parameter Storeパラメータ（Mackerel・CloudWatch設定）

### インストールされるソフトウェア
- Amazon CloudWatch Agent
- Mackerel Agent
- ctop（コンテナ監視ツール）

## トラブルシューティング

### よくある問題

1. **IAMロールが見つからない**
   ```
   Error: InvalidIamInstanceProfileName
   ```
   → `iam_instance_profile_name`で指定したIAMロールが存在することを確認

2. **Parameter Storeアクセス権限エラー**
   ```
   Error: ParameterNotFound
   ```
   → EC2インスタンスのIAMロールにSSM Parameter Storeアクセス権限を追加

3. **AMI取得エラー**
   ```
   Error: Your query returned no results
   ```
   → 指定したリージョンにECS最適化AMIが存在することを確認

### ログの確認

EC2インスタンス起動後、以下のログでセットアップ状況を確認できます：

```bash
# ユーザーデータ実行ログ
sudo tail -f /var/log/user-data.log

# CloudWatch Agent ログ
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Mackerel Agent ログ
sudo tail -f /var/log/mackerel-agent.log
```

## 開発・コントリビューション

### 前提条件
- Terraform >= 1.0
- AWS CLI設定済み
- 適切なAWS権限

### テスト実行
```bash
# 構文チェック
terraform validate

# プランの確認
terraform plan

# 適用（テスト環境）
terraform apply
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 変更履歴

- v1.0.0: 初期リリース
- v1.1.0: CloudWatch Agent対応追加
- v1.2.0: Parameter Store統合
- v1.3.0: Mackerel sysconfig対応
- v2.0.0: コード構造の大幅なリファクタリング
