# ==================================================
# EC2 Auto Scaling Group Terraform Module - Variables
# ==================================================
#
# このファイルは Auto Scaling Group モジュールの全変数を定義します
#
# 設定カテゴリ:
# - プロジェクト基本設定
# - 起動テンプレート設定
# - ネットワーク設定
# - スケーリング設定
# - 監視・アラート設定
# - 通知設定
# - タグ設定
#
# 最新更新: 2024年12月
# ==================================================

# ==================================================
# プロジェクト基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region は有効なAWSリージョン形式である必要があります（例: ap-northeast-1）。"
  }
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myproject"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name)) && length(var.project_name) >= 2 && length(var.project_name) <= 32
    error_message = "project_name は2-32文字の英小文字、数字、ハイフンのみ使用可能です。"
  }
}

variable "environment" {
  description = "環境名（dev, stg, prodなど）"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "test", "prod"], var.environment)
    error_message = "environment は 'dev', 'stg', 'test', 'prod' のいずれかである必要があります。"
  }
}

variable "app" {
  description = "アプリケーション名（空文字列の場合は省略される）"
  type        = string
  default     = ""

  validation {
    condition     = var.app == "" || (can(regex("^[a-z0-9-]+$", var.app)) && length(var.app) >= 2 && length(var.app) <= 32)
    error_message = "app は空文字列または2-32文字の英小文字、数字、ハイフンのみ使用可能です。"
  }
}

# ==================================================
# 起動テンプレート設定
# ==================================================

variable "launch_template_id" {
  description = "使用する起動テンプレートのID"
  type        = string

  validation {
    condition     = can(regex("^lt-[0-9a-f]{8,17}$", var.launch_template_id))
    error_message = "launch_template_id は有効な起動テンプレートID形式である必要があります（例: lt-0123456789abcdef0）。"
  }
}

variable "launch_template_version" {
  description = "使用する起動テンプレートのバージョン（$Latest, $Default, または特定のバージョン番号）"
  type        = string
  default     = "$Latest"

  validation {
    condition     = var.launch_template_version == "$Latest" || var.launch_template_version == "$Default" || can(regex("^[0-9]+$", var.launch_template_version))
    error_message = "launch_template_version は '$Latest', '$Default', または数値である必要があります。"
  }
}

# ==================================================
# ネットワーク設定
# ==================================================

variable "subnet_ids" {
  description = "オートスケーリンググループで使用するサブネットIDのリスト（空の場合はデフォルトVPCのサブネットを使用）"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", subnet_id))
    ])
    error_message = "subnet_ids の各要素は有効なサブネットID形式である必要があります（例: subnet-12345678）。"
  }
}

variable "availability_zones" {
  description = "オートスケーリンググループで使用するアベイラビリティーゾーンのリスト（空の場合は利用可能なすべてのAZを使用）"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))
    ])
    error_message = "availability_zones の各要素は有効なAZ形式である必要があります（例: ap-northeast-1a）。"
  }
}

# ==================================================
# オートスケーリンググループ基本設定
# ==================================================

variable "desired_capacity" {
  description = "オートスケーリンググループの希望インスタンス数（最大インスタンス数は2倍に設定される）"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1 && var.desired_capacity <= 1000
    error_message = "desired_capacity は1から1000の間である必要があります。"
  }
}

variable "min_size" {
  description = "オートスケーリンググループの最小インスタンス数（0に設定することで完全なスケールダウンが可能）"
  type        = number
  default     = 0

  validation {
    condition     = var.min_size >= 0 && var.min_size <= 1000
    error_message = "min_size は0から1000の間である必要があります。"
  }
}

variable "health_check_type" {
  description = "ヘルスチェックタイプ（EC2 または ELB）"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type は 'EC2' または 'ELB' である必要があります。"
  }
}

variable "health_check_grace_period" {
  description = "ヘルスチェック猶予期間（秒）"
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0 && var.health_check_grace_period <= 7200
    error_message = "health_check_grace_period は0から7200秒の間である必要があります。"
  }
}

variable "protect_from_scale_in" {
  description = "スケールイン保護を有効にするかどうか"
  type        = bool
  default     = false
}

