# Integration tests for ALB Module
# Tests with real AWS resources (requires valid credentials)

# ==================================================
# SETUP INSTRUCTIONS
# ==================================================
# Before running these integration tests, you MUST provide environment-specific values
# for vpc_id, subnet_ids, and ssl_certificate_arn. You can do this in two ways:
#
# Option 1: Environment variables
#   export TF_VAR_vpc_id="vpc-your-actual-vpc-id"
#   export TF_VAR_subnet_ids='["subnet-id1", "subnet-id2"]'
#   export TF_VAR_ssl_certificate_arn="arn:aws:acm:region:account:certificate/cert-id"
#
# Option 2: Create terraform.tfvars file (copy from terraform.tfvars.example)
#   vpc_id = "vpc-your-actual-vpc-id"
#   subnet_ids = ["subnet-id1", "subnet-id2"]
#   ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
#
# ==================================================

# Variables for test environment configuration
# These MUST be set via environment variables (TF_VAR_vpc_id, TF_VAR_subnet_ids, etc.)
# or through terraform.tfvars files to avoid environment-specific conflicts
variable "vpc_id" {
  description = "VPC ID for testing - must be provided via environment variable or tfvars file"
  type        = string
  default     = ""

  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "VPC ID must not be empty. Please provide a valid VPC ID via environment variable TF_VAR_vpc_id or terraform.tfvars file."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for testing - must be provided via environment variable or tfvars file"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "Subnet IDs must not be empty. Please provide at least one subnet ID via environment variable TF_VAR_subnet_ids or terraform.tfvars file."
  }
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for testing"
  type        = string
  default     = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

# Test 1: Basic ALB integration with real AWS resources
run "basic_alb_integration" {
  command = apply

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    common_tags = {
      Project     = "test"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
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
}

run "basic_alb_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "test"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    common_tags = {
      Project     = "test"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 2: ALB with complex configuration
run "complex_alb_integration" {
  command = apply

  variables {
    project_name        = "myapp"
    environment         = "prd"
    app                 = "api"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # ALB configuration
    internal                         = false
    enable_deletion_protection       = true
    idle_timeout                     = 300
    enable_cross_zone_load_balancing = true
    enable_http2                     = true
    ip_address_type                  = "dualstack"

    # Target group configuration
    target_group_port     = 8080
    target_group_protocol = "HTTP"
    target_type           = "ip"

    # Health check configuration
    health_check_enabled             = true
    health_check_path                = "/health"
    health_check_port                = "8080"
    health_check_protocol            = "HTTP"
    health_check_healthy_threshold   = 3
    health_check_unhealthy_threshold = 5
    health_check_timeout             = 10
    health_check_interval            = 15
    health_check_matcher             = "200,201"

    # SSL configuration
    ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

    # Access logs
    enable_access_logs = true
    access_logs_bucket = "myapp-alb-logs"
    access_logs_prefix = "prd-api"

    common_tags = {
      Project     = "myapp"
      Environment = "prd"
      Application = "api"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = aws_lb.main.name == "myapp-prd-api-alb"
    error_message = "ALB name should be 'myapp-prd-api-alb'"
  }

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "ALB should be internet-facing"
  }

  assert {
    condition     = aws_lb.main.enable_deletion_protection == true
    error_message = "Deletion protection should be enabled"
  }

  assert {
    condition     = aws_lb.main.idle_timeout == 300
    error_message = "Idle timeout should be 300 seconds"
  }

  assert {
    condition     = aws_lb.main.ip_address_type == "dualstack"
    error_message = "IP address type should be 'dualstack'"
  }

  assert {
    condition     = aws_lb_target_group.main.name == "myapp-prd-api-tg"
    error_message = "Target group name should be 'myapp-prd-api-tg'"
  }

  assert {
    condition     = aws_lb_target_group.main.port == 8080
    error_message = "Target group port should be 8080"
  }

  assert {
    condition     = aws_lb_target_group.main.target_type == "ip"
    error_message = "Target type should be 'ip'"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].path == "/health"
    error_message = "Health check path should be '/health'"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].port == "8080"
    error_message = "Health check port should be 8080"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].healthy_threshold == 3
    error_message = "Health check healthy threshold should be 3"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].unhealthy_threshold == 5
    error_message = "Health check unhealthy threshold should be 5"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].timeout == 10
    error_message = "Health check timeout should be 10 seconds"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].interval == 15
    error_message = "Health check interval should be 15 seconds"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].matcher == "200,201"
    error_message = "Health check matcher should be '200,201'"
  }

  assert {
    condition     = aws_lb_listener.https.ssl_policy == "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
    error_message = "SSL policy should be 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06'"
  }

  assert {
    condition     = aws_lb.main.access_logs[0].enabled == true
    error_message = "Access logs should be enabled"
  }

  assert {
    condition     = aws_lb.main.access_logs[0].bucket == "myapp-alb-logs"
    error_message = "Access logs bucket should be 'myapp-alb-logs'"
  }

  assert {
    condition     = aws_lb.main.access_logs[0].prefix == "prd-api"
    error_message = "Access logs prefix should be 'prd-api'"
  }
}

