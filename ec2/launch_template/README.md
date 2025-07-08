# 🚀 EC2 Launch Template Terraform Module

**最新の更新**: 2024年12月 - 完全動作確認済み

Amazon EC2の起動テンプレートを作成するTerraformモジュールです。ECS対応のAmazon Linux 2023 AMIを使用し、統合監視機能とセキュリティ強化を実装します。

## 📋 概要

セキュアで監視機能が統合されたEC2インスタンス起動テンプレートを構築します。ECS最適化AMI、監視エージェント、セキュリティ設定を自動で組み込み、運用効率を向上させます。

## ✨ 2024年12月の特徴

### 🐧 **AMI・インスタンス設定**
- ✅ **Amazon Linux 2023 ECS最適化** - 最新AMI自動選択
- ✅ **セキュリティ強化** - IMDSv2強制、EBS暗号化
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 📊 **統合監視**
- ✅ **CloudWatch Agent** - システムメトリクス・ログ収集
- ✅ **Mackerel Agent** - アプリケーション監視・アラート
- ✅ **自動ツール** - ctop、パフォーマンスツール自動インストール

### 🔐 **セキュリティ機能**
- ✅ **IMDSv2強制** - メタデータセキュリティ強化
- ✅ **EBS暗号化** - デフォルトで暗号化有効
- ✅ **統合タグ戦略** - 一貫したリソース管理

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EC2 Launch Template                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        ┌────────▼─────────┐   ┌────────▼─────────┐   ┌────────▼─────────┐
        │   AMI Selection  │   │  Instance Config │   │   Security       │
        │                  │   │                  │   │                  │
        │ ├─ ECS Optimized │   │ ├─ Instance Type │   │ ├─ IMDSv2        │
        │ ├─ Amazon Linux  │   │ ├─ Key Pair      │   │ ├─ Security Group│
        │ ├─ 2023 Latest   │   │ ├─ EBS Config    │   │ ├─ IAM Profile   │
        │ └─ Auto Update   │   │ └─ User Data     │   │ └─ Encryption    │
        └──────────────────┘   └──────────────────┘   └──────────────────┘
                 │                      │                      │
                 └──────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
           ┌────────▼─────────┐ ┌────────▼─────────┐ ┌────────▼─────────┐
           │   Monitoring     │ │   ECS Integration│ │   User Data      │
           │                  │ │                  │ │                  │
           │ ├─ CloudWatch    │ │ ├─ ECS Agent     │ │ ├─ System Setup  │
           │ ├─ Mackerel      │ │ ├─ Container     │ │ ├─ Monitoring    │
           │ ├─ System Logs   │ │ ├─ Service Disc  │ │ ├─ Tools Install │
           │ └─ App Metrics   │ │ └─ Task Metadata │ │ └─ Configuration │
           └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 🚀 主要機能

### 🐧 **AMI・インスタンス設定**
- **ECS最適化AMI** - Amazon Linux 2023 ECS最適化AMIを自動選択
- **インスタンスタイプ** - t3.micro〜大型インスタンスまで対応
- **EBS暗号化** - デフォルトで暗号化有効
- **IMDSv2強制** - セキュリティ強化設定

### 📊 **監視統合**
- **CloudWatch Agent** - システムメトリクス・ログ収集
- **Mackerel Agent** - アプリケーション監視・アラート
- **ctop** - コンテナ監視ツール自動インストール
- **Parameter Store** - 設定管理の自動化

### 🔐 **セキュリティ機能**
- **セキュリティグループ** - 適切なアクセス制御
- **IAM統合** - インスタンスプロファイル自動設定
- **キーペア** - SSH アクセス管理
- **ユーザーデータ** - 安全な初期設定スクリプト

## 🔧 前提条件

### 📋 必要な環境

