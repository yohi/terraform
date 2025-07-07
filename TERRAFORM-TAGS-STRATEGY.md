# Terraform Tags Strategy

このドキュメントは、Terraformプロジェクトにおけるタグ戦略とベストプラクティスを定義します。

## 📋 タグ戦略の概要

### 目的
- **リソース管理**: Terraformで管理されるリソースの識別
- **コスト管理**: プロジェクトや環境別のコスト追跡
- **セキュリティ**: アクセス制御とコンプライアンス
- **運用**: 監視、バックアップ、ライフサイクル管理

### 基本原則
1. **一貫性**: 全てのリソースに統一されたタグ付けルール
2. **階層性**: プロジェクト → 環境 → アプリケーション の階層構造
3. **自動化**: Terraformによる自動タグ付け
4. **拡張性**: 新しい要件に対応可能な柔軟な設計

## 🏷️ 必須タグ

### 管理タグ
```hcl
# Terraformプロバイダーのデフォルトタグ
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner_team
      CostCenter  = var.cost_center
    }
  }
}
```

### 基本タグ定義

| タグ名        | 説明               | 例                       | 必須 |
| ------------- | ------------------ | ------------------------ | ---- |
| `ManagedBy`   | リソース管理ツール | `terraform`              | ✅    |
| `Project`     | プロジェクト名     | `myapp`, `webapp`        | ✅    |
| `Environment` | 環境名             | `prod`, `stg`, `dev`     | ✅    |
| `Owner`       | 担当チーム         | `DevOps`, `Backend`      | ✅    |
| `CostCenter`  | コストセンター     | `engineering`, `product` | ✅    |

## 🔧 モジュール別タグ戦略

### EC2 Launch Template
```hcl
locals {
  # 基本タグ
  base_tags = {
    ManagedBy   = "terraform"
    Project     = var.project_name
    Environment = var.environment
    Module      = "ec2-launch-template"
  }

  # 拡張タグ
  extended_tags = {
    OwnerTeam         = var.owner_team
    OwnerEmail        = var.owner_email
    CostCenter        = var.cost_center
    BillingCode       = var.billing_code
    DataClassification = var.data_classification
    BackupRequired    = var.backup_required
    MonitoringLevel   = var.monitoring_level
    Schedule          = var.schedule
  }

  # 最終タグ
  final_common_tags = merge(
    local.base_tags,
    local.extended_tags,
    var.common_tags
  )
}
```

### Auto Scaling Group
```hcl
# 共通タグ
common_tags = {
  ManagedBy   = "terraform"
  Project     = var.project_name
  Environment = var.environment
  Module      = "autoscaling-group"
}

# インスタンスに伝播するタグ
additional_tags = {
  "Name" = {
    propagate_at_launch = true
  }
  "Backup" = {
    propagate_at_launch = true
  }
  "Monitoring" = {
    propagate_at_launch = true
  }
}
```

### Athena Analytics
```hcl
common_tags = {
  ManagedBy   = "terraform"
  Project     = var.project_name
  Environment = var.environment
  Module      = "athena-analytics"
  Purpose     = "log-analysis"
}
```

## 🎯 命名規則

### リソース名の形式
```
${project}-${env}-${app}-${resource_type}
```

**例:**
- `myapp-prod-web-asg` (Auto Scaling Group)
- `myapp-stg-api-lt` (Launch Template)
- `myapp-dev-db-sg` (Security Group)

### タグ値の命名規則

#### プロジェクト名
- **形式**: 小文字、ハイフン区切り
- **例**: `my-webapp`, `data-pipeline`, `user-service`

#### 環境名
- **prod**: 本番環境
- **stg**: ステージング環境
- **dev**: 開発環境
- **test**: テスト環境

#### アプリケーション名
- **web**: Webサーバー
- **api**: APIサーバー
- **db**: データベース
- **cache**: キャッシュサーバー

## 📊 コスト管理のためのタグ

### 必須コストタグ
```hcl
cost_tags = {
  CostCenter    = var.cost_center      # "engineering", "product"
  BillingCode   = var.billing_code     # "CC-001", "PROJ-123"
  Department    = var.department       # "IT", "Marketing"
  BusinessUnit  = var.business_unit    # "Platform", "Growth"
}
```

### 運用コストタグ
```hcl
operational_tags = {
  Schedule        = var.schedule         # "business-hours", "24x7"
  BackupRequired  = var.backup_required  # "true", "false"
  MonitoringLevel = var.monitoring_level # "basic", "detailed"
}
```

