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

# ==================================================
# 起動テンプレート設定
# ==================================================

variable "launch_template_id" {
  description = "使用する起動テンプレートのID"
  type        = string
}

variable "launch_template_version" {
  description = "使用する起動テンプレートのバージョン（$Latest, $Default, または特定のバージョン番号）"
  type        = string
  default     = "$Latest"
}

# ==================================================
# ネットワーク設定
# ==================================================

variable "subnet_ids" {
  description = "オートスケーリンググループで使用するサブネットIDのリスト（空の場合はデフォルトVPCのサブネットを使用）"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "オートスケーリンググループで使用するアベイラビリティーゾーンのリスト（空の場合は利用可能なすべてのAZを使用）"
  type        = list(string)
  default     = []
}

# ==================================================
# オートスケーリンググループ基本設定
# ==================================================

variable "desired_capacity" {
  description = "オートスケーリンググループの希望インスタンス数（最小インスタンス数は同じ値、最大インスタンス数は2倍に設定される）"
  type        = number
  default     = 2
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
}

variable "max_instance_lifetime" {
  description = "インスタンスの最大寿命（秒）。0の場合は制限なし"
  type        = number
  default     = 0
}

variable "termination_policies" {
  description = "インスタンス終了ポリシー"
  type        = list(string)
  default     = ["Default"]
}

# ==================================================
# ロードバランサー設定
# ==================================================

variable "target_group_arns" {
  description = "ターゲットグループのARNリスト（ALB/NLB使用時）"
  type        = list(string)
  default     = []
}

variable "load_balancer_names" {
  description = "クラシックロードバランサー名のリスト（CLB使用時）"
  type        = list(string)
  default     = []
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

variable "common_tags" {
  description = "すべてのリソースに適用される共通タグ"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "オートスケーリンググループに追加するタグのマップ（プロパゲート設定を含む）"
  type = map(object({
    propagate_at_launch = bool
  }))
  default = {}
}