variable "default_cooldown" {
  description = "デフォルトクールダウン時間（秒）"
  type        = number
  default     = 300

  validation {
    condition     = var.default_cooldown >= 0 && var.default_cooldown <= 3600
    error_message = "default_cooldown は0から3600秒の間である必要があります。"
  }
}

variable "max_instance_lifetime" {
  description = "インスタンスの最大寿命（秒）。0の場合は制限なし"
  type        = number
  default     = 0

  validation {
    condition     = var.max_instance_lifetime == 0 || (var.max_instance_lifetime >= 604800 && var.max_instance_lifetime <= 31536000)
    error_message = "max_instance_lifetime は0（制限なし）または604800-31536000秒（7日-365日）の間である必要があります。"
  }
}

variable "termination_policies" {
  description = "インスタンス終了ポリシー"
  type        = list(string)
  default     = ["Default"]

  validation {
    condition = alltrue([
      for policy in var.termination_policies :
      contains(["Default", "OldestInstance", "NewestInstance", "OldestLaunchConfiguration", "OldestLaunchTemplate", "ClosestToNextInstanceHour", "AllocationStrategy"], policy)
    ])
    error_message = "termination_policies の各要素は有効な終了ポリシーである必要があります。"
  }
}

# ==================================================
# ロードバランサー設定
# ==================================================

variable "target_group_arns" {
  description = "ターゲットグループのARNリスト（ALB/NLB使用時）"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.target_group_arns : can(regex("^arn:aws:elasticloadbalancing:[a-z0-9-]+:[0-9]+:targetgroup/.+$", arn))
    ])
    error_message = "target_group_arns の各要素は有効なターゲットグループARN形式である必要があります。"
  }
}

variable "load_balancer_names" {
  description = "クラシックロードバランサー名のリスト（CLB使用時）"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for name in var.load_balancer_names : can(regex("^[a-zA-Z0-9-]+$", name)) && length(name) >= 1 && length(name) <= 32
    ])
    error_message = "load_balancer_names の各要素は1-32文字の英数字とハイフンのみ使用可能です。"
  }
}

# ==================================================
# 通知設定
# ==================================================

variable "enable_notifications" {
  description = "SNS通知を有効にするかどうか"
  type        = bool
  default     = false
}

variable "notification_email_addresses" {
  description = "通知先メールアドレスのリスト"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.notification_email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "notification_email_addresses の各要素は有効なメールアドレス形式である必要があります。"
  }
}

variable "sns_kms_key_id" {
  description = "SNSトピックの暗号化に使用するKMS key ID (ARN, key ID, または alias)"
  type        = string
  default     = null

  validation {
    condition     = var.sns_kms_key_id == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-f0-9-]+|[a-f0-9-]+|alias/.+)$", var.sns_kms_key_id))
    error_message = "sns_kms_key_id は有効なKMS key ID、ARN、またはエイリアス形式である必要があります。"
  }
}

variable "notification_types" {
  description = "通知タイプのリスト"
  type        = list(string)
  default = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  validation {
    condition = alltrue([
      for type in var.notification_types : can(regex("^autoscaling:EC2_INSTANCE_", type))
    ])
    error_message = "notification_types の各要素は有効なAuto Scaling通知タイプである必要があります。"
  }
}

# ==================================================
# メトリクス設定
# ==================================================

variable "enabled_metrics" {
  description = "有効にするメトリクスタイプのリスト"
  type        = list(string)
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
}

# ==================================================
# インスタンスリフレッシュ設定
# ==================================================

variable "enable_instance_refresh" {
  description = "インスタンスリフレッシュを有効にするかどうか"
  type        = bool
  default     = false
}

variable "instance_refresh_strategy" {
  description = "インスタンスリフレッシュ戦略"
  type        = string
  default     = "Rolling"
}

variable "instance_refresh_min_healthy_percentage" {
  description = "インスタンスリフレッシュ時の最小ヘルシー割合"
  type        = number
  default     = 90
}

variable "instance_refresh_instance_warmup" {
  description = "インスタンスウォームアップ時間（秒）"
  type        = number
  default     = 300
}