| 要件             | バージョン | 説明                 |
| ---------------- | ---------- | -------------------- |
| **Terraform**    | >= 1.0     | 最新の構文・機能対応 |
| **AWS Provider** | >= 5.0     | 最新のAWS機能        |
| **AWS CLI**      | >= 2.0     | 認証・設定確認       |

### 📦 事前準備

| リソース                        | 必須 | 説明                              |
| ------------------------------- | ---- | --------------------------------- |
| **IAMインスタンスプロファイル** | ❌    | ECS・CloudWatch・SSM用権限推奨    |
| **キーペア**                    | ❌    | SSH アクセス用                    |
| **VPC・サブネット**             | ❌    | 指定なしの場合はデフォルトVPC使用 |
| **セキュリティグループ**        | ❌    | 指定なしの場合は自動作成          |

## 🛠️ 使用方法

### 1. 📁 基本セットアップ

```bash
# 設定ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# 設定を編集
vi terraform.tfvars
```

### 2. 📝 基本設定例

```hcl
# プロジェクト基本設定
project = "myproject"
env     = "dev"
app     = "web"

# EC2基本設定
instance_type = "t3.medium"
key_name      = "my-key-pair"
volume_size   = 50

# ECS設定
ecs_cluster_name = "myproject-dev-ecs"
iam_instance_profile_name = "ecsInstanceRole"

# 監視設定
mackerel_api_key = var.mackerel_api_key
mackerel_organization = "myorg"
mackerel_roles = "web,dev"

# CloudWatch設定
cloudwatch_default_namespace = "MyProject/Dev"
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

## 📊 設定項目

### 🔑 必須変数

| 変数名    | 説明                         | デフォルト値  | 必須 |
| --------- | ---------------------------- | ------------- | ---- |
| `project` | プロジェクト名               | `"myproject"` | ✅    |
| `env`     | 環境名（dev, stg, prodなど） | `"dev"`       | ✅    |

### 🖥️ 主要設定

| 変数名                       | 説明                        | デフォルト値 | 開発環境推奨     | 本番環境推奨       |
| ---------------------------- | --------------------------- | ------------ | ---------------- | ------------------ |
| `instance_type`              | EC2インスタンスタイプ       | `"t3.micro"` | `"t3.small"`     | `"t3.medium"` 以上 |
| `key_name`                   | EC2キーペア名               | `""`         | SSH用キーペア    | SSH用キーペア      |
| `volume_size`                | EBSボリュームサイズ（GB）   | `20`         | `30`             | `50` 以上          |
| `ecs_cluster_name`           | ECSクラスター名             | 自動生成     | 既存クラスター名 | 既存クラスター名   |
| `iam_instance_profile_name`  | IAMインスタンスプロファイル | `""`         | 適切なロール設定 | 適切なロール設定   |
| `enable_detailed_monitoring` | 詳細監視の有効化            | `false`      | `false`          | `true`             |

### 📊 監視・アラート設定

| 変数名                         | 説明                     | デフォルト値 | 推奨設定           |
| ------------------------------ | ------------------------ | ------------ | ------------------ |
| `mackerel_api_key`             | MackerelのAPIキー        | `""`         | 監視用APIキー      |
| `mackerel_organization`        | Mackerel組織名           | `""`         | 組織名             |
| `mackerel_roles`               | Mackerelロール           | `""`         | 環境・用途別ロール |
| `cloudwatch_default_namespace` | CloudWatchネームスペース | 自動生成     | プロジェクト固有名 |
| `enable_cloudwatch_agent`      | CloudWatch Agent有効化   | `true`       | `true`             |

### 🌐 ネットワーク設定

| 変数名                | 説明                         | デフォルト値 | 推奨設定               |
| --------------------- | ---------------------------- | ------------ | ---------------------- |
| `vpc_id`              | VPC ID                       | `""`         | 既存VPC ID             |
| `subnet_ids`          | サブネットIDリスト           | `[]`         | プライベートサブネット |
| `security_group_ids`  | セキュリティグループIDリスト | `[]`         | 適切なSG               |
| `associate_public_ip` | パブリックIP自動割り当て     | `false`      | 本番環境では`false`    |

### 💾 ストレージ設定

| 変数名                  | 説明                               | デフォルト値 | 推奨設定                  |
| ----------------------- | ---------------------------------- | ------------ | ------------------------- |
| `volume_type`           | EBSボリュームタイプ                | `"gp3"`      | 本番環境:`"gp3"`          |
| `volume_iops`           | EBS IOPS（gp3/io1/io2用）          | `3000`       | 用途に応じて調整          |
| `volume_throughput`     | EBSスループット（gp3用）           | `125`        | 用途に応じて調整          |
| `volume_encrypted`      | EBS暗号化                          | `true`       | 必ず`true`                |
| `delete_on_termination` | インスタンス削除時のボリューム削除 | `true`       | 開発:`true`, 本番:`false` |

### 🏷️ タグ設定

| 変数名        | 説明                                 | デフォルト値 |
| ------------- | ------------------------------------ | ------------ |
| `common_tags` | すべてのリソースに適用される共通タグ | `{}`         |

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "ec2_launch_template" {
  source = "./ec2/launch_template/terraform"

  # プロジェクト基本設定
  project = "myapp"
  env     = "dev"
  app     = "web"

  # EC2設定
  instance_type = "t3.medium"
  key_name      = "my-key-pair"
  volume_size   = 30

  # ECS設定
  ecs_cluster_name = "myapp-dev-ecs"
  iam_instance_profile_name = "ecsInstanceRole"

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
module "ec2_launch_template_prod" {
  source = "./ec2/launch_template/terraform"

  # プロジェクト基本設定
  project = "webapp"
  env     = "prod"
  app     = "api"

  # EC2設定（本番環境）
  instance_type = "c5.large"
  key_name      = "prod-key-pair"
  volume_size   = 100
  volume_type   = "gp3"
  volume_iops   = 3000
  volume_throughput = 250

  # セキュリティ設定
  enable_detailed_monitoring = true
  enable_nitro_enclave = true

  # ECS設定
  ecs_cluster_name = "webapp-prod-ecs"
  iam_instance_profile_name = "ecsInstanceRole"

  # ネットワーク設定
  vpc_id = "vpc-12345678"
  subnet_ids = [
    "subnet-private1",
    "subnet-private2"
  ]
  security_group_ids = [
    "sg-web-servers",
    "sg-database-access"
  ]
  associate_public_ip = false

  # 監視設定
  mackerel_api_key = var.mackerel_api_key
  mackerel_organization = "mycompany"
  mackerel_roles = "webapp,prod,api"
  cloudwatch_default_namespace = "WebApp/Prod"

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Schedule    = "24x7"
    BackupRequired = "true"
  }
}
```

