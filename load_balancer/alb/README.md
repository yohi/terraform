# 🌐 Application Load Balancer (ALB) for ECS

**最新の更新**: 2024年12月 - 完全動作確認済み

ECS統合に特化したApplication Load Balancer (ALB)を構築するTerraformモジュールです。IPベースターゲットグループ、SSL終端、ヘルスチェック最適化、セキュリティグループ統合を自動化し、スケーラブルなWebアプリケーションの運用を支援します。

## 📋 概要

ECS最適化されたロードバランサー環境を構築します。SSL証明書管理、ヘルスチェック設定、ECSサービス統合、セキュリティグループ設定を自動化し、本格的なWebアプリケーションの運用を支援します。

## ✨ 2024年12月の特徴

### 🌐 **ロードバランサー機能**
- ✅ **ECS最適化** - IPベースターゲットグループ・高速ヘルスチェック
- ✅ **SSL終端** - HTTPS対応・自動リダイレクト
- ✅ **動作確認済み** - Terraform 1.0+, AWS Provider 5.x

### 🔐 **セキュリティ機能**
- ✅ **SSL証明書統合** - ACM証明書自動設定
- ✅ **セキュリティグループ** - 適切なアクセス制御
- ✅ **HTTPS強制** - HTTP自動リダイレクト

### 🔧 **運用機能**
- ✅ **ECS統合** - 自動ターゲット登録・除去
- ✅ **ヘルスチェック最適化** - ECS用設定
- ✅ **統合タグ戦略** - 一貫したリソース管理

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Application Load Balancer                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        ┌────────▼─────────┐   ┌────────▼─────────┐   ┌────────▼─────────┐
        │   Load Balancer  │   │   Target Group   │   │   Security       │
        │   Configuration  │   │   Management     │   │   Configuration  │
        │                  │   │                  │   │                  │
        │ ├─ Multi-AZ      │   │ ├─ IP-based      │   │ ├─ HTTP/HTTPS    │
        │ ├─ Public/Private│   │ ├─ Health Check  │   │ ├─ IPv4/IPv6     │
        │ ├─ Scheme        │   │ ├─ Deregistration│   │ ├─ Ingress Rules │
        │ └─ Security Group│   │ └─ ECS Integration│   │ └─ Port 80/443   │
        └──────────────────┘   └──────────────────┘   └──────────────────┘
                 │                      │                      │
                 └──────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
           ┌────────▼─────────┐ ┌────────▼─────────┐ ┌────────▼─────────┐
           │   HTTP Listener  │ │   HTTPS Listener │ │   ECS Service    │
           │   (Port 80)      │ │   (Port 443)     │ │   Integration    │
           │                  │ │                  │ │                  │
           │ ├─ 301 Redirect  │ │ ├─ SSL Termination│ │ ├─ Auto Register │
           │ ├─ to HTTPS      │ │ ├─ Certificate   │ │ ├─ Health Check  │
           │ └─ Security      │ │ ├─ Default Action│ │ ├─ Auto Deregister│
           │   Enhancement    │ │ └─ Forwarding    │ │ └─ Task Lifecycle │
           └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 🚀 主要機能

### 🌐 **ロードバランサー機能**
- **マルチAZ配置** - 高可用性・障害対応
- **IPベースターゲットグループ** - ECS Fargate最適化
- **HTTP/HTTPS対応** - SSL終端・自動リダイレクト
- **セキュリティグループ統合** - 適切なアクセス制御

### 🔐 **セキュリティ機能**
- **SSL証明書統合** - ACM証明書自動設定
- **HTTPS強制** - HTTP自動リダイレクト（301）
- **セキュリティグループ** - ポート80/443の適切な制御
- **IPv4/IPv6対応** - 現代的なネットワーク対応

### 🔧 **ECS統合機能**
- **自動ターゲット登録** - ECSタスク起動時自動登録
- **ヘルスチェック最適化** - ECS用設定（15秒間隔）
- **高速デレジストレーション** - 30秒でタスク切り離し
- **タスクライフサイクル** - 起動・停止時の自動処理

### 📊 **監視・運用機能**
- **CloudWatch統合** - メトリクス・ログ自動収集
- **アクセスログ** - S3バケット自動出力
- **統合タグ戦略** - 一貫したリソース管理
- **運用コマンド** - AWS CLI操作自動化

## 🔧 前提条件

### 📋 必要な環境

| 要件             | バージョン | 説明                 |
| ---------------- | ---------- | -------------------- |
| **Terraform**    | >= 1.0     | 最新の構文・機能対応 |
| **AWS Provider** | >= 5.0     | 最新のALB機能        |
| **AWS CLI**      | >= 2.0     | 認証・操作用         |

