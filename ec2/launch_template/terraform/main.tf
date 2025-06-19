# ==================================================
# データソース
# ==================================================

# デフォルトVPCの取得
data "aws_vpc" "default" {
  default = true
}

# Amazon Linux 2023 ECS最適化AMIの取得
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==================================================
# ローカル変数（Mackerel設定）
# ==================================================

locals {
  # APIキーの決定（優先順位: 明示的指定 > デフォルト値）
  effective_mackerel_api_key = var.mackerel_api_key != "" ? var.mackerel_api_key : var.mackerel_default_api_key

  # 表示名の決定（優先順位: 明示的指定 > 自動生成）
  effective_mackerel_display_name = var.mackerel_display_name != "" ? var.mackerel_display_name : (
    var.app != "" ? "${var.project}-${var.env}-${var.app}" : "${var.project}-${var.env}"
  )

  # ロールの決定（優先順位: 明示的指定 > デフォルト値）
  effective_mackerel_roles = var.mackerel_roles != "" ? var.mackerel_roles : join(",", var.mackerel_default_roles)

  # Mackerel設定のテンプレート化
  default_mackerel_config = var.create_default_mackerel_config && var.mackerel_agent_config == "" ? templatefile("${path.module}/../templates/monitoring/mackerel-agent.conf.tpl", {
    api_key      = local.effective_mackerel_api_key
    display_name = local.effective_mackerel_display_name
    roles        = local.effective_mackerel_roles
  }) : var.mackerel_agent_config

  # Parameter Storeに保存する最終的なMackerel設定
  final_mackerel_config = local.default_mackerel_config != "" ? local.default_mackerel_config : var.mackerel_agent_config

  # Mackerel sysconfig設定
  default_mackerel_sysconfig = var.mackerel_enable_sysconfig && var.mackerel_sysconfig_template == "" ? templatefile("${path.module}/../templates/monitoring/mackerel-sysconfig.tpl", {
    api_key             = local.effective_mackerel_api_key
    organization        = var.mackerel_organization
    roles               = local.effective_mackerel_roles
    auto_retirement     = var.mackerel_auto_retirement != "" ? var.mackerel_auto_retirement : "1"
    additional_env_vars = var.mackerel_additional_env_vars
  }) : var.mackerel_sysconfig_template

  # Parameter Storeに保存する最終的なsysconfig設定
  final_mackerel_sysconfig = local.default_mackerel_sysconfig != "" ? local.default_mackerel_sysconfig : var.mackerel_sysconfig_template
}

# ==================================================
# ローカル変数（CloudWatch設定）
# ==================================================

locals {
  # ネームスペースの決定（優先順位: 明示的指定 > 自動生成）
  effective_cloudwatch_namespace = var.cloudwatch_default_namespace != "" ? var.cloudwatch_default_namespace : "${var.project}-metrics"

  # CloudWatch Agent設定のテンプレート化
  default_cloudwatch_config = var.create_default_cloudwatch_config && var.cloudwatch_agent_config_json == "" ? templatefile("${path.module}/../templates/monitoring/cloudwatch-agent.json.tpl", {
    namespace                     = local.effective_cloudwatch_namespace
    metrics_collection_interval   = var.cloudwatch_metrics_collection_interval
    run_as_user                  = var.cloudwatch_run_as_user
    cpu_metrics                  = jsonencode(var.cloudwatch_cpu_metrics)
    disk_metrics                 = jsonencode(var.cloudwatch_disk_metrics)
    disk_resources               = jsonencode(var.cloudwatch_disk_resources)
    diskio_metrics               = jsonencode(var.cloudwatch_diskio_metrics)
    mem_metrics                  = jsonencode(var.cloudwatch_mem_metrics)
    enable_statsd                = var.cloudwatch_enable_statsd
    statsd_port                  = var.cloudwatch_statsd_port
  }) : var.cloudwatch_agent_config_json

  # Parameter Storeに保存する最終的なCloudWatch設定
  final_cloudwatch_config = local.default_cloudwatch_config != "" ? local.default_cloudwatch_config : var.cloudwatch_agent_config_json
}

# ==================================================
# セキュリティグループ
# ==================================================

resource "aws_security_group" "main" {
  name        = "${var.project}-${var.env}-ec2-sg"
  description = "EC2インスタンス用セキュリティグループ"
  vpc_id      = data.aws_vpc.default.id

  # SSH (22)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  # HTTP (80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (443)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ECSコンテナポート範囲（動的ポートマッピング用）
  ingress {
    description = "ECS Dynamic Ports"
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # アウトバウンド（すべて許可）
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project}-${var.env}-ec2-sg"
    }
  )
}

# ==================================================
# EC2起動テンプレート
# ==================================================

