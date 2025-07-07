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

# Amazon Linux 2023 ECS最適化AMIの取得
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = var.ami_name_filter
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
    var.app != "" ? "${var.project_name}-${var.environment}-${var.app}" : "${var.project_name}-${var.environment}"
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
  effective_cloudwatch_namespace = var.cloudwatch_default_namespace != "" ? var.cloudwatch_default_namespace : "${var.project_name}-metrics"

  # CloudWatch Agent設定のテンプレート化
  default_cloudwatch_config = var.create_default_cloudwatch_config && var.cloudwatch_agent_config_json == "" ? templatefile("${path.module}/../templates/monitoring/cloudwatch-agent.json.tpl", {
    namespace                   = local.effective_cloudwatch_namespace
    metrics_collection_interval = var.cloudwatch_metrics_collection_interval
    run_as_user                 = var.cloudwatch_run_as_user
    cpu_metrics                 = jsonencode(var.cloudwatch_cpu_metrics)
    disk_metrics                = jsonencode(var.cloudwatch_disk_metrics)
    disk_resources              = jsonencode(var.cloudwatch_disk_resources)
    diskio_metrics              = jsonencode(var.cloudwatch_diskio_metrics)
    mem_metrics                 = jsonencode(var.cloudwatch_mem_metrics)
    enable_statsd               = var.cloudwatch_enable_statsd
    statsd_port                 = var.cloudwatch_statsd_port
  }) : var.cloudwatch_agent_config_json

  # Parameter Storeに保存する最終的なCloudWatch設定
  final_cloudwatch_config = local.default_cloudwatch_config != "" ? local.default_cloudwatch_config : var.cloudwatch_agent_config_json
}

# ==================================================
# ローカル変数（タグ戦略）
# ==================================================

locals {
  # 基本タグ（すべてのリソースに適用）
  base_tags = {
    "ManagedBy"          = "terraform"
    "TerraformWorkspace" = terraform.workspace
    "Project"            = var.project_name
    "Environment"        = var.environment
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
    "BillingCode"     = var.billing_code != "" ? var.billing_code : "PROJ-2024-${var.project_name}"
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
  env_tags = var.environment == "prod" ? {
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
    "Service"      = "compute"
    "Component"    = "launch-template"
    "Tier"         = "application"
    "InstanceType" = var.instance_type
    "AMI"          = "amazon-linux-2023-ecs"
  }

  # 最終的な共通タグ（優先度: 共通タグ > 環境固有 > セキュリティ > 運用 > サービス > 基本）
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
# セキュリティグループ
# ==================================================

resource "aws_security_group" "main" {
      name        = "${var.project_name}-${var.environment}-ec2-sg"
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
    local.final_common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-ec2-sg"
      Component = "security-group"
      Purpose   = "ec2-access-control"
    }
  )
}

# ==================================================
# EC2起動テンプレート
# ==================================================

resource "aws_launch_template" "main" {
      name_prefix = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-tpl-" : "${var.project_name}-${var.environment}-tpl-"
      description = "EC2起動テンプレート for ${var.project_name}-${var.environment}"

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

  # メタデータオプション（IMDSv2強制）
  metadata_options {
    http_tokens = "required"
  }

  # ユーザーデータ
  user_data = base64encode(templatefile("${path.module}/../templates/scripts/user_data.sh", {
    aws_region                = var.aws_region
          ecs_cluster_name          = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project_name}-${var.environment}-ecs"
    ecs_app_type              = var.app != "" ? upper(var.app) : ""
          cloudwatch_agent_config   = var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : "/${var.project_name}/${var.environment}/config/cloudwatch/agent"
    mackerel_api_key          = local.effective_mackerel_api_key
          mackerel_parameter_prefix = var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"
    mackerel_auto_retirement  = var.mackerel_auto_retirement
    ctop_version              = var.ctop_version
    custom_user_data          = var.custom_user_data
  }))

  # インスタンスタグ設定
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.final_common_tags,
      {
        Name = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-ec2" : "${var.project_name}-${var.environment}-ec2"
      }
    )
  }

  # ボリュームタグ設定
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.final_common_tags,
      {
        Name      = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-volume" : "${var.project_name}-${var.environment}-volume"
        Component = "ebs-volume"
        Purpose   = "root-storage"
      }
    )
  }

  # ネットワークインターフェースタグ設定
  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      local.final_common_tags,
      {
        Name      = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-eni" : "${var.project_name}-${var.environment}-eni"
        Component = "network-interface"
        Purpose   = "ec2-network"
      }
    )
  }

  tags = merge(
    local.final_common_tags,
    {
              Name      = var.app != "" ? "${var.project_name}-${var.environment}-${var.app}-tpl" : "${var.project_name}-${var.environment}-tpl"
      Component = "launch-template"
      Purpose   = "ec2-instance-template"
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

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}api-key"
  type  = "SecureString"
  value = local.effective_mackerel_api_key

  key_id = var.parameter_store_kms_key_id != "" ? var.parameter_store_kms_key_id : null

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-api-key"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
      Sensitive = "yes"
    }
  )
}

# Mackerel表示名
resource "aws_ssm_parameter" "mackerel_display_name" {
  count = var.create_parameter_store && local.effective_mackerel_display_name != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}display-name"
  type  = "String"
  value = local.effective_mackerel_display_name

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-display-name"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# Mackerel組織名
resource "aws_ssm_parameter" "mackerel_organization" {
  count = var.create_parameter_store && var.mackerel_organization != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}organization"
  type  = "String"
  value = var.mackerel_organization

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-organization"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# Mackerelロール
resource "aws_ssm_parameter" "mackerel_roles" {
  count = var.create_parameter_store && local.effective_mackerel_roles != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}roles"
  type  = "String"
  value = local.effective_mackerel_roles

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-roles"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# Mackerel自動退役設定
resource "aws_ssm_parameter" "mackerel_auto_retirement" {
  count = var.create_parameter_store && var.mackerel_auto_retirement != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}auto-retirement"
  type  = "String"
  value = var.mackerel_auto_retirement

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-auto-retirement"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# Mackerelエージェント設定
resource "aws_ssm_parameter" "mackerel_agent_config" {
  count = var.create_parameter_store && local.final_mackerel_config != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}api-conf"
  type  = "String"
  value = local.final_mackerel_config

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-agent-config"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# Mackerel sysconfig設定
resource "aws_ssm_parameter" "mackerel_sysconfig_config" {
  count = var.create_parameter_store && local.final_mackerel_sysconfig != "" ? 1 : 0

      name  = "${var.mackerel_parameter_prefix != "" ? var.mackerel_parameter_prefix : "/${var.project_name}/${var.environment}/config/mackerel/"}agent"
  type  = "String"
  value = local.final_mackerel_sysconfig

  tags = merge(
    local.final_common_tags,
    {
      Name      = "mackerel-sysconfig"
      Component = "parameter-store"
      Purpose   = "mackerel-configuration"
    }
  )
}

# CloudWatchエージェント設定
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.create_parameter_store && local.final_cloudwatch_config != "" ? 1 : 0

      name  = var.cloudwatch_agent_config != "" ? var.cloudwatch_agent_config : "/${var.project_name}/${var.environment}/config/cloudwatch/agent"
  type  = "String"
  value = local.final_cloudwatch_config

  tags = merge(
    local.final_common_tags,
    {
      Name      = "cloudwatch-agent-config"
      Component = "parameter-store"
      Purpose   = "cloudwatch-configuration"
    }
  )
}
