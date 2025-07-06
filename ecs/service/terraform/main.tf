# ==================================================
# データソース
# ==================================================

# デフォルトVPCの取得
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

# VPCの取得
data "aws_vpc" "selected" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

# サブネットの取得
data "aws_subnets" "default" {
  count = length(var.subnet_ids) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id]
  }
}

# ==================================================
# ローカル変数
# ==================================================

locals {
  # VPC ID
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id

  # サブネット ID
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default[0].ids

  # タスク定義ファミリー名
  task_definition_family = var.task_definition_family != "" ? var.task_definition_family : "${var.project_name}-${var.env}-${var.app}"

  # サービス名
  service_name = var.service_name != "" ? var.service_name : "${var.project_name}-${var.env}-${var.app}-service"

  # コンテナ名
  container_name = var.container_name != "" ? var.container_name : "${var.project_name}-${var.env}-${var.app}"

  # ログ設定
  log_group_name = var.log_group_name != "" ? var.log_group_name : "/ecs/${local.task_definition_family}"

  # ロードバランサー設定
  load_balancer_container_name = var.load_balancer_container_name != "" ? var.load_balancer_container_name : local.container_name

  # 環境変数の変換
  environment = [
    for key, value in var.environment_variables : {
      name  = key
      value = value
    }
  ]

  # デフォルトコンテナ定義
  default_container_definition = merge(
    {
      name      = local.container_name
      image     = var.container_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = var.container_protocol
        }
      ]

      environment = local.environment
      secrets     = var.secrets
    },
    var.enable_logging ? {
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main[0].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.log_stream_prefix
        }
      }
    } : {}
  )

  # 最終的なコンテナ定義
  container_definitions = length(var.container_definitions) > 0 ? var.container_definitions : [local.default_container_definition]
}

# ==================================================
# CloudWatchロググループ
# ==================================================

resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_logging ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = merge(
    var.common_tags,
    {
      Name = local.log_group_name
    }
  )
}

# ==================================================
# IAMロール（タスク実行ロール）
# ==================================================

resource "aws_iam_role" "execution_role" {
  count = var.execution_role_arn == "" ? 1 : 0

  name = "${local.task_definition_family}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${local.task_definition_family}-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  count = var.execution_role_arn == "" ? 1 : 0

  role       = aws_iam_role.execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatchログ用の追加ポリシー
resource "aws_iam_role_policy" "execution_role_logs" {
  count = var.execution_role_arn == "" && var.enable_logging ? 1 : 0

  name = "${local.task_definition_family}-execution-logs-policy"
  role = aws_iam_role.execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.main[0].arn,
          "${aws_cloudwatch_log_group.main[0].arn}:*"
        ]
      }
    ]
  })
}

# ==================================================
# IAMロール（タスクロール）
# ==================================================

resource "aws_iam_role" "task_role" {
  count = var.task_role_arn == "" ? 1 : 0

  name = "${local.task_definition_family}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${local.task_definition_family}-task-role"
    }
  )
}

# Execute Command用のポリシー
resource "aws_iam_role_policy" "task_role_execute_command" {
  count = var.task_role_arn == "" && var.enable_execute_command ? 1 : 0

  name = "${local.task_definition_family}-execute-command-policy"
  role = aws_iam_role.task_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================================================
# セキュリティグループ
# ==================================================

resource "aws_security_group" "main" {
  name        = "${local.service_name}-sg"
  description = "Security group for ${local.service_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "Container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id != "" ? data.aws_vpc.selected[0].cidr_block : data.aws_vpc.default[0].cidr_block]
  }

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
      Name = "${local.service_name}-sg"
    }
  )
}

# ==================================================
# ECSタスク定義
# ==================================================

resource "aws_ecs_task_definition" "main" {
  family                   = local.task_definition_family
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = var.execution_role_arn != "" ? var.execution_role_arn : aws_iam_role.execution_role[0].arn
  task_role_arn      = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.task_role[0].arn

  container_definitions = jsonencode(local.container_definitions)

  lifecycle {
    precondition {
      condition     = var.launch_type != "FARGATE" || var.network_mode == "awsvpc"
      error_message = "Fargateを使用する場合、network_mode は awsvpc である必要があります。"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = local.task_definition_family
    }
  )
}

# ==================================================
# ECSサービス
# ==================================================

resource "aws_ecs_service" "main" {
  name             = local.service_name
  cluster          = var.cluster_name
  task_definition  = aws_ecs_task_definition.main.arn
  desired_count    = var.desired_count
  launch_type      = var.launch_type
  platform_version = var.launch_type == "FARGATE" ? var.platform_version : null

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = concat([aws_security_group.main.id], var.security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = local.load_balancer_container_name
      container_port   = var.load_balancer_container_port
    }
  }

  health_check_grace_period_seconds = var.target_group_arn != "" ? var.health_check_grace_period_seconds : null

  deployment_configuration {
    maximum_percent         = var.deployment_maximum_percent
    minimum_healthy_percent = var.deployment_minimum_healthy_percent
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_deployment_circuit_breaker ? [1] : []
    content {
      enable   = var.enable_deployment_circuit_breaker
      rollback = var.deployment_circuit_breaker_rollback
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = local.service_name
    }
  )
}

# ==================================================
# Auto Scaling設定
# ==================================================

resource "aws_appautoscaling_target" "main" {
  count = var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.common_tags
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${local.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.target_cpu_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${local.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.target_memory_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
