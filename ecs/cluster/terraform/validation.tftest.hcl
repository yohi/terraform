# ECS Cluster Module - Validation Tests
# This test suite validates input variable validation rules

# Use mocks for unit testing
mock_provider "aws" {}

# Common variables for all tests
variables {
  project_name = "test-validation"
  app          = "webapp"

  common_tags = {
    Project     = "test-validation"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "Terraform"
  }
}

# Test valid environment values
run "valid_environment_dev" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment dev should be valid"
  }
}

run "valid_environment_stg" {
  command = plan

  variables {
    environment = "stg"
  }

  assert {
    condition     = var.environment == "stg"
    error_message = "Environment stg should be valid"
  }
}

run "valid_environment_prd" {
  command = plan

  variables {
    environment = "prd"
  }

  assert {
    condition     = var.environment == "prd"
    error_message = "Environment prd should be valid"
  }
}

run "valid_environment_rls" {
  command = plan

  variables {
    environment = "rls"
  }

  assert {
    condition     = var.environment == "rls"
    error_message = "Environment rls should be valid"
  }
}

# Test invalid environment values - these should cause plan to fail
run "invalid_environment_production" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [
    var.environment,
  ]
}

run "invalid_environment_staging" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [
    var.environment,
  ]
}

run "invalid_environment_test" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [
    var.environment,
  ]
}

# Test Service Connect namespace validation
# Note: Temporarily disabled due to Service Connect ARN validation issues
# run "valid_service_connect_namespace_simple" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "my-namespace"
#   }
#
#   assert {
#     condition     = var.service_connect_namespace == "my-namespace"
#     error_message = "Service Connect namespace 'my-namespace' should be valid"
#   }
# }

# Note: Service Connect tests temporarily disabled due to ARN validation issues
# run "valid_service_connect_namespace_with_hyphens" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "my-test-namespace-1"
#   }
#
#   assert {
#     condition     = var.service_connect_namespace == "my-test-namespace-1"
#     error_message = "Service Connect namespace with hyphens should be valid"
#   }
# }
#
# run "valid_service_connect_namespace_with_underscores" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "my_test_namespace_1"
#   }
#
#   assert {
#     condition     = var.service_connect_namespace == "my_test_namespace_1"
#     error_message = "Service Connect namespace with underscores should be valid"
#   }
# }
#
# run "invalid_service_connect_namespace_starting_with_hyphen" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "-invalid-namespace"
#   }
#
#   expect_failures = [
#     var.service_connect_namespace,
#   ]
# }
#
# run "invalid_service_connect_namespace_ending_with_hyphen" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "invalid-namespace-"
#   }
#
#   expect_failures = [
#     var.service_connect_namespace,
#   ]
# }
#
# run "invalid_service_connect_namespace_special_chars" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = "invalid@namespace"
#   }
#
#   expect_failures = [
#     var.service_connect_namespace,
#   ]
# }
#
# # Test Service Connect configuration validation
# run "service_connect_enabled_without_namespace" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = true
#     service_connect_namespace = ""
#   }
#
#   expect_failures = [
#     check.service_connect_namespace_validation,
#   ]
# }
#
# run "service_connect_disabled_with_empty_namespace" {
#   command = plan
#
#   variables {
#     environment               = "dev"
#     enable_service_connect    = false
#     service_connect_namespace = ""
#   }
#
#   # This should pass - no namespace required when Service Connect is disabled
#   assert {
#     condition     = var.enable_service_connect == false
#     error_message = "Service Connect should be disabled"
#   }
# }

# Test capacity providers validation
run "valid_capacity_providers_fargate_only" {
  command = plan

  variables {
    environment        = "dev"
    capacity_providers = ["FARGATE"]
  }

  assert {
    condition     = length(var.capacity_providers) == 1
    error_message = "Should have exactly one capacity provider"
  }

  assert {
    condition     = contains(var.capacity_providers, "FARGATE")
    error_message = "Should contain FARGATE capacity provider"
  }
}

run "valid_capacity_providers_fargate_spot" {
  command = plan

  variables {
    environment        = "dev"
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  }

  assert {
    condition     = length(var.capacity_providers) == 2
    error_message = "Should have exactly two capacity providers"
  }

  assert {
    condition     = contains(var.capacity_providers, "FARGATE")
    error_message = "Should contain FARGATE capacity provider"
  }

  assert {
    condition     = contains(var.capacity_providers, "FARGATE_SPOT")
    error_message = "Should contain FARGATE_SPOT capacity provider"
  }
}

# Test default capacity provider strategy validation
run "valid_default_capacity_provider_strategy_single" {
  command = plan

  variables {
    environment        = "dev"
    capacity_providers = ["FARGATE"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 0
      }
    ]
  }

  assert {
    condition     = length(var.default_capacity_provider_strategy) == 1
    error_message = "Should have exactly one capacity provider strategy"
  }

  assert {
    condition     = var.default_capacity_provider_strategy[0].capacity_provider == "FARGATE"
    error_message = "Capacity provider strategy should use FARGATE"
  }
}

run "valid_default_capacity_provider_strategy_multiple" {
  command = plan

  variables {
    environment        = "dev"
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 4
        base              = 0
      }
    ]
  }

  assert {
    condition     = length(var.default_capacity_provider_strategy) == 2
    error_message = "Should have exactly two capacity provider strategies"
  }

  assert {
    condition     = var.default_capacity_provider_strategy[0].weight == 1
    error_message = "First strategy weight should be 1"
  }

  assert {
    condition     = var.default_capacity_provider_strategy[1].weight == 4
    error_message = "Second strategy weight should be 4"
  }
}

# Test log retention validation
run "valid_log_retention_7_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 7
  }

  assert {
    condition     = var.log_retention_in_days == 7
    error_message = "Log retention should be 7 days"
  }
}

run "valid_log_retention_30_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 30
  }

  assert {
    condition     = var.log_retention_in_days == 30
    error_message = "Log retention should be 30 days"
  }
}

run "valid_log_retention_90_days" {
  command = plan

  variables {
    environment           = "dev"
    log_retention_in_days = 90
  }

  assert {
    condition     = var.log_retention_in_days == 90
    error_message = "Log retention should be 90 days"
  }
}

# Test AWS region validation
run "valid_aws_region_tokyo" {
  command = plan

  variables {
    environment = "dev"
    aws_region  = "ap-northeast-1"
  }

  assert {
    condition     = var.aws_region == "ap-northeast-1"
    error_message = "AWS region should be ap-northeast-1"
  }
}

run "valid_aws_region_virginia" {
  command = plan

  variables {
    environment = "dev"
    aws_region  = "us-east-1"
  }

  assert {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region should be us-east-1"
  }
}

# Test cluster name patterns
run "valid_cluster_name_custom" {
  command = plan

  variables {
    environment  = "dev"
    cluster_name = "production-cluster"
  }

  assert {
    condition     = var.cluster_name == "production-cluster"
    error_message = "Custom cluster name should be accepted"
  }
}

run "valid_cluster_name_empty" {
  command = plan

  variables {
    environment  = "dev"
    cluster_name = ""
  }

  assert {
    condition     = var.cluster_name == ""
    error_message = "Empty cluster name should be accepted for auto-generation"
  }
}