resource "aws_launch_template" "main" {
  name_prefix = var.app != "" ? "${var.project}-${var.env}-${var.app}-tpl-" : "${var.project}-${var.env}-tpl-"
  description = "EC2起動テンプレート for ${var.project}-${var.env}"

  # AMI設定（Amazon Linux 2023 ECS最適化）
  image_id = data.aws_ami.amazon_linux.id

  # インスタンスタイプ
  instance_type = var.instance_type

  # キーペア
  key_name = var.key_name != "" ? var.key_name : null

  # VPCセキュリティグループ
  vpc_security_group_ids = [aws_security_group.main.id]

  # ストレージ設定
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  # ネットワークインターフェース設定
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.main.id]
    delete_on_termination       = true
  }

  # IAMインスタンスプロファイル
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  # ユーザーデータ
  user_data = base64encode(templatefile("${path.module}/../templates/scripts/user_data.sh", {
    aws_region                = var.aws_region
    ecs_cluster_name         = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project}-${var.env}-ecs"
    ecs_app_type             = var.app != "" ? upper(var.app) : ""
    cloudwatch_agent_config  = var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : "AmazonCloudWatch-Agent_${var.project}-ecs"
    mackerel_api_key         = var.mackerel_api_key
    mackerel_parameter_prefix = var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"
    mackerel_auto_retirement = var.mackerel_auto_retirement
    ctop_version             = var.ctop_version
    custom_user_data         = var.custom_user_data
  }))

  # インスタンスタグ設定
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = var.app != "" ? "${var.project}-${var.env}-${var.app}-ec2" : "${var.project}-${var.env}-ec2"
      }
    )
  }

  # ボリュームタグ設定
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name = var.app != "" ? "${var.project}-${var.env}-${var.app}-volume" : "${var.project}-${var.env}-volume"
      }
    )
  }

  # ネットワークインターフェースタグ設定
  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      var.common_tags,
      {
        Name = var.app != "" ? "${var.project}-${var.env}-${var.app}-eni" : "${var.project}-${var.env}-eni"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.app != "" ? "${var.project}-${var.env}-${var.app}-tpl" : "${var.project}-${var.env}-tpl"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# Parameter Store パラメータ
# ==================================================

# Mackerel APIキー
resource "aws_ssm_parameter" "mackerel_api_key" {
  count = var.create_parameter_store && local.effective_mackerel_api_key != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}api-key"
  type  = "SecureString"
  value = local.effective_mackerel_api_key

  key_id = var.parameter_store_kms_key_id != "" ? var.parameter_store_kms_key_id : null

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-api-key"
    }
  )
}

# Mackerel表示名
resource "aws_ssm_parameter" "mackerel_display_name" {
  count = var.create_parameter_store && local.effective_mackerel_display_name != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}display-name"
  type  = "String"
  value = local.effective_mackerel_display_name

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-display-name"
    }
  )
}

# Mackerel組織名
resource "aws_ssm_parameter" "mackerel_organization" {
  count = var.create_parameter_store && var.mackerel_organization != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}organization"
  type  = "String"
  value = var.mackerel_organization

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-organization"
    }
  )
}

# Mackerelロール
resource "aws_ssm_parameter" "mackerel_roles" {
  count = var.create_parameter_store && local.effective_mackerel_roles != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}roles"
  type  = "String"
  value = local.effective_mackerel_roles

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-roles"
    }
  )
}

# Mackerel自動退役設定
resource "aws_ssm_parameter" "mackerel_auto_retirement" {
  count = var.create_parameter_store && var.mackerel_auto_retirement != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}auto-retirement"
  type  = "String"
  value = var.mackerel_auto_retirement

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-auto-retirement"
    }
  )
}

# Mackerelエージェント設定
resource "aws_ssm_parameter" "mackerel_agent_config" {
  count = var.create_parameter_store && local.final_mackerel_config != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}api-conf"
  type  = "String"
  value = local.final_mackerel_config

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-agent-config"
    }
  )
}

# Mackerel sysconfig設定
resource "aws_ssm_parameter" "mackerel_sysconfig_config" {
  count = var.create_parameter_store && local.final_mackerel_sysconfig != "" ? 1 : 0

  name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project}/${var.env}/mackerel/"}agent"
  type  = "String"
  value = local.final_mackerel_sysconfig

  tags = merge(
    var.common_tags,
    {
      Name = "mackerel-sysconfig"
    }
  )
}

# CloudWatchエージェント設定
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.create_parameter_store && local.final_cloudwatch_config != "" ? 1 : 0

  name  = var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : "AmazonCloudWatch-Agent_${var.project}-ecs"
  type  = "String"
  value = local.final_cloudwatch_config

  tags = merge(
    var.common_tags,
    {
      Name = "cloudwatch-agent-config"
    }
  )
}