### 🐳 ECS統合の使用例

```hcl
module "ec2_launch_template_ecs" {
  source = "./ec2/launch_template/terraform"

  # プロジェクト基本設定
  project = "microservices"
  env     = "stg"
  app     = "containers"

  # ECS最適化設定
  instance_type = "m5.xlarge"
  volume_size   = 80
  volume_type   = "gp3"

  # ECS専用設定
  ecs_cluster_name = "microservices-stg-cluster"
  iam_instance_profile_name = "ecsInstanceRole"
  enable_ecs_optimized = true

  # コンテナ監視強化
  enable_cloudwatch_agent = true
  enable_container_insights = true

  # 追加パッケージ
  additional_packages = [
    "docker-compose",
    "htop",
    "iotop"
  ]

  # ECS統合用タグ
  common_tags = {
    Project     = "microservices"
    Environment = "stg"
    Owner       = "container-team"
    ManagedBy   = "terraform"
    ServiceType = "ecs-container-host"
  }
}
```

### 💰 コスト最適化の使用例

```hcl
module "ec2_launch_template_cost_optimized" {
  source = "./ec2/launch_template/terraform"

  # プロジェクト基本設定
  project = "testapp"
  env     = "dev"
  app     = "testing"

  # コスト最適化設定
  instance_type = "t3.micro"
  volume_size   = 20
  volume_type   = "gp3"
  volume_iops   = 3000  # 基本IOPS

  # 簡素な監視
  enable_detailed_monitoring = false
  enable_cloudwatch_agent = true  # 基本監視は維持
  mackerel_api_key = ""  # Mackerel無効

  # 開発用設定
  delete_on_termination = true
  enable_nitro_enclave = false

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
module "ec2_launch_template_secure" {
  source = "./ec2/launch_template/terraform"

  # プロジェクト基本設定
  project = "financial"
  env     = "prod"
  app     = "core"

  # セキュリティ強化設定
  instance_type = "m5.large"
  volume_size   = 100
  volume_encrypted = true
  volume_type   = "gp3"

  # 高セキュリティ設定
  enable_nitro_enclave = true
  enable_detailed_monitoring = true
  associate_public_ip = false

  # IMDSv2強制
  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  # ネットワークセキュリティ
  vpc_id = "vpc-secure-12345678"
  subnet_ids = [
    "subnet-private-secure1",
    "subnet-private-secure2"
  ]
  security_group_ids = [
    "sg-high-security",
    "sg-audit-logging"
  ]

  # セキュリティ監視
  enable_security_monitoring = true
  enable_compliance_logging = true

  # セキュリティ用タグ
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

## 🔧 ユーザーデータスクリプト

### 📋 自動インストールされるツール

```bash
# システム更新
yum update -y

