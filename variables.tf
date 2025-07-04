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
}

# ==================================================
# プロジェクト設定
# ==================================================

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "env" {
  description = "環境名 (dev, stg, prod)"
  type        = string
}

variable "app" {
  description = "アプリケーション名（オプション）"
  type        = string
  default     = ""
}
