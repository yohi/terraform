# ==================================================
# 基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "common_tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "ManagedBy"] :
      length(trimspace(lookup(var.common_tags, key, ""))) > 0
    ])
    error_message = "common_tagsに含まれる必須タグ（Project、Environment、ManagedBy）は空文字列にできません。"
  }
}

# ==================================================
# プロジェクト設定
# ==================================================

variable "project_name" {
  description = "プロジェクト名"
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "プロジェクト名は空文字列にできません。必須タグ「Project」として使用されます。"
  }
}

variable "environment" {
  description = "環境名 (dev, stg, rls, prd)"
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "環境名は空文字列にできません。必須タグ「Environment」として使用されます。"
  }

  validation {
    condition     = contains(["dev", "stg", "rls", "prd"], var.environment)
    error_message = "環境名は 'dev', 'stg', 'rls', 'prd' のいずれかである必要があります。"
  }
}

variable "app" {
  description = "アプリケーション名（オプション）"
  type        = string
  default     = ""
}