# 基本ツール
yum install -y \
  htop \
  iotop \
  netstat-nat \
  tcpdump \
  wget \
  curl \
  jq \
  git

# コンテナ監視ツール
# ctop - コンテナリアルタイム監視
wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
chmod +x /usr/local/bin/ctop

# CloudWatch Agent（有効時）
if [ "${enable_cloudwatch_agent}" = "true" ]; then
  yum install -y amazon-cloudwatch-agent
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c ssm:${cloudwatch_config_parameter} -s
fi

# Mackerel Agent（API キー設定時）
if [ -n "${mackerel_api_key}" ]; then
  curl -fsSL https://mackerel.io/file/script/amznlinux | sh
  echo 'apikey = "${mackerel_api_key}"' >> /etc/mackerel-agent/mackerel-agent.conf
  echo 'roles = ["${mackerel_roles}"]' >> /etc/mackerel-agent/mackerel-agent.conf
  systemctl enable mackerel-agent
  systemctl start mackerel-agent
fi

# ECS Agent設定（ECS使用時）
if [ -n "${ecs_cluster_name}" ]; then
  echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
  echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  systemctl enable ecs
  systemctl start ecs
fi
```

### 🔧 カスタムユーザーデータ

```hcl
# カスタムユーザーデータの追加
module "ec2_launch_template_custom" {
  source = "./ec2/launch_template/terraform"

  # 基本設定
  project = "webapp"
  env     = "stg"

  # カスタムユーザーデータ
  additional_user_data = [
    "# アプリケーション固有の設定",
    "mkdir -p /app/config",
    "aws s3 cp s3://myapp-config/staging/app.conf /app/config/",
    "systemctl enable myapp",
    "systemctl start myapp"
  ]
}
```

## 🔔 監視・ログ設定

### 📊 CloudWatch設定

```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "MyProject/Dev",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/var/log/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "/aws/ecs/agent",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

### 📈 Mackerel設定

