# ==================================================
# データソース
# ==================================================

# 現在のAWSアカウント情報取得
data "aws_caller_identity" "current" {}

# 現在のAWSリージョン取得
data "aws_region" "current" {}

# デフォルトVPCの取得
data "aws_vpc" "default" {
  default = true
}

# デフォルトVPCのサブネット取得
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 指定されたAZのデフォルトVPCサブネット取得（availability_zonesが指定されている場合）
data "aws_subnets" "default_filtered" {
  count = length(var.availability_zones) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = var.availability_zones
  }
}

# アベイラビリティーゾーン取得
data "aws_availability_zones" "available" {
  state = "available"
}

# ==================================================
# ローカル変数
# ==================================================

locals {
  # ASG名の決定（${project}-${env}-${app}-asg、appは省略可能）
  asg_name = var.app != "" ? "${var.project}-${var.env}-${var.app}-asg" : "${var.project}-${var.env}-asg"

  # その他のリソース名プレフィックス
  name_prefix = var.app != "" ? "${var.project}-${var.env}-${var.app}" : "${var.project}-${var.env}"

  # アベイラビリティーゾーンの決定（指定されている場合は使用、なければ利用可能なすべてのAZ）
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  # サブネットの決定（指定されている場合は使用、なければデフォルトVPCのサブネット）
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (length(var.availability_zones) > 0 ? data.aws_subnets.default_filtered[0].ids : data.aws_subnets.default.ids)

  # 通知エンドポイントの決定
  notification_endpoints = length(var.notification_email_addresses) > 0 ? var.notification_email_addresses : []

  # ==================================================
  # タグ戦略の実装
  # ==================================================

  # 基本タグ（すべてのリソースに適用）
  base_tags = {
    "ManagedBy"          = "terraform"
    "TerraformWorkspace" = terraform.workspace
    "Project"            = var.project
    "Environment"        = var.env
    "Application"        = var.app
    "CreatedAt"          = formatdate("YYYY-MM-DD", timestamp())
    "CreatedBy"          = data.aws_caller_identity.current.user_id
    "AccountId"          = data.aws_caller_identity.current.account_id
    "Region"             = data.aws_region.current.name
  }

  # 運用管理タグ
  operational_tags = {
    "Owner"           = var.owner_team
    "OwnerEmail"      = var.owner_email
    "CostCenter"      = var.cost_center
    "BillingCode"     = var.billing_code != "" ? var.billing_code : "PROJ-2024-${var.project}"
    "Schedule"        = var.schedule
    "BackupRequired"  = var.backup_required ? "yes" : "no"
    "MonitoringLevel" = var.monitoring_level
  }

  # セキュリティ・コンプライアンス タグ
  security_tags = {
    "DataClassification" = var.data_classification
    "Encryption"         = "required"
    "NetworkAccess"      = "vpc-only"
  }

  # 環境固有タグ
  env_tags = var.env == "prod" ? {
    "CriticalityLevel" = "high"
    "AuditRequired"    = "yes"
    "RetentionPeriod"  = "7-years"
    } : {
    "CriticalityLevel" = "medium"
    "AuditRequired"    = "no"
    "RetentionPeriod"  = "1-year"
  }

  # サービス固有タグ
  service_tags = {
    "Service"     = "compute"
    "Component"   = "auto-scaling-group"
    "Tier"        = "application"
    "AutoScaling" = "enabled"
    "HealthCheck" = var.health_check_type
  }

  # 最終的な共通タグ（優先度: 追加タグ > 共通タグ > 環境固有 > セキュリティ > 運用 > サービス > 基本）
  final_common_tags = merge(
    local.base_tags,
    local.service_tags,
    local.operational_tags,
    local.security_tags,
    local.env_tags,
    var.common_tags
  )
}

# ==================================================
# SNS Topic (通知用)
# ==================================================

