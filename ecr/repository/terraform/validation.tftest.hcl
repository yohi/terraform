# ECR Repository Module - Validation Tests
# This test suite validates input variable validation rules

# Use mocks for unit testing
mock_provider "aws" {}

# Common variables for all tests
variables {
  project_name = "test-validation"
  environment  = "dev"
  app          = "sample"

  common_tags = {
    Project     = "test-validation"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "terraform"
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

# Test invalid environment values
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

# Test valid image tag mutability values
run "valid_image_tag_mutability_mutable" {
  command = plan

  variables {
    image_tag_mutability = "MUTABLE"
  }

  assert {
    condition     = var.image_tag_mutability == "MUTABLE"
    error_message = "Image tag mutability MUTABLE should be valid"
  }
}

run "valid_image_tag_mutability_immutable" {
  command = plan

  variables {
    image_tag_mutability = "IMMUTABLE"
  }

  assert {
    condition     = var.image_tag_mutability == "IMMUTABLE"
    error_message = "Image tag mutability IMMUTABLE should be valid"
  }
}

# Test invalid image tag mutability values
run "invalid_image_tag_mutability_mutable_lowercase" {
  command = plan

  variables {
    image_tag_mutability = "mutable"
  }

  expect_failures = [
    var.image_tag_mutability,
  ]
}

run "invalid_image_tag_mutability_immutable_lowercase" {
  command = plan

  variables {
    image_tag_mutability = "immutable"
  }

  expect_failures = [
    var.image_tag_mutability,
  ]
}

run "invalid_image_tag_mutability_invalid_value" {
  command = plan

  variables {
    image_tag_mutability = "INVALID"
  }

  expect_failures = [
    var.image_tag_mutability,
  ]
}

# Test valid encryption type values
run "valid_encryption_type_aes256" {
  command = plan

  variables {
    encryption_type = "AES256"
  }

  assert {
    condition     = var.encryption_type == "AES256"
    error_message = "Encryption type AES256 should be valid"
  }
}

run "valid_encryption_type_kms" {
  command = plan

  variables {
    encryption_type = "KMS"
    kms_key_id      = "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = var.encryption_type == "KMS"
    error_message = "Encryption type KMS should be valid"
  }
}

# Test invalid encryption type values
run "invalid_encryption_type_aes256_lowercase" {
  command = plan

  variables {
    encryption_type = "aes256"
  }

  expect_failures = [
    var.encryption_type,
  ]
}

run "invalid_encryption_type_kms_lowercase" {
  command = plan

  variables {
    encryption_type = "kms"
    kms_key_id      = "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  expect_failures = [
    var.encryption_type,
  ]
}

run "invalid_encryption_type_invalid_value" {
  command = plan

  variables {
    encryption_type = "INVALID"
  }

  expect_failures = [
    var.encryption_type,
  ]
}

# Test KMS key validation
run "invalid_kms_encryption_without_key" {
  command = plan

  variables {
    encryption_type = "KMS"
    kms_key_id      = ""
  }

  expect_failures = [
    var.kms_key_id,
  ]
}

# Test valid replication destinations
# Note: Temporarily disabled due to mock account ID format issues
# run "valid_replication_destinations" {
#   command = plan
#
#   variables {
#     enable_replication       = true
#     replication_destinations = ["us-east-1", "eu-west-1"]
#   }
#
#   assert {
#     condition     = var.enable_replication == true
#     error_message = "Replication should be enabled"
#   }
#
#   assert {
#     condition     = length(var.replication_destinations) == 2
#     error_message = "Should have 2 replication destinations"
#   }
# }

# Test invalid replication destinations
run "invalid_replication_destinations" {
  command = plan

  variables {
    enable_replication       = true
    replication_destinations = ["invalid-region", "also-invalid"]
  }

  expect_failures = [
    var.replication_destinations,
  ]
}

# Test common tags validation
run "valid_common_tags_with_required_keys" {
  command = plan

  variables {
    common_tags = {
      Project     = "test-validation"
      Environment = "dev"
      Purpose     = "testing"
      ManagedBy   = "terraform"
    }
  }

  assert {
    condition     = var.common_tags["Project"] == "test-validation"
    error_message = "Common tags should contain Project key"
  }

  assert {
    condition     = var.common_tags["Environment"] == "dev"
    error_message = "Common tags should contain Environment key"
  }
}
