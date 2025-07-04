# ==================================================
# 基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "env" {
  description = "環境名 (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.env)
    error_message = "env must be one of the following values: dev, stg, or prod."
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
# ECSクラスター設定
# ==================================================

variable "cluster_name" {
  description = "ECSクラスター名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "capacity_providers" {
  description = "キャパシティプロバイダー"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "デフォルトキャパシティプロバイダー戦略"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
  ]
}

# ==================================================
# Container Insights設定
# ==================================================

variable "enable_container_insights" {
  description = "Container Insightsを有効にするか"
  type        = bool
  default     = true
}

# ==================================================
# Execute Command設定
# ==================================================

variable "enable_execute_command_logging" {
  description = "Execute Commandのログ記録を有効にするか"
  type        = bool
  default     = true
}

variable "execute_command_kms_key_id" {
  description = "Execute Command用のKMSキーID（指定しない場合はデフォルトキーを使用）"
  type        = string
  default     = ""
}

variable "execute_command_log_group_name" {
  description = "Execute Command用のCloudWatchロググループ名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "execute_command_s3_bucket_name" {
  description = "Execute Command用のS3バケット名（オプション）"
  type        = string
  default     = ""
}

variable "execute_command_s3_key_prefix" {
  description = "Execute Command用のS3キープレフィックス"
  type        = string
  default     = "ecs-execute-command"
}

# ==================================================
# Service Connect設定
# ==================================================

variable "enable_service_connect" {
  description = "Service Connectを有効にするか"
  type        = bool
  default     = false
}

variable "service_connect_namespace" {
  description = "Service Connect名前空間（enable_service_connectがtrueの場合は必須）"
  type        = string
  default     = ""

  # NOTE: Terraformの変数validation blockは他の変数を参照できないため、
  # enable_service_connectがtrueの場合の空文字チェックは main.tf 内で実装する必要があります
  validation {
    condition     = var.service_connect_namespace == "" || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,62}[a-zA-Z0-9]$", var.service_connect_namespace))
    error_message = "service_connect_namespace must be a valid namespace name (1-64 characters, alphanumeric, hyphens, and underscores only, cannot start/end with special characters) when provided. This value is required when enable_service_connect is true."
  }
}
