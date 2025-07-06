# ==================================================
# 基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名 (prd, rls, stg, dev)"
  type        = string
  validation {
    condition     = contains(["prd", "rls", "stg", "dev"], var.environment)
    error_message = "environment must be one of: prd, rls, stg, dev."
  }
}

variable "app" {
  description = "アプリケーション名（オプション）"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      contains(keys(var.common_tags), "Project") || var.project_name != "",
      contains(keys(var.common_tags), "Environment") || var.environment != ""
    ])
    error_message = "common_tags must contain 'Project' and 'Environment' keys, or these values must be provided via project_name and environment variables."
  }
}

# ==================================================
# ECRリポジトリ設定
# ==================================================

variable "repository_name" {
  description = "ECRリポジトリ名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "repositories" {
  description = "複数のECRリポジトリを作成する場合のリスト"
  type = list(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    encryption_type      = optional(string, "AES256")
    kms_key_id           = optional(string, "")
  }))
  default = []
}

variable "image_tag_mutability" {
  description = "イメージタグの変更可能性 (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "プッシュ時にイメージスキャンを実行するか"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "暗号化タイプ (AES256 or KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "KMS暗号化キーID（encryption_type=KMSの場合に指定）"
  type        = string
  default     = ""
  validation {
    condition     = var.encryption_type == "KMS" ? var.kms_key_id != "" : true
    error_message = "kms_key_id must not be empty when encryption_type is 'KMS'."
  }
}

# ==================================================
# ライフサイクルポリシー設定
# ==================================================

variable "enable_lifecycle_policy" {
  description = "ライフサイクルポリシーを有効にするか"
  type        = bool
  default     = true
}

variable "lifecycle_policy_rules" {
  description = "カスタムライフサイクルポリシールール（JSONまたはテンプレート化文字列）"
  type        = string
  default     = ""
}

variable "untagged_image_count_limit" {
  description = "タグなしイメージの保持数"
  type        = number
  default     = 10
}

variable "tagged_image_count_limit" {
  description = "タグ付きイメージの保持数"
  type        = number
  default     = 20
}

variable "image_age_limit_days" {
  description = "イメージの保持期間（日）"
  type        = number
  default     = 30
}

# ==================================================
# リポジトリポリシー設定
# ==================================================

variable "enable_repository_policy" {
  description = "リポジトリポリシーを有効にするか"
  type        = bool
  default     = false
}

variable "repository_policy_json" {
  description = "カスタムリポジトリポリシー（JSON）"
  type        = string
  default     = ""
}

variable "allowed_principals" {
  description = "リポジトリへのアクセスを許可するプリンシパル（アカウントIDまたはARN）"
  type        = list(string)
  default     = []
}

variable "allowed_actions" {
  description = "許可するECRアクション"
  type        = list(string)
  default = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability"
  ]
}

# ==================================================
# レプリケーション設定
# ==================================================

variable "enable_replication" {
  description = "レプリケーションを有効にするか（trueの場合はreplication_destinationsが必須）"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "レプリケーション先リージョンのリスト（enable_replicationがtrueの場合は必須）"
  type        = list(string)
  default     = []

  validation {
    condition = length(var.replication_destinations) > 0 ? alltrue([
      for region in var.replication_destinations : can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", region))
    ]) : true
    error_message = "replication_destinations must contain valid AWS region names (e.g., 'us-east-1', 'ap-northeast-1') when specified."
  }
}

# ==================================================
# プル経由アクセス設定
# ==================================================

variable "enable_pull_through_cache" {
  description = "プル経由キャッシュを有効にするか"
  type        = bool
  default     = false
}

variable "upstream_registry_url" {
  description = "上流レジストリURL（プル経由キャッシュ用）"
  type        = string
  default     = ""

  validation {
    condition     = var.enable_pull_through_cache ? var.upstream_registry_url != "" : true
    error_message = "upstream_registry_url must not be empty when enable_pull_through_cache is true."
  }
}