### 🔑 必要なリソース

| リソース          | 必須 | 説明                              |
| ----------------- | ---- | --------------------------------- |
| **VPC**           | ✅    | ALB配置用VPC                      |
| **サブネット**    | ✅    | 最低2つのAZのパブリックサブネット |
| **SSL証明書**     | ✅    | ACM証明書（HTTPS用）              |
| **ECSクラスター** | ❌    | 統合時に必要                      |

## 📊 設定項目

### 🔑 必須変数

| 変数名                | 説明                    | デフォルト値 | 必須 |
| --------------------- | ----------------------- | ------------ | ---- |
| `project`             | プロジェクト名          | `""`         | ✅    |
| `env`                 | 環境名（dev, stg, prd） | `""`         | ✅    |
| `vpc_id`              | VPC ID                  | `""`         | ✅    |
| `subnet_ids`          | サブネットIDリスト      | `[]`         | ✅    |
| `ssl_certificate_arn` | SSL証明書ARN            | `""`         | ✅    |

### 🌐 ALB基本設定

| 変数名                       | 説明                   | デフォルト値    | 開発環境推奨    | 本番環境推奨    |
| ---------------------------- | ---------------------- | --------------- | --------------- | --------------- |
| `alb_name`                   | ALB名                  | 自動生成        | 自動生成        | 自動生成        |
| `internal`                   | 内部ALB                | `false`         | `false`         | 環境による      |
| `load_balancer_type`         | ロードバランサータイプ | `"application"` | `"application"` | `"application"` |
| `ip_address_type`            | IPアドレスタイプ       | `"ipv4"`        | `"ipv4"`        | `"dualstack"`   |
| `enable_deletion_protection` | 削除保護               | `false`         | `false`         | `true`          |

### 🎯 ターゲットグループ設定

| 変数名                  | 説明                         | デフォルト値 | 推奨設定               |
| ----------------------- | ---------------------------- | ------------ | ---------------------- |
| `target_group_name`     | ターゲットグループ名         | 自動生成     | 自動生成               |
| `target_type`           | ターゲットタイプ             | `"ip"`       | `"ip"` (ECS用)         |
| `target_group_port`     | ターゲットグループポート     | `80`         | アプリケーションポート |
| `target_group_protocol` | ターゲットグループプロトコル | `"HTTP"`     | `"HTTP"`               |
| `deregistration_delay`  | デレジストレーション遅延     | `30`         | ECS用に最適化          |

### 🔍 ヘルスチェック設定

| 変数名                  | 説明                       | デフォルト値     | 推奨設定                 |
| ----------------------- | -------------------------- | ---------------- | ------------------------ |
| `health_check_enabled`  | ヘルスチェック有効化       | `true`           | `true`                   |
| `health_check_path`     | ヘルスチェックパス         | `"/"`            | アプリケーション固有パス |
| `health_check_port`     | ヘルスチェックポート       | `"traffic-port"` | `"traffic-port"`         |
| `health_check_protocol` | ヘルスチェックプロトコル   | `"HTTP"`         | `"HTTP"`                 |
| `health_check_interval` | ヘルスチェック間隔         | `15`             | ECS用に最適化            |
| `health_check_timeout`  | ヘルスチェックタイムアウト | `10`             | ECS用に最適化            |
| `healthy_threshold`     | 正常しきい値               | `2`              | `2`                      |
| `unhealthy_threshold`   | 異常しきい値               | `3`              | `3`                      |

### 🔐 セキュリティ設定

| 変数名                     | 説明                   | デフォルト値    | 推奨設定         |
| -------------------------- | ---------------------- | --------------- | ---------------- |
| `security_group_name`      | セキュリティグループ名 | 自動生成        | 自動生成         |
| `allowed_cidr_blocks`      | 許可CIDRブロック       | `["0.0.0.0/0"]` | 必要に応じて制限 |
| `allowed_ipv6_cidr_blocks` | 許可IPv6 CIDRブロック  | `["::/0"]`      | 必要に応じて制限 |

### 📊 ログ・監視設定

| 変数名               | 説明                       | デフォルト値        | 推奨設定             |
| -------------------- | -------------------------- | ------------------- | -------------------- |
| `enable_access_logs` | アクセスログ有効化         | `false`             | 本番環境では`true`   |
| `access_logs_bucket` | アクセスログS3バケット     | `""`                | 専用バケット         |
| `access_logs_prefix` | アクセスログプレフィックス | `"alb-access-logs"` | 環境別プレフィックス |

### 🏷️ タグ設定