variable "instance_refresh_checkpoint_delay" {
  description = "チェックポイント遅延時間（秒）"
  type        = number
  default     = 3600
}

variable "instance_refresh_checkpoint_percentages" {
  description = "チェックポイント割合のリスト"
  type        = list(number)
  default     = [20, 50, 100]
}

variable "instance_refresh_triggers" {
  description = "インスタンスリフレッシュをトリガーする変更のリスト"
  type        = list(string)
  default     = ["launch_template"]
}

# ==================================================
# CPU監視アラーム設定
# ==================================================

variable "enable_cpu_high_alarm" {
  description = "CPU使用率高アラームを有効にするかどうか"
  type        = bool
  default     = true
}

variable "cpu_high_threshold" {
  description = "CPU使用率高アラームの閾値（%）"
  type        = number
  default     = 80
}

variable "cpu_high_evaluation_periods" {
  description = "CPU使用率高アラームの評価期間"
  type        = number
  default     = 2
}

variable "cpu_high_period" {
  description = "CPU使用率高アラームの期間（秒）"
  type        = number
  default     = 120
}

variable "enable_cpu_low_alarm" {
  description = "CPU使用率低アラームを有効にするかどうか"
  type        = bool
  default     = true
}

variable "cpu_low_threshold" {
  description = "CPU使用率低アラームの閾値（%）"
  type        = number
  default     = 10
}

variable "cpu_low_evaluation_periods" {
  description = "CPU使用率低アラームの評価期間"
  type        = number
  default     = 2
}

variable "cpu_low_period" {
  description = "CPU使用率低アラームの期間（秒）"
  type        = number
  default     = 120
}

# ==================================================
# スケーリングポリシー設定
# ==================================================

variable "enable_scale_up_policy" {
  description = "スケールアップポリシーを有効にするかどうか"
  type        = bool
  default     = true
}

variable "scale_up_adjustment" {
  description = "スケールアップ時の調整値"
  type        = number
  default     = 1
}

variable "scale_up_adjustment_type" {
  description = "スケールアップ時の調整タイプ"
  type        = string
  default     = "ChangeInCapacity"
}

variable "scale_up_cooldown" {
  description = "スケールアップ後のクールダウン時間（秒）"
  type        = number
  default     = 300
}

variable "scale_up_policy_type" {
  description = "スケールアップポリシータイプ"
  type        = string
  default     = "SimpleScaling"
}

variable "scale_up_step_adjustments" {
  description = "ステップスケーリング用の調整設定"
  type = list(object({
    scaling_adjustment          = number
    metric_interval_lower_bound = number
    metric_interval_upper_bound = number
  }))
  default = []
}

variable "enable_scale_down_policy" {
  description = "スケールダウンポリシーを有効にするかどうか"
  type        = bool
  default     = true
}

variable "scale_down_adjustment" {
  description = "スケールダウン時の調整値"
  type        = number
  default     = -1
}

variable "scale_down_adjustment_type" {
  description = "スケールダウン時の調整タイプ"
  type        = string
  default     = "ChangeInCapacity"
}

variable "scale_down_cooldown" {
  description = "スケールダウン後のクールダウン時間（秒）"
  type        = number
  default     = 300
}

variable "scale_down_policy_type" {
  description = "スケールダウンポリシータイプ"
  type        = string
  default     = "SimpleScaling"
}

variable "scale_down_step_adjustments" {
  description = "ステップスケーリング用の調整設定"
  type = list(object({
    scaling_adjustment          = number
    metric_interval_lower_bound = number
    metric_interval_upper_bound = number
  }))
  default = []
}

# ==================================================
# ターゲット追跡スケーリング設定
# ==================================================

variable "target_tracking_target_value" {
  description = "ターゲット追跡スケーリングの目標値"
  type        = number
  default     = 50.0
}

variable "target_tracking_metric_type" {
  description = "ターゲット追跡メトリクスタイプ"
  type        = string
  default     = "ASGAverageCPUUtilization"
}

variable "target_tracking_scale_out_cooldown" {
  description = "ターゲット追跡スケールアウトクールダウン時間（秒）"
  type        = number
  default     = 300
}

