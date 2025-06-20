# ==================================================
# プロジェクト基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "プロジェクト名"
  type        = string
  default     = "myproject"
}

variable "env" {
  description = "環境名（dev, stg, prodなど）"
  type        = string
  default     = "dev"
}

variable "app" {
  description = "アプリケーション名（空文字列の場合は省略される）"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "全リソースに付与する共通タグ"
  type        = map(string)
  default = {
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# ==================================================
# ネットワーク設定
# ==================================================

variable "vpc_id" {
  description = "ALBを配置するVPCのID"
  type        = string
}

variable "subnet_ids" {
  description = "ALBを配置するサブネットIDのリスト（最低2つのAZ）"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALBには最低2つのサブネットが必要です。"
  }
}

# ==================================================
# セキュリティグループ設定
# ==================================================

variable "allowed_cidr_blocks" {
  description = "ALBへのアクセスを許可するCIDRブロックのリスト（現在は使用されていません。80/443ポートは自動的にすべてのIPv4/IPv6を許可します）"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "ALBに追加で適用するセキュリティグループIDのリスト"
  type        = list(string)
  default     = []
}

# ==================================================
# ALB設定
# ==================================================

variable "alb_name" {
  description = "ALB名（空の場合は自動生成: {project}-{env}-alb）"
  type        = string
  default     = ""
}

variable "internal" {
  description = "内部向けALBにするかどうか"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "削除保護を有効にするかどうか"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "アイドルタイムアウト（秒）"
  type        = number
  default     = 60
}

variable "enable_cross_zone_load_balancing" {
  description = "クロスゾーンロードバランシングを有効にするかどうか"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "HTTP/2を有効にするかどうか"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "IPアドレスタイプ（ipv4 または dualstack）"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_typeは 'ipv4' または 'dualstack' である必要があります。"
  }
}

# ==================================================
# ターゲットグループ設定
# ==================================================

variable "target_group_name" {
  description = "ターゲットグループ名（空の場合は自動生成: {project}-{env}-tg）"
  type        = string
  default     = ""
}

variable "target_group_port" {
  description = "ターゲットグループのポート番号"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "ターゲットグループのプロトコル"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_group_protocol)
    error_message = "target_group_protocolは 'HTTP' または 'HTTPS' である必要があります。"
  }
}

variable "target_type" {
  description = "ターゲットタイプ（instance, ip, lambda）"
  type        = string
  default     = "ip"  # ECS用にデフォルトをipに変更
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_typeは 'instance', 'ip', または 'lambda' である必要があります。"
  }
}

variable "health_check_enabled" {
  description = "ヘルスチェックを有効にするかどうか"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "ヘルスチェックのパス"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "ヘルスチェックのポート（trafficの場合はトラフィックポートを使用）"
  type        = string
  default     = "traffic"
}

variable "health_check_protocol" {
  description = "ヘルスチェックのプロトコル"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.health_check_protocol)
    error_message = "health_check_protocolは 'HTTP' または 'HTTPS' である必要があります。"
  }
}

variable "health_check_healthy_threshold" {
  description = "正常と判定するまでの連続成功回数"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "異常と判定するまでの連続失敗回数"
  type        = number
  default     = 2
}

variable "health_check_timeout" {
  description = "ヘルスチェックのタイムアウト（秒）"
  type        = number
  default     = 10  # ECS用により長いタイムアウト
}

variable "health_check_interval" {
  description = "ヘルスチェックの間隔（秒）"
  type        = number
  default     = 15  # ECS用により短い間隔
}

variable "health_check_matcher" {
  description = "正常と判定するHTTPレスポンスコード"
  type        = string
  default     = "200"
}

# ==================================================
# リスナー設定
# ==================================================

# 注意: listener_port と listener_protocol は使用されなくなりました
# HTTPリスナー（80）は443へのリダイレクト、HTTPSリスナー（443）は404を返します

variable "listener_port" {
  description = "リスナーのポート番号（現在は使用されていません）"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "リスナーのプロトコル（現在は使用されていません）"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.listener_protocol)
    error_message = "listener_protocolは 'HTTP' または 'HTTPS' である必要があります。"
  }
}

variable "ssl_certificate_arn" {
  description = "SSL証明書のARN（HTTPSリスナーで必須）"
  type        = string
}

variable "ssl_policy" {
  description = "SSLポリシー（HTTPSの場合）"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# ==================================================
# ECS統合設定
# ==================================================

variable "enable_ecs_service_connect" {
  description = "ECSサービス接続を有効にするかどうか"
  type        = bool
  default     = false
}

# ==================================================
# アクセスログ設定
# ==================================================

variable "enable_access_logs" {
  description = "アクセスログを有効にするかどうか"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "アクセスログを保存するS3バケット名"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "アクセスログのプレフィックス"
  type        = string
  default     = "alb-access-logs"
}