| 変数名        | 説明                                 | デフォルト値 |
| ------------- | ------------------------------------ | ------------ |
| `common_tags` | すべてのリソースに適用される共通タグ | `{}`         |

## 💡 使用例

### 📚 基本的な使用例

```hcl
module "alb" {
  source = "./load_balancer/alb/terraform"

  # プロジェクト基本設定
  project = "webapp"
  env     = "dev"

  # ネットワーク設定
  vpc_id = "vpc-12345678"
  subnet_ids = [
    "subnet-12345678",  # ap-northeast-1a
    "subnet-87654321"   # ap-northeast-1c
  ]

  # SSL証明書設定
  ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

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
module "alb_prod" {
  source = "./load_balancer/alb/terraform"

  # プロジェクト基本設定
  project = "webapp"
  env     = "prod"

  # ネットワーク設定
  vpc_id = "vpc-12345678"
  subnet_ids = [
    "subnet-public1",   # ap-northeast-1a
    "subnet-public2",   # ap-northeast-1c
    "subnet-public3"    # ap-northeast-1d
  ]

  # SSL証明書設定
  ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/prod-cert-12345678"

  # 本番環境設定
  ip_address_type = "dualstack"  # IPv4/IPv6対応
  enable_deletion_protection = true

  # ヘルスチェック設定
  health_check_path = "/health"
  health_check_interval = 10
  health_check_timeout = 5
  healthy_threshold = 2
  unhealthy_threshold = 2

  # アクセスログ設定
  enable_access_logs = true
  access_logs_bucket = "webapp-prod-alb-logs"
  access_logs_prefix = "prod-alb-access-logs"

  # セキュリティ設定
  allowed_cidr_blocks = [
    "10.0.0.0/8",     # 内部ネットワーク
    "172.16.0.0/12",  # 内部ネットワーク
    "192.168.0.0/16"  # 内部ネットワーク
  ]

  # 本番環境用タグ
  common_tags = {
    Project     = "webapp"
    Environment = "prod"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    CriticalService = "true"
  }
}
```

### 🔧 ECS統合の使用例

```hcl
# ALB作成
module "alb" {
  source = "./load_balancer/alb/terraform"

  project = "webapp"
  env     = "stg"

  vpc_id = "vpc-12345678"
  subnet_ids = [
    "subnet-public1",
    "subnet-public2"
  ]

  ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/stg-cert-12345678"

  # ECS用ヘルスチェック最適化
  health_check_path = "/api/health"
  health_check_interval = 15
  health_check_timeout = 10
  target_group_port = 8080

  common_tags = {
    Project     = "webapp"
    Environment = "stg"
    Owner       = "qa-team"
    ManagedBy   = "terraform"
  }
}

# ECSサービス（ALB統合）
module "ecs_service" {
  source = "./ecs/service/terraform"

  project_name = "webapp"
  environment  = "stg"
  app          = "api"
  cluster_name = "webapp-stg-ecs"

  # ALB統合設定
  target_group_arn = module.alb.target_group_arn
  load_balancer_container_port = 8080
  health_check_grace_period_seconds = 60

  container_image = "webapp-api:latest"
  container_port  = 8080
  desired_count   = 3

  # ALB作成後にサービス作成
  depends_on = [module.alb]
}
```

### 🌐 内部ALBの使用例

```hcl
module "internal_alb" {
  source = "./load_balancer/alb/terraform"

  # プロジェクト基本設定
  project = "internal-api"
  env     = "prod"

  # 内部ALB設定
  internal = true

  # ネットワーク設定（プライベートサブネット）
  vpc_id = "vpc-12345678"
  subnet_ids = [
    "subnet-private1",
    "subnet-private2"
  ]

  # 内部用SSL証明書
  ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/internal-cert-12345678"

  # 内部ネットワーク制限
  allowed_cidr_blocks = [
    "10.0.0.0/8"    # 内部ネットワークのみ
  ]

  # 内部API用タグ
  common_tags = {
    Project     = "internal-api"
    Environment = "prod"
    Owner       = "backend-team"
    ManagedBy   = "terraform"
    NetworkType = "internal"
  }
}
```

### 🔐 セキュリティ強化の使用例

