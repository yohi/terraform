# ==================================================
# ECSサービスとALBの統合例
# ==================================================
# このファイルは参考例です。実際の使用時は適切な場所にコピーして使用してください。

# 変数定義
variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myproject"
}

variable "env" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-xxxxxxxxx"
}

variable "private_subnet_ids" {
  description = "プライベートサブネットIDのリスト"
  type        = list(string)
  default     = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
}

variable "hosted_zone_id" {
  description = "Route53 ホステッドゾーンID（オプション）"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "ドメイン名（オプション）"
  type        = string
  default     = "example.com"
}

# ALBモジュールの呼び出し例
module "alb" {
  source = "./terraform"

  # 基本設定
  project = var.project_name
      env     = var.environment
  app     = "web"

  # ネットワーク設定
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # ECS用設定
  target_type           = "ip"
  target_group_port     = 80
  target_group_protocol = "HTTP"
  health_check_path     = "/health"
  health_check_interval = 15
  health_check_timeout  = 10
  health_check_matcher  = "200"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "load-balancer"
  }
}

# ==================================================
# ECS クラスター
# ==================================================
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  # パフォーマンス最適化
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ==================================================
# ECS タスク実行ロール
# ==================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.env}-ecs-task-execution-role"

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

  tags = {
    Name        = "${var.project_name}-${var.env}-ecs-task-execution-role"
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==================================================
# ECS タスク定義
# ==================================================
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project_name}-${var.env}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "web"
      image = "nginx:alpine"

      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.env}-web"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.env}-web-task"
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# CloudWatch ログ グループ
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.project_name}-${var.env}-web"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.env}-web-logs"
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# データソース
data "aws_region" "current" {}

# ==================================================
# ECS サービス
# ==================================================
resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-${var.env}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # ALBとの統合
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "web"
    container_port   = 80
  }

  # ネットワーク設定（Fargate使用時）
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # ALBのヘルスチェックに依存
  depends_on = [
    module.alb,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
  ]

  # ECSサービスの更新設定
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  # サービス発見（オプション）
  # service_registries {
  #   registry_arn = aws_service_discovery_service.web.arn
  # }

  tags = {
    Name        = "${var.project_name}-${var.env}-web"
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# ECSタスク用セキュリティグループ
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-${var.env}-ecs-tasks-"
  vpc_id      = var.vpc_id

  # ALBからのトラフィックを許可
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  # アウトバウンドトラフィックを許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-ecs-tasks"
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# Route53 レコード作成（オプション）
# ==================================================
resource "aws_route53_record" "web" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "web.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_hosted_zone_id
    evaluate_target_health = true
  }
}