resource "aws_sns_topic" "asg_notifications" {
  count = var.enable_notifications ? 1 : 0

  name              = "${local.name_prefix}-asg-notifications"
  kms_master_key_id = var.sns_kms_key_id

  tags = merge(
    local.final_common_tags,
    {
      Name      = "${local.name_prefix}-asg-notifications"
      Component = "sns"
      Purpose   = "auto-scaling-notifications"
    }
  )
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email_notifications" {
  count = var.enable_notifications && length(local.notification_endpoints) > 0 ? length(local.notification_endpoints) : 0

  topic_arn = aws_sns_topic.asg_notifications[0].arn
  protocol  = "email"
  endpoint  = local.notification_endpoints[count.index]
}

# ==================================================
# オートスケーリンググループ
# ==================================================

resource "aws_autoscaling_group" "main" {
  name                = local.asg_name
  vpc_zone_identifier = local.subnet_ids
  availability_zones  = length(var.subnet_ids) == 0 ? local.availability_zones : null

  # 起動テンプレート設定
  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # インスタンス数設定（希望インスタンス数をベースに自動計算）
  min_size         = var.desired_capacity
  max_size         = var.desired_capacity * 2
  desired_capacity = var.desired_capacity

  # ヘルスチェック設定
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  # インスタンス保護設定
  protect_from_scale_in = var.protect_from_scale_in

  # ターゲットグループ設定（指定されている場合）
  target_group_arns = var.target_group_arns

  # ロードバランサー設定（指定されている場合）
  load_balancers = var.load_balancer_names

  # 終了ポリシー
  termination_policies = var.termination_policies

  # 通知設定
  enabled_metrics = var.enabled_metrics

  # 起動時の遅延設定
  default_cooldown = var.default_cooldown

  # インスタンス置換設定
  max_instance_lifetime = var.max_instance_lifetime

  # タグ設定
  dynamic "tag" {
    for_each = merge(
      local.final_common_tags,
      {
        Name = "${local.name_prefix}-asg-instance"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # 追加タグ（プロパゲート設定あり）
  dynamic "tag" {
    for_each = var.additional_tags
    content {
      key                 = tag.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }

  # インスタンス refresh設定
  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []
    content {
      strategy = var.instance_refresh_strategy

      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        instance_warmup        = var.instance_refresh_instance_warmup
        checkpoint_delay       = var.instance_refresh_checkpoint_delay
        checkpoint_percentages = var.instance_refresh_checkpoint_percentages
      }

      triggers = var.instance_refresh_triggers
    }
  }

  # 依存関係（起動テンプレートの変更時に更新）
  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# Auto Scaling Group通知設定
# ==================================================

resource "aws_autoscaling_notification" "asg_notifications" {
  count = var.enable_notifications ? 1 : 0

  group_names = [aws_autoscaling_group.main.name]

  notifications = var.notification_types

  topic_arn = aws_sns_topic.asg_notifications[0].arn
}

# ==================================================
# CloudWatch Alarms
# ==================================================

# CPU使用率アラーム（High）
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_cpu_high_alarm ? 1 : 0

  alarm_name          = "${local.name_prefix}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_high_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization for ${local.name_prefix}"
  alarm_actions       = var.enable_notifications ? [aws_sns_topic.asg_notifications[0].arn] : []
  ok_actions          = var.enable_notifications ? [aws_sns_topic.asg_notifications[0].arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(
    local.final_common_tags,
    {
      Name      = "${local.name_prefix}-asg-cpu-high-alarm"
      Component = "cloudwatch-alarm"
      Purpose   = "cpu-monitoring"
      Threshold = tostring(var.cpu_high_threshold)
    }
  )
}

# CPU使用率アラーム（Low）
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_cpu_low_alarm ? 1 : 0

  alarm_name          = "${local.name_prefix}-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_low_period
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization for ${local.name_prefix}"
  alarm_actions       = var.enable_notifications ? [aws_sns_topic.asg_notifications[0].arn] : []
  ok_actions          = var.enable_notifications ? [aws_sns_topic.asg_notifications[0].arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(
    local.final_common_tags,
    {
      Name      = "${local.name_prefix}-asg-cpu-low-alarm"
      Component = "cloudwatch-alarm"
      Purpose   = "cpu-monitoring"
      Threshold = tostring(var.cpu_low_threshold)
    }
  )
}

# ==================================================
# オートスケーリングポリシー
# ==================================================

# スケールアップポリシー
resource "aws_autoscaling_policy" "scale_up" {
  count = var.enable_scale_up_policy ? 1 : 0

  name                   = "${local.name_prefix}-asg-scale-up"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = var.scale_up_adjustment_type
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = var.scale_up_policy_type

  # ステップスケーリング設定（policy_typeがStepScalingの場合）
  dynamic "step_adjustment" {
    for_each = var.scale_up_policy_type == "StepScaling" ? var.scale_up_step_adjustments : []
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  # ターゲット追跡設定（policy_typeがTargetTrackingScalingの場合）
  dynamic "target_tracking_configuration" {
    for_each = var.scale_up_policy_type == "TargetTrackingScaling" ? [1] : []
    content {
      target_value = var.target_tracking_target_value

      predefined_metric_specification {
        predefined_metric_type = var.target_tracking_metric_type
      }

      disable_scale_in = var.target_tracking_disable_scale_in
    }
  }
}

# スケールダウンポリシー
resource "aws_autoscaling_policy" "scale_down" {
  count = var.enable_scale_down_policy ? 1 : 0

  name                   = "${local.name_prefix}-asg-scale-down"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = var.scale_down_adjustment_type
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = var.scale_down_policy_type

  # ステップスケーリング設定（policy_typeがStepScalingの場合）
  dynamic "step_adjustment" {
    for_each = var.scale_down_policy_type == "StepScaling" ? var.scale_down_step_adjustments : []
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  # ターゲット追跡設定（policy_typeがTargetTrackingScalingの場合）
  dynamic "target_tracking_configuration" {
    for_each = var.scale_down_policy_type == "TargetTrackingScaling" ? [1] : []
    content {
      target_value = var.target_tracking_target_value_down

      predefined_metric_specification {
        predefined_metric_type = var.target_tracking_metric_type_down
      }

      disable_scale_in = var.target_tracking_disable_scale_in_down
    }
  }
}

# ==================================================
# CloudWatch Alarm for Auto Scaling
# ==================================================

# スケールアップ用CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  count = var.enable_scale_up_policy && var.enable_scale_up_alarm ? 1 : 0

  alarm_name          = "${local.name_prefix}-asg-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.scale_up_alarm_evaluation_periods
  metric_name         = var.scale_up_alarm_metric_name
  namespace           = "AWS/EC2"
  period              = var.scale_up_alarm_period
  statistic           = var.scale_up_alarm_statistic
  threshold           = var.scale_up_alarm_threshold
  alarm_description   = "This metric triggers scale up for ${local.name_prefix}"
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(
    local.final_common_tags,
    {
      Name      = "${local.name_prefix}-asg-scale-up-alarm"
      Component = "cloudwatch-alarm"
      Purpose   = "auto-scaling"
      ScaleType = "scale-up"
      Threshold = tostring(var.scale_up_alarm_threshold)
    }
  )
}

# スケールダウン用CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  count = var.enable_scale_down_policy && var.enable_scale_down_alarm ? 1 : 0

  alarm_name          = "${local.name_prefix}-asg-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.scale_down_alarm_evaluation_periods
  metric_name         = var.scale_down_alarm_metric_name
  namespace           = "AWS/EC2"
  period              = var.scale_down_alarm_period
  statistic           = var.scale_down_alarm_statistic
  threshold           = var.scale_down_alarm_threshold
  alarm_description   = "This metric triggers scale down for ${local.name_prefix}"
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(
    local.final_common_tags,
    {
      Name      = "${local.name_prefix}-asg-scale-down-alarm"
      Component = "cloudwatch-alarm"
      Purpose   = "auto-scaling"
      ScaleType = "scale-down"
      Threshold = tostring(var.scale_down_alarm_threshold)
    }
  )
}
