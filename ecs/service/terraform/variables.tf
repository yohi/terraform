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

variable "env" {
  description = "環境名 (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "env は dev, stg, prod のいずれかである必要があります。"
  }
}

variable "app" {
  description = "アプリケーション名"
  type        = string
}

variable "common_tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}

# ==================================================
# ECSクラスター情報
# ==================================================

variable "cluster_name" {
  description = "ECSクラスター名"
  type        = string
}

# ==================================================
# VPC・ネットワーク設定
# ==================================================

variable "vpc_id" {
  description = "VPC ID（指定しない場合はデフォルトVPCを使用）"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "サブネットIDのリスト（指定しない場合はデフォルトVPCのサブネットを使用）"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "追加のセキュリティグループIDのリスト"
  type        = list(string)
  default     = []
}

# ==================================================
# ECSタスク定義設定
# ==================================================

variable "task_definition_family" {
  description = "タスク定義ファミリー名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "task_cpu" {
  description = "タスクCPU（Fargate: 256, 512, 1024, 2048, 4096）"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "タスクメモリ（MiB）"
  type        = number
  default     = 512
}

variable "execution_role_arn" {
  description = "タスク実行ロールARN（指定しない場合は自動作成）"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "タスクロールARN（指定しない場合は自動作成）"
  type        = string
  default     = ""
}

variable "network_mode" {
  description = "ネットワークモード（awsvpc, bridge, host, none）"
  type        = string
  default     = "awsvpc"

  validation {
    condition     = contains(["awsvpc", "bridge", "host", "none"], var.network_mode)
    error_message = "network_mode は awsvpc, bridge, host, none のいずれかである必要があります。"
  }
}

variable "requires_compatibilities" {
  description = "互換性要件"
  type        = list(string)
  default     = ["FARGATE"]
}

# ==================================================
# コンテナ設定
# ==================================================

variable "container_definitions" {
  description = "コンテナ定義のJSONまたはリスト"
  type        = any
  default     = []
}

variable "container_name" {
  description = "メインコンテナ名"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "コンテナイメージ"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "コンテナポート"
  type        = number
  default     = 80
}

variable "container_protocol" {
  description = "コンテナプロトコル"
  type        = string
  default     = "tcp"
}

variable "container_cpu" {
  description = "コンテナCPU"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "コンテナメモリ（MiB）"
  type        = number
  default     = 512
}

variable "container_memory_reservation" {
  description = "コンテナメモリ予約（MiB）"
  type        = number
  nullable    = true
  default     = null
}

variable "environment_variables" {
  description = "環境変数"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "シークレット（Parameter Store/Secrets Manager）"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# ==================================================
# ECSサービス設定
# ==================================================

variable "service_name" {
  description = "ECSサービス名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "希望するタスク数"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "起動タイプ（FARGATE, EC2）"
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type は FARGATE または EC2 である必要があります。"
  }
}

variable "platform_version" {
  description = "プラットフォームバージョン（FARGATE使用時）"
  type        = string
  default     = "LATEST"
}

variable "assign_public_ip" {
  description = "パブリックIPを割り当てるか"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Execute Commandを有効にするか"
  type        = bool
  default     = true
}

# ==================================================
# ロードバランサー設定
# ==================================================

variable "target_group_arn" {
  description = "ターゲットグループARN（ALB使用時）"
  type        = string
  default     = ""
}

variable "load_balancer_container_name" {
  description = "ロードバランサーに接続するコンテナ名"
  type        = string
  default     = ""
}

variable "load_balancer_container_port" {
  description = "ロードバランサーに接続するコンテナポート"
  type        = number
  default     = 80
}

# ==================================================
# Auto Scaling設定
# ==================================================

variable "enable_auto_scaling" {
  description = "Auto Scalingを有効にするか"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "最小キャパシティ"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "最大キャパシティ"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "ターゲットCPU使用率（%）"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "ターゲットメモリ使用率（%）"
  type        = number
  default     = 80
}

variable "scale_in_cooldown" {
  description = "スケールイン時のクールダウン時間（秒）"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "スケールアウト時のクールダウン時間（秒）"
  type        = number
  default     = 300
}

# ==================================================
# ログ設定
# ==================================================

variable "enable_logging" {
  description = "CloudWatchログを有効にするか"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "CloudWatchロググループ名（指定しない場合は自動生成）"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "ログ保持期間（日）"
  type        = number
  default     = 7
}

variable "log_stream_prefix" {
  description = "ログストリームプレフィックス"
  type        = string
  default     = "ecs"
}

# ==================================================
# ヘルスチェック設定
# ==================================================

variable "health_check_grace_period_seconds" {
  description = "ヘルスチェック猶予期間（秒）"
  type        = number
  default     = 30
}

# ==================================================
# デプロイメント設定
# ==================================================

variable "deployment_maximum_percent" {
  description = "デプロイメント時の最大パーセント"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "デプロイメント時の最小ヘルシーパーセント"
  type        = number
  default     = 100
}

variable "enable_deployment_circuit_breaker" {
  description = "デプロイメントサーキットブレーカーを有効にするか"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "サーキットブレーカー時にロールバックするか"
  type        = bool
  default     = true
}