```conf
# /etc/mackerel-agent/mackerel-agent.conf
apikey = "YOUR_API_KEY"
roles = ["webapp:prod:web"]

[plugin.metrics.disk]
command = ["mackerel-plugin-disk"]

[plugin.metrics.load]
command = ["mackerel-plugin-load"]

[plugin.metrics.memory]
command = ["mackerel-plugin-memory"]

[plugin.check.log]
command = ["check-log", "--file", "/var/log/messages", "--pattern", "ERROR"]
```

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題                             | 原因                     | 解決方法                         |
| -------------------------------- | ------------------------ | -------------------------------- |
| **インスタンスが起動しない**     | AMI・キーペアの問題      | AMI ID・キーペア名確認           |
| **ECSクラスターに登録されない**  | IAMロール・ECS設定の問題 | ecsInstanceRole確認・ECS設定確認 |
| **監視エージェントが動作しない** | 権限・設定の問題         | IAM権限・設定ファイル確認        |
| **ユーザーデータが実行されない** | スクリプトエラー         | CloudWatch Logs確認              |

### 🔍 デバッグ手順

```bash
# 1. 起動テンプレート確認
aws ec2 describe-launch-templates \
  --launch-template-names "${PROJECT}-${ENV}-${APP}-lt"

# 2. インスタンス起動状況確認
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PROJECT}-${ENV}-${APP}-*"

# 3. ECS登録状況確認
aws ecs list-container-instances \
  --cluster "${ECS_CLUSTER_NAME}"

# 4. ユーザーデータログ確認
aws logs get-log-events \
  --log-group-name "/aws/ec2/user-data" \
  --log-stream-name "${INSTANCE_ID}"

# 5. システムログ確認
aws logs get-log-events \
  --log-group-name "/aws/ec2/var/log/messages" \
  --log-stream-name "${INSTANCE_ID}"
```

### 🛠️ 設定調整のガイドライン

**パフォーマンス最適化:**
```hcl
# 高パフォーマンス設定
instance_type = "c5.xlarge"
volume_type = "gp3"
volume_iops = 16000
volume_throughput = 1000
enable_detailed_monitoring = true
```

**コスト最適化:**
```hcl
# 低コスト設定
instance_type = "t3.micro"
volume_type = "gp3"
volume_size = 20
enable_detailed_monitoring = false
```

## 📈 パフォーマンス最適化

### 🎯 インスタンスタイプ選択ガイド

| 用途                     | 推奨インスタンスタイプ | vCPU | メモリ  | 説明                   |
| ------------------------ | ---------------------- | ---- | ------- | ---------------------- |
| **開発・テスト**         | t3.micro, t3.small     | 1-2  | 1-2GB   | バースト可能・低コスト |
| **Web アプリケーション** | t3.medium, t3.large    | 2-4  | 4-8GB   | バランス型・汎用       |
| **CPU集約的**            | c5.large, c5.xlarge    | 2-4  | 4-8GB   | 高CPU性能              |
| **メモリ集約的**         | r5.large, r5.xlarge    | 2-4  | 16-32GB | 高メモリ容量           |
| **ストレージ集約的**     | i3.large, i3.xlarge    | 2-4  | 15-30GB | 高速SSD                |

### 💾 EBS最適化設定

```hcl
# 高性能ストレージ設定
locals {
  storage_optimized = {
    volume_type = "gp3"
    volume_size = 100
    volume_iops = 10000
    volume_throughput = 500
    volume_encrypted = true
  }
}

# 標準ストレージ設定
locals {
  storage_standard = {
    volume_type = "gp3"
    volume_size = 30
    volume_iops = 3000
    volume_throughput = 125
    volume_encrypted = true
  }
}
```

## 🔗 出力値

| 出力名                            | 説明                                |
| --------------------------------- | ----------------------------------- |
| `launch_template_id`              | Launch Template ID                  |
| `launch_template_name`            | Launch Template名                   |
| `launch_template_latest_version`  | Launch Template最新バージョン       |
| `launch_template_default_version` | Launch Templateデフォルトバージョン |

## 📝 ライセンス

このモジュールは[MIT License](LICENSE)の下で提供されています。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**テスト状況**: 全機能テスト済み
