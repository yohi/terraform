# Mock configurations for ALB Module Tests
# This file provides mock data for AWS resources during unit testing

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      id                   = "vpc-12345678"
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      tags = {
        Name = "test-vpc"
      }
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      id                = "subnet-12345678"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-northeast-1a"
      tags = {
        Name = "test-subnet"
      }
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id          = "sg-12345678"
      arn         = "arn:aws:ec2:ap-northeast-1:123456789012:security-group/sg-12345678"
      name        = "test-alb-sg"
      description = "Security group for ALB"
      vpc_id      = "vpc-12345678"
      ingress = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port        = 80
          to_port          = 80
          protocol         = "tcp"
          ipv6_cidr_blocks = ["::/0"]
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          from_port        = 443
          to_port          = 443
          protocol         = "tcp"
          ipv6_cidr_blocks = ["::/0"]
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Name = "test-alb-sg"
      }
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      id                               = "alb-12345678"
      name                             = "test-alb"
      arn                              = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
      arn_suffix                       = "app/test-alb/1234567890123456"
      dns_name                         = "test-alb-123456789.ap-northeast-1.elb.amazonaws.com"
      zone_id                          = "Z2YN17T5R711GT"
      load_balancer_type               = "application"
      internal                         = false
      security_groups                  = ["sg-12345678"]
      subnets                          = ["subnet-12345678", "subnet-87654321"]
      enable_deletion_protection       = false
      idle_timeout                     = 60
      enable_cross_zone_load_balancing = true
      enable_http2                     = true
      ip_address_type                  = "ipv4"
      access_logs = [
        {
          bucket  = ""
          enabled = false
          prefix  = ""
        }
      ]
      tags = {
        Name = "test-alb"
      }
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      id                   = "tg-12345678"
      name                 = "test-tg"
      arn                  = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-tg/1234567890123456"
      arn_suffix           = "targetgroup/test-tg/1234567890123456"
      port                 = 80
      protocol             = "HTTP"
      vpc_id               = "vpc-12345678"
      target_type          = "ip"
      deregistration_delay = "30"
      health_check = [
        {
          enabled             = true
          healthy_threshold   = 2
          unhealthy_threshold = 2
          timeout             = 10
          interval            = 15
          path                = "/"
          matcher             = "200"
          port                = "traffic-port"
          protocol            = "HTTP"
        }
      ]
      tags = {
        Name = "test-tg"
      }
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      id                = "listener-12345678"
      arn               = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:listener/app/test-alb/1234567890123456/1234567890123456"
      load_balancer_arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
      port              = 80
      protocol          = "HTTP"
      ssl_policy        = null
      certificate_arn   = null
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
      tags = {
        Name = "test-alb-listener"
      }
    }
  }
}

# Simple mock test to verify the mock provider setup
run "mock_test" {
  command = apply

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    common_tags = {
      Project     = "test"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "mock"
    }
  }

  assert {
    condition     = aws_lb.main.name == "test-dev-alb"
    error_message = "ALB name should be 'test-dev-alb'"
  }

  assert {
    condition     = aws_security_group.alb.name == "test-dev-alb-sg"
    error_message = "Security group name should be 'test-dev-alb-sg'"
  }

  assert {
    condition     = aws_lb_target_group.main.name == "test-dev-tg"
    error_message = "Target group name should be 'test-dev-tg'"
  }

  assert {
    condition     = aws_lb_listener.http.port == 80
    error_message = "HTTP listener should listen on port 80"
  }

  assert {
    condition     = aws_lb_listener.https.port == 443
    error_message = "HTTPS listener should listen on port 443"
  }

  assert {
    condition     = output.alb_id != ""
    error_message = "ALB ID output should not be empty"
  }

  assert {
    condition     = output.target_group_arn != ""
    error_message = "Target group ARN output should not be empty"
  }

  assert {
    condition     = output.security_group_id != ""
    error_message = "Security group ID output should not be empty"
  }

  assert {
    condition     = output.load_balancer_url != ""
    error_message = "Load balancer URL output should not be empty"
  }

  assert {
    condition     = can(regex("^https://", output.load_balancer_url))
    error_message = "Load balancer URL should start with 'https://'"
  }
}
