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
    error_message = "environment must be one of the following values: prd, rls, stg, or dev."
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
}

# ==================================================
# ECSエージェント監視設定
# ==================================================

variable "resource_name_prefix" {
  description = "リソース名のプレフィックス（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "cluster_arn" {
  description = "監視対象のECSクラスターARN"
  type        = string
}

variable "slack_channel" {
  description = "Slack通知先チャンネル名 (例: #alerts, @user)"
  type        = string
  default     = "#alerts"
}

variable "slack_token_secret_arn" {
  description = "Slack Bot Token を格納している AWS Secrets Manager のシークレット ARN"
  type        = string
  sensitive   = true
}

# ==================================================
# CloudWatch ログ設定
# ==================================================

variable "log_group_name" {
  description = "CloudWatchログ グループ名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "CloudWatchログの保持期間（日）"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_in_days)
    error_message = "log_retention_in_days must be one of the following values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

# ==================================================
# Lambda設定
# ==================================================

variable "lambda_timeout" {
  description = "Lambda関数のタイムアウト（秒）"
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_runtime" {
  description = "Lambda関数のランタイム"
  type        = string
  default     = "python3.9"

  validation {
    condition     = contains(["python3.8", "python3.9", "python3.10", "python3.11"], var.lambda_runtime)
    error_message = "lambda_runtime must be one of the following values: python3.8, python3.9, python3.10, python3.11."
  }
}

# ==================================================
# フィルタリング設定
# ==================================================

variable "subscription_filter_pattern" {
  description = "CloudWatch ログ サブスクリプション フィルターのパターン"
  type        = string
  default     = "{ $.detail.agentConnected is false }"
}

variable "enable_monitoring" {
  description = "ECSエージェント監視を有効にするか"
  type        = bool
  default     = true
}
