# ==================================================
# ECSサービスとALBの統合例
# ==================================================
# このファイルは参考例です。実際の使用時は適切な場所にコピーして使用してください。

# ALBモジュールの呼び出し例
module "alb" {
  source = "./load_balancer/alb/terraform"

  # 基本設定
  project = "myproject"
  env     = "dev"
  app     = "web"

  # ネットワーク設定
  vpc_id     = "vpc-xxxxxxxxx"
  subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]

  # ECS用設定
  target_type               = "ip"
  target_group_port         = 80
  target_group_protocol     = "HTTP"
  health_check_path         = "/health"
  health_check_interval     = 15
  health_check_timeout      = 10
  health_check_matcher      = "200"

  common_tags = {
    Project     = "myproject"
    Environment = "dev"
    ManagedBy   = "terraform"
    Component   = "load-balancer"
  }
}

# ECSサービスの例
resource "aws_ecs_service" "web" {
  name            = "${var.project}-${var.env}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 2

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
    aws_lb_listener.main,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
  ]

  # ECSサービスの更新設定
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  # サービス発見（オプション）
  service_registries {
    registry_arn = aws_service_discovery_service.web.arn
  }

  tags = {
    Name        = "${var.project}-${var.env}-web"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# ECSタスク用セキュリティグループ
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project}-${var.env}-ecs-tasks-"
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
    Name        = "${var.project}-${var.env}-ecs-tasks"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 使用例：Route53レコード作成
resource "aws_route53_record" "web" {
  zone_id = var.hosted_zone_id
  name    = "web.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_hosted_zone_id
    evaluate_target_health = true
  }
}
