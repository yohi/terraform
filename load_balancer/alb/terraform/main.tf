# ==================================================
# ローカル変数
# ==================================================

locals {
  # 命名規則: ${project}-${env}-${app}-{suffix} (${app}は省略可能)
  alb_name = var.alb_name != "" ? var.alb_name : "${var.project}-${var.env}${var.app != "" ? "-${var.app}" : ""}-alb"
  target_group_name = var.target_group_name != "" ? var.target_group_name : "${var.project}-${var.env}${var.app != "" ? "-${var.app}" : ""}-tg"
  security_group_name = "${var.project}-${var.env}${var.app != "" ? "-${var.app}" : ""}-alb-sg"
}

# ==================================================
# セキュリティグループ
# ==================================================

resource "aws_security_group" "alb" {
  name        = local.security_group_name
  vpc_id      = var.vpc_id

  # HTTP (80) - IPv4
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (80) - IPv6
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTPS (443) - IPv4
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (443) - IPv6
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = local.security_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# Application Load Balancer
# ==================================================

resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = concat([aws_security_group.alb.id], var.additional_security_group_ids)
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  ip_address_type                  = var.ip_address_type

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(var.common_tags, {
    Name = local.alb_name
  })
}

# ==================================================
# ターゲットグループ
# ==================================================

resource "aws_lb_target_group" "main" {
  name     = local.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  target_type = var.target_type

  # ECS用の設定
  deregistration_delay = 30  # ECSタスクの停止時間を短縮

  health_check {
    enabled             = var.health_check_enabled
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = var.health_check_port
    protocol            = var.health_check_protocol
  }

  tags = merge(var.common_tags, {
    Name = local.target_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# リスナー
# ==================================================

# HTTPリスナー（80番ポート）- HTTPSにリダイレクト
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${local.alb_name}-http-listener"
  })
}

# HTTPSリスナー（443番ポート）- 404 Not Foundを返す
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1><p>The requested resource was not found on this server.</p></body></html>"
      status_code  = "404"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${local.alb_name}-https-listener"
  })
}