## 🔒 セキュリティとコンプライアンス

### データ分類タグ
```hcl
security_tags = {
  DataClassification = var.data_classification  # "public", "internal", "confidential", "restricted"
  ComplianceScope   = var.compliance_scope      # "pci", "hipaa", "gdpr"
  SecurityLevel     = var.security_level        # "low", "medium", "high"
}
```

### アクセス制御タグ
```hcl
access_tags = {
  Owner           = var.owner_team      # "devops", "security"
  OwnerEmail      = var.owner_email     # "devops@company.com"
  AccessLevel     = var.access_level    # "public", "restricted"
}
```

## 📈 監視とアラート

### 監視タグ
```hcl
monitoring_tags = {
  MonitoringLevel = var.monitoring_level  # "basic", "detailed", "custom"
  AlertLevel      = var.alert_level       # "low", "medium", "high", "critical"
  LogRetention    = var.log_retention     # "30days", "90days", "1year"
}
```

## 🔄 ライフサイクル管理

### 自動化タグ
```hcl
lifecycle_tags = {
  AutoStart     = var.auto_start       # "true", "false"
  AutoStop      = var.auto_stop        # "true", "false"
  AutoScaling   = var.auto_scaling     # "enabled", "disabled"
  MaintenanceWindow = var.maintenance_window  # "sun-03:00-04:00"
}
```

## 📝 タグ実装例

### 基本的な実装
```hcl
# variables.tf
variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}

# main.tf
locals {
  base_tags = {
    ManagedBy   = "terraform"
    Project     = var.project_name
    Environment = var.environment
    Module      = "example"
  }

  final_tags = merge(
    local.base_tags,
    var.common_tags
  )
}

resource "aws_instance" "example" {
  # ... other configuration ...

  tags = local.final_tags
}
```

### 高度な実装例
```hcl
# locals.tf
locals {
  # AWS アカウント情報
  aws_account_info = {
    AccountId = data.aws_caller_identity.current.account_id
    Region    = data.aws_region.current.name
  }

  # 基本タグ
  base_tags = {
    ManagedBy   = "terraform"
    Project     = var.project_name
    Environment = var.environment
    Module      = "advanced-example"
  }

  # AWS環境情報タグ
  aws_tags = {
    AWSAccountId = local.aws_account_info.AccountId
    AWSRegion    = local.aws_account_info.Region
  }

  # 最終タグ
  final_common_tags = merge(
    local.base_tags,
    local.aws_tags,
    var.common_tags
  )
}

# データソース
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

## 🎨 タグ付けのベストプラクティス

### 1. 一貫性の確保
- 全てのモジュールで同じタグ構造を使用
- 命名規則を統一
- 大文字小文字を統一

### 2. 自動化の活用
- Terraformプロバイダーのデフォルトタグを使用
- 変数とlocalsを活用してタグを動的生成
- 環境固有のタグを自動設定

### 3. 運用性の向上
- 検索しやすいタグ名と値を使用
- 階層構造を明確にする
- 不要なタグは削除する

### 4. コスト最適化
- コストセンターとプロジェクトタグを必須化
- 定期的なタグ監査を実施
- 未使用リソースの識別を容易にする

## 🔍 タグ監査とコンプライアンス

### 監査スクリプト
```bash
# 全てのTerraformリソースの確認
./search_terraform_resources.sh

# 特定のタグが設定されていないリソースの確認
aws resourcegroupstaggingapi get-resources \
  --resource-type-filters "AWS::EC2::Instance" \
  --query 'ResourceTagMappingList[?!Tags[?Key==`ManagedBy`]]'
```

### コンプライアンスチェック
```bash
# 必須タグのチェック
required_tags=("ManagedBy" "Project" "Environment" "Owner")
for tag in "${required_tags[@]}"; do
  echo "Checking for $tag tag..."
  # チェックロジック
done
```

## 🚀 実装ガイドライン

### 新規モジュール作成時
1. **base_tags** を定義
2. **common_tags** 変数を追加
3. **final_tags** でマージ
4. 全リソースにタグ適用

### 既存モジュール更新時
1. 現在のタグ構造を確認
2. 段階的に標準タグ構造に移行
3. 後方互換性を維持
4. ドキュメントを更新

## 📚 参考リンク

- [AWS Tagging Best Practices](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html)
- [Terraform AWS Provider Default Tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags)
- [AWS Cost and Usage Report](https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html)

---

**最終更新日**: 2024年12月
**バージョン**: 1.0