variable "target_tracking_scale_in_cooldown" {
  description = "ターゲット追跡スケールインクールダウン時間（秒）"
  type        = number
  default     = 300
}

variable "target_tracking_disable_scale_in" {
  description = "ターゲット追跡でスケールインを無効にするかどうか"
  type        = bool
  default     = false
}

# スケールダウン専用のターゲット追跡設定
variable "target_tracking_target_value_down" {
  description = "スケールダウン用ターゲット追跡スケーリングの目標値"
  type        = number
  default     = 30.0
}

variable "target_tracking_metric_type_down" {
  description = "スケールダウン用ターゲット追跡メトリクスタイプ"
  type        = string
  default     = "ASGAverageCPUUtilization"
}

variable "target_tracking_disable_scale_in_down" {
  description = "スケールダウン用ターゲット追跡でスケールインを無効にするかどうか"
  type        = bool
  default     = false
}

# ==================================================
# スケーリングアラーム設定
# ==================================================

variable "enable_scale_up_alarm" {
  description = "スケールアップ用アラームを有効にするかどうか"
  type        = bool
  default     = true
}

variable "scale_up_alarm_metric_name" {
  description = "スケールアップアラームのメトリクス名"
  type        = string
  default     = "CPUUtilization"
}

variable "scale_up_alarm_threshold" {
  description = "スケールアップアラームの閾値"
  type        = number
  default     = 70
}

variable "scale_up_alarm_evaluation_periods" {
  description = "スケールアップアラームの評価期間"
  type        = number
  default     = 2
}

variable "scale_up_alarm_period" {
  description = "スケールアップアラームの期間（秒）"
  type        = number
  default     = 120
}

variable "scale_up_alarm_statistic" {
  description = "スケールアップアラームの統計"
  type        = string
  default     = "Average"
}

variable "enable_scale_down_alarm" {
  description = "スケールダウン用アラームを有効にするかどうか"
  type        = bool
  default     = true
}

variable "scale_down_alarm_metric_name" {
  description = "スケールダウンアラームのメトリクス名"
  type        = string
  default     = "CPUUtilization"
}

variable "scale_down_alarm_threshold" {
  description = "スケールダウンアラームの閾値"
  type        = number
  default     = 20
}

variable "scale_down_alarm_evaluation_periods" {
  description = "スケールダウンアラームの評価期間"
  type        = number
  default     = 2
}

variable "scale_down_alarm_period" {
  description = "スケールダウンアラームの期間（秒）"
  type        = number
  default     = 120
}

variable "scale_down_alarm_statistic" {
  description = "スケールダウンアラームの統計"
  type        = string
  default     = "Average"
}

# ==================================================
# タグ設定
# ==================================================

variable "owner_team" {
  description = "リソースの所有者チーム"
  type        = string
  default     = "devops-team"
}

variable "owner_email" {
  description = "リソースの所有者チームのメールアドレス"
  type        = string
  default     = "devops@example.com"
}

variable "cost_center" {
  description = "コストセンター"
  type        = string
  default     = "engineering"
}

variable "billing_code" {
  description = "請求コード"
  type        = string
  default     = ""
}

variable "data_classification" {
  description = "データ分類レベル (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification は 'public', 'internal', 'confidential', 'restricted' のいずれかである必要があります。"
  }
}

variable "backup_required" {
  description = "バックアップが必要かどうか"
  type        = bool
  default     = true
}

variable "monitoring_level" {
  description = "監視レベル (basic, enhanced)"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "enhanced"], var.monitoring_level)
    error_message = "monitoring_level は 'basic' または 'enhanced' である必要があります。"
  }
}

variable "schedule" {
  description = "運用スケジュール (24x7, business-hours)"
  type        = string
  default     = "24x7"
}

variable "common_tags" {
  description = "すべてのリソースに適用される共通タグ（追加・上書き用）"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "オートスケーリンググループに追加するタグのマップ（プロパゲート設定を含む）"
  type = map(object({
    value               = string
    propagate_at_launch = bool
  }))
  default = {}
}
