# Validation tests for ALB Module
# Tests input validation and error handling

# Using mock provider for testing
provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "ap-northeast-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

mock_provider "aws" {
  alias = "fake"

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
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      id                = "subnet-12345678"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-northeast-1a"
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id          = "sg-12345678"
      name        = "test-alb-sg"
      description = "Security group for ALB"
      vpc_id      = "vpc-12345678"
      ingress     = []
      egress      = []
      tags        = {}
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
      tags                             = {}
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      id           = "tg-12345678"
      name         = "test-tg"
      arn          = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-tg/1234567890123456"
      arn_suffix   = "targetgroup/test-tg/1234567890123456"
      port         = 80
      protocol     = "HTTP"
      vpc_id       = "vpc-12345678"
      target_type  = "ip"
      health_check = []
      tags         = {}
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      id                = "listener-12345678"
      arn               = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:listener/app/test-alb/1234567890123456/1234567890123456"
      load_balancer_arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:loadbalancer/app/test-alb/1234567890123456"
      port              = 80
      protocol          = "HTTP"
      default_action    = []
      tags              = {}
    }
  }
}

# Test 1: Valid environment values
run "valid_environment_prd" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "prd"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.environment == "prd"
    error_message = "Environment should be 'prd'"
  }
}

run "valid_environment_rls" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "rls"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.environment == "rls"
    error_message = "Environment should be 'rls'"
  }
}

run "valid_environment_stg" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "stg"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.environment == "stg"
    error_message = "Environment should be 'stg'"
  }
}

run "valid_environment_dev" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment should be 'dev'"
  }
}

# Test 2: Invalid environment value should fail
run "invalid_environment" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "invalid"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  expect_failures = [
    var.environment,
  ]
}

# Test 3: Subnet IDs validation - minimum 2 subnets
run "minimum_subnet_ids" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Should have at least 2 subnet IDs"
  }
}

# Test 4: Insufficient subnet IDs should fail
run "insufficient_subnet_ids" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  expect_failures = [
    var.subnet_ids,
  ]
}

# Test 5: Valid IP address type values
run "valid_ip_address_type_ipv4" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    ip_address_type     = "ipv4"
  }

  assert {
    condition     = var.ip_address_type == "ipv4"
    error_message = "IP address type should be 'ipv4'"
  }
}

run "valid_ip_address_type_dualstack" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    ip_address_type     = "dualstack"
  }

  assert {
    condition     = var.ip_address_type == "dualstack"
    error_message = "IP address type should be 'dualstack'"
  }
}

# Test 6: Invalid IP address type should fail
run "invalid_ip_address_type" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    ip_address_type     = "invalid"
  }

  expect_failures = [
    var.ip_address_type,
  ]
}

# Test 7: Valid target group protocol values
run "valid_target_group_protocol_http" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_group_protocol = "HTTP"
  }

  assert {
    condition     = var.target_group_protocol == "HTTP"
    error_message = "Target group protocol should be 'HTTP'"
  }
}

run "valid_target_group_protocol_https" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_group_protocol = "HTTPS"
  }

  assert {
    condition     = var.target_group_protocol == "HTTPS"
    error_message = "Target group protocol should be 'HTTPS'"
  }
}

# Test 8: Invalid target group protocol should fail
run "invalid_target_group_protocol" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_group_protocol = "TCP"
  }

  expect_failures = [
    var.target_group_protocol,
  ]
}

# Test 9: Valid target type values
run "valid_target_type_instance" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_type         = "instance"
  }

  assert {
    condition     = var.target_type == "instance"
    error_message = "Target type should be 'instance'"
  }
}

run "valid_target_type_ip" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_type         = "ip"
  }

  assert {
    condition     = var.target_type == "ip"
    error_message = "Target type should be 'ip'"
  }
}

run "valid_target_type_lambda" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_type         = "lambda"
  }

  assert {
    condition     = var.target_type == "lambda"
    error_message = "Target type should be 'lambda'"
  }
}

# Test 10: Invalid target type should fail
run "invalid_target_type" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_type         = "invalid"
  }

  expect_failures = [
    var.target_type,
  ]
}

# Test 11: Valid health check protocol values
run "valid_health_check_protocol_http" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    health_check_protocol = "HTTP"
  }

  assert {
    condition     = var.health_check_protocol == "HTTP"
    error_message = "Health check protocol should be 'HTTP'"
  }
}

run "valid_health_check_protocol_https" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    health_check_protocol = "HTTPS"
  }

  assert {
    condition     = var.health_check_protocol == "HTTPS"
    error_message = "Health check protocol should be 'HTTPS'"
  }
}

# Test 12: Invalid health check protocol should fail
run "invalid_health_check_protocol" {
  command = plan

  variables {
    project_name          = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    health_check_protocol = "TCP"
  }

  expect_failures = [
    var.health_check_protocol,
  ]
}

# Test 13: Port number validation
run "valid_port_numbers" {
  command = plan

  variables {
    project_name                     = "test"
    environment                      = "dev"
    vpc_id                           = "vpc-12345678"
    subnet_ids                       = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn              = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    target_group_port                = 8080
    health_check_timeout             = 29
    health_check_interval            = 30
    health_check_healthy_threshold   = 10
    health_check_unhealthy_threshold = 10
  }

  assert {
    condition     = var.target_group_port == 8080
    error_message = "Target group port should be 8080"
  }

  assert {
    condition     = var.health_check_timeout < var.health_check_interval
    error_message = "Health check timeout should be less than interval"
  }

  assert {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Health check healthy threshold should be between 2 and 10"
  }

  assert {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Health check unhealthy threshold should be between 2 and 10"
  }
}

# Test 14: Required SSL certificate ARN
run "required_ssl_certificate_arn" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.ssl_certificate_arn != ""
    error_message = "SSL certificate ARN should not be empty"
  }

  assert {
    condition     = can(regex("^arn:aws:acm:", var.ssl_certificate_arn))
    error_message = "SSL certificate ARN should be a valid ACM certificate ARN"
  }
}

# Test 15: Multiple subnets for high availability
run "multiple_subnets_for_ha" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]
    ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB should have at least 2 subnets for high availability"
  }

  assert {
    condition     = contains(var.subnet_ids, "subnet-12345678")
    error_message = "Should contain first subnet ID"
  }

  assert {
    condition     = contains(var.subnet_ids, "subnet-87654321")
    error_message = "Should contain second subnet ID"
  }

  assert {
    condition     = contains(var.subnet_ids, "subnet-11111111")
    error_message = "Should contain third subnet ID"
  }
}