```hcl
module "secure_alb" {
  source = "./load_balancer/alb/terraform"

  # プロジェクト基本設定
  project = "financial"
  env     = "prod"

  # ネットワーク設定
  vpc_id = "vpc-secure-12345678"
  subnet_ids = [
    "subnet-secure-public1",
    "subnet-secure-public2"
  ]

  # 高セキュリティ設定
  enable_deletion_protection = true
  ip_address_type = "ipv4"  # IPv4のみ（セキュリティ要件）

  # SSL証明書設定
  ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/financial-prod-cert"

  # 厳格なアクセス制御
  allowed_cidr_blocks = [
    "203.0.113.0/24",  # 本社IP
    "198.51.100.0/24"  # データセンターIP
  ]

  # セキュリティ監査用ログ
  enable_access_logs = true
  access_logs_bucket = "financial-prod-security-logs"
  access_logs_prefix = "alb-security-audit"

  # 厳格なヘルスチェック
  health_check_path = "/secure/health"
  health_check_interval = 10
  healthy_threshold = 3
  unhealthy_threshold = 2

  # セキュリティ用タグ
  common_tags = {
    Project     = "financial"
    Environment = "prod"
    Owner       = "security-team"
    ManagedBy   = "terraform"
    SecurityLevel = "high"
    ComplianceRequired = "true"
  }
}
```

## 🔧 ECSサービスとの統合

### 📋 ECSサービスでの設定例

```hcl
resource "aws_ecs_service" "web" {
  name            = "${var.project}-${var.env}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  # ALBとの統合
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "web"
    container_port   = 80
  }

  # ネットワーク設定
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # ALBのヘルスチェック依存
  health_check_grace_period_seconds = 60

  depends_on = [
    module.alb,
    aws_ecs_task_definition.web
  ]
}
```

### 🔍 ヘルスチェック設定詳細

```hcl
# ALB用ヘルスチェック設定
health_check_enabled  = true
health_check_path     = "/health"
health_check_port     = "traffic-port"
health_check_protocol = "HTTP"

# ECS用最適化設定
health_check_interval    = 15  # 15秒間隔
health_check_timeout     = 10  # 10秒タイムアウト
healthy_threshold        = 2   # 2回成功で正常
unhealthy_threshold      = 3   # 3回失敗で異常
deregistration_delay     = 30  # 30秒で除去
```

## 🔧 トラブルシューティング

### 📋 よくある問題と解決方法

| 問題                   | 原因                       | 解決方法                    |
| ---------------------- | -------------------------- | --------------------------- |
| **ALBが作成されない**  | サブネット・VPC設定の問題  | 最低2つのAZのサブネット確認 |
| **SSL証明書エラー**    | ACM証明書の問題            | 証明書ARN・リージョン確認   |
| **ヘルスチェック失敗** | ターゲットの応答問題       | アプリケーション・パス確認  |
| **ECS統合失敗**        | セキュリティグループの問題 | ALB-ECS間通信許可確認       |
| **403/404エラー**      | リスナールールの問題       | デフォルトアクション確認    |

### 🔍 デバッグ手順

```bash
# 1. ALB状態確認
aws elbv2 describe-load-balancers --names ${ALB_NAME}

# 2. ターゲットグループ確認
aws elbv2 describe-target-groups --load-balancer-arn ${ALB_ARN}

# 3. ターゲット健全性確認
aws elbv2 describe-target-health --target-group-arn ${TARGET_GROUP_ARN}

# 4. リスナー設定確認
aws elbv2 describe-listeners --load-balancer-arn ${ALB_ARN}

# 5. セキュリティグループ確認
aws ec2 describe-security-groups --group-ids ${SECURITY_GROUP_ID}
```

### 🛠️ 設定調整のガイドライン

**パフォーマンス最適化:**
```hcl
# 高パフォーマンス設定
health_check_interval = 10
health_check_timeout = 5
deregistration_delay = 15
```

**セキュリティ強化:**
```hcl
# 高セキュリティ設定
enable_deletion_protection = true
allowed_cidr_blocks = ["10.0.0.0/8"]
enable_access_logs = true
```

## 🔗 出力値

### 🌐 ALB情報

| 出力名               | 説明               |
| -------------------- | ------------------ |
| `alb_arn`            | ALB ARN            |
| `alb_dns_name`       | ALB DNS名          |
| `alb_zone_id`        | ALB Zone ID        |
| `alb_hosted_zone_id` | ALB Hosted Zone ID |

### 🎯 ターゲットグループ情報

| 出力名              | 説明                     |
| ------------------- | ------------------------ |
| `target_group_arn`  | ターゲットグループARN    |
| `target_group_name` | ターゲットグループ名     |
| `target_group_port` | ターゲットグループポート |

### 🔐 セキュリティ情報

| 出力名                | 説明                   |
| --------------------- | ---------------------- |
| `security_group_id`   | セキュリティグループID |
| `security_group_name` | セキュリティグループ名 |

## 📝 ライセンス

このモジュールは[MIT License](LICENSE)の下で提供されています。

---

**最終更新**: 2024年12月
**動作確認**: Terraform 1.0+, AWS Provider 5.x
**テスト状況**: 全機能テスト済み