run "complex_alb_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "myapp"
    environment         = "prd"
    app                 = "api"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # ALB configuration
    internal                         = false
    enable_deletion_protection       = true
    idle_timeout                     = 300
    enable_cross_zone_load_balancing = true
    enable_http2                     = true
    ip_address_type                  = "dualstack"

    # Target group configuration
    target_group_port     = 8080
    target_group_protocol = "HTTP"
    target_type           = "ip"

    # Health check configuration
    health_check_enabled             = true
    health_check_path                = "/health"
    health_check_port                = "8080"
    health_check_protocol            = "HTTP"
    health_check_healthy_threshold   = 3
    health_check_unhealthy_threshold = 5
    health_check_timeout             = 10
    health_check_interval            = 15
    health_check_matcher             = "200,201"

    # SSL configuration
    ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

    # Access logs
    enable_access_logs = true
    access_logs_bucket = "myapp-alb-logs"
    access_logs_prefix = "prd-api"

    common_tags = {
      Project     = "myapp"
      Environment = "prd"
      Application = "api"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 3: Internal ALB integration
run "internal_alb_integration" {
  command = apply

  variables {
    project_name        = "internal"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    internal            = true
    common_tags = {
      Project     = "internal"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = aws_lb.main.name == "internal-dev-alb"
    error_message = "ALB name should be 'internal-dev-alb'"
  }

  assert {
    condition     = aws_lb.main.internal == true
    error_message = "ALB should be internal"
  }

  assert {
    condition     = aws_security_group.alb.name == "internal-dev-alb-sg"
    error_message = "Security group name should be 'internal-dev-alb-sg'"
  }

  assert {
    condition     = aws_lb_target_group.main.name == "internal-dev-tg"
    error_message = "Target group name should be 'internal-dev-tg'"
  }
}

run "internal_alb_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "internal"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    internal            = true
    common_tags = {
      Project     = "internal"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 4: ALB with HTTPS target group
run "https_target_group_integration" {
  command = apply

  variables {
    project_name        = "secure"
    environment         = "prd"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # HTTPS target group
    target_group_port     = 443
    target_group_protocol = "HTTPS"
    health_check_protocol = "HTTPS"
    health_check_port     = "443"

    common_tags = {
      Project     = "secure"
      Environment = "prd"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = aws_lb_target_group.main.port == 443
    error_message = "Target group port should be 443"
  }

  assert {
    condition     = aws_lb_target_group.main.protocol == "HTTPS"
    error_message = "Target group protocol should be 'HTTPS'"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].protocol == "HTTPS"
    error_message = "Health check protocol should be 'HTTPS'"
  }

  assert {
    condition     = aws_lb_target_group.main.health_check[0].port == "443"
    error_message = "Health check port should be 443"
  }
}

run "https_target_group_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "secure"
    environment         = "prd"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # HTTPS target group
    target_group_port     = 443
    target_group_protocol = "HTTPS"
    health_check_protocol = "HTTPS"
    health_check_port     = "443"

    common_tags = {
      Project     = "secure"
      Environment = "prd"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 5: ALB with Lambda target type
run "lambda_target_type_integration" {
  command = apply

  variables {
    project_name        = "lambda"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Lambda target type
    target_type = "lambda"

    common_tags = {
      Project     = "lambda"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = aws_lb_target_group.main.target_type == "lambda"
    error_message = "Target type should be 'lambda'"
  }
}

run "lambda_target_type_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "lambda"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Lambda target type
    target_type = "lambda"

    common_tags = {
      Project     = "lambda"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 6: ALB with custom names
run "custom_names_integration" {
  command = apply

  variables {
    project_name        = "custom"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Custom names
    alb_name          = "my-custom-alb"
    target_group_name = "my-custom-tg"

    common_tags = {
      Project     = "custom"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = aws_lb.main.name == "my-custom-alb"
    error_message = "ALB name should be 'my-custom-alb'"
  }

  assert {
    condition     = aws_lb_target_group.main.name == "my-custom-tg"
    error_message = "Target group name should be 'my-custom-tg'"
  }

  assert {
    condition     = aws_security_group.alb.name == "custom-dev-alb-sg"
    error_message = "Security group name should be 'custom-dev-alb-sg'"
  }
}

run "custom_names_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "custom"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Custom names
    alb_name          = "my-custom-alb"
    target_group_name = "my-custom-tg"

    common_tags = {
      Project     = "custom"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 7: ALB with additional security groups
run "additional_security_groups_integration" {
  command = apply

  variables {
    project_name        = "security"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Additional security groups
    additional_security_group_ids = length(var.additional_security_group_ids) > 0 ? var.additional_security_group_ids : []

    common_tags = {
      Project     = "security"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  assert {
    condition     = length(aws_lb.main.security_groups) == 3
    error_message = "ALB should have 3 security groups (1 default + 2 additional)"
  }

  assert {
    condition     = contains(aws_lb.main.security_groups, aws_security_group.alb.id)
    error_message = "ALB should contain the default security group"
  }

  assert {
    condition     = length(var.additional_security_group_ids) == 0 || alltrue([for sg_id in var.additional_security_group_ids : contains(aws_lb.main.security_groups, sg_id)])
    error_message = "ALB should contain all additional security groups"
  }
}

run "additional_security_groups_integration_cleanup" {
  command = destroy

  variables {
    project_name        = "security"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn

    # Additional security groups
    additional_security_group_ids = length(var.additional_security_group_ids) > 0 ? var.additional_security_group_ids : []

    common_tags = {
      Project     = "security"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}

# Test 8: Full outputs validation
run "full_outputs_validation" {
  command = apply

  variables {
    project_name        = "output"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    common_tags = {
      Project     = "output"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }

  # ALB outputs
  assert {
    condition     = output.alb_id == aws_lb.main.id
    error_message = "ALB ID output should match resource ID"
  }

  assert {
    condition     = output.alb_arn == aws_lb.main.arn
    error_message = "ALB ARN output should match resource ARN"
  }

  assert {
    condition     = output.alb_name == aws_lb.main.name
    error_message = "ALB name output should match resource name"
  }

  assert {
    condition     = output.alb_dns_name == aws_lb.main.dns_name
    error_message = "ALB DNS name output should match resource DNS name"
  }

  assert {
    condition     = output.alb_zone_id == aws_lb.main.zone_id
    error_message = "ALB zone ID output should match resource zone ID"
  }

  assert {
    condition     = output.alb_hosted_zone_id == aws_lb.main.zone_id
    error_message = "ALB hosted zone ID output should match resource zone ID"
  }

  # Target group outputs
  assert {
    condition     = output.target_group_id == aws_lb_target_group.main.id
    error_message = "Target group ID output should match resource ID"
  }

  assert {
    condition     = output.target_group_arn == aws_lb_target_group.main.arn
    error_message = "Target group ARN output should match resource ARN"
  }

  assert {
    condition     = output.target_group_name == aws_lb_target_group.main.name
    error_message = "Target group name output should match resource name"
  }

  # Listener outputs
  assert {
    condition     = output.http_listener_id == aws_lb_listener.http.id
    error_message = "HTTP listener ID output should match resource ID"
  }

  assert {
    condition     = output.http_listener_arn == aws_lb_listener.http.arn
    error_message = "HTTP listener ARN output should match resource ARN"
  }

  assert {
    condition     = output.https_listener_id == aws_lb_listener.https.id
    error_message = "HTTPS listener ID output should match resource ID"
  }

  assert {
    condition     = output.https_listener_arn == aws_lb_listener.https.arn
    error_message = "HTTPS listener ARN output should match resource ARN"
  }

  # Security group outputs
  assert {
    condition     = output.security_group_id == aws_security_group.alb.id
    error_message = "Security group ID output should match resource ID"
  }

  assert {
    condition     = output.security_group_name == aws_security_group.alb.name
    error_message = "Security group name output should match resource name"
  }

  # URL outputs
  assert {
    condition     = output.load_balancer_url == "https://${aws_lb.main.dns_name}"
    error_message = "Load balancer URL should be HTTPS URL"
  }

  assert {
    condition     = output.load_balancer_http_url == "http://${aws_lb.main.dns_name}"
    error_message = "Load balancer HTTP URL should be HTTP URL"
  }

  assert {
    condition     = output.load_balancer_endpoint == aws_lb.main.dns_name
    error_message = "Load balancer endpoint should be DNS name only"
  }

  # Backward compatibility outputs
  assert {
    condition     = output.listener_id == aws_lb_listener.https.id
    error_message = "Listener ID (backward compatibility) should match HTTPS listener ID"
  }

  assert {
    condition     = output.listener_arn == aws_lb_listener.https.arn
    error_message = "Listener ARN (backward compatibility) should match HTTPS listener ARN"
  }
}

run "full_outputs_validation_cleanup" {
  command = destroy

  variables {
    project_name        = "output"
    environment         = "dev"
    vpc_id              = var.vpc_id
    subnet_ids          = var.subnet_ids
    ssl_certificate_arn = var.ssl_certificate_arn
    common_tags = {
      Project     = "output"
      Environment = "dev"
      ManagedBy   = "terraform"
      TestType    = "integration"
    }
  }
}
