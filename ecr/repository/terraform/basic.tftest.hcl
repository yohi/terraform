# ECR Repository Module - Basic Tests
# This test suite validates basic ECR repository creation and configuration

# Use mocks for unit testing
mock_provider "aws" {}

# Common variables for all tests
variables {
  project_name = "test-ecr"
  environment  = "dev"
  app          = "sample"

  common_tags = {
    Project     = "test-ecr"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "terraform"
  }
}

# Test basic ECR repository creation
run "basic_repository_creation" {
  command = plan

  variables {
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
  }

  assert {
    condition     = aws_ecr_repository.main != null
    error_message = "ECR repository should be created"
  }

  assert {
    condition     = can(regex("^test-ecr-dev-sample$", aws_ecr_repository.main.name))
    error_message = "ECR repository name does not match expected pattern"
  }

  assert {
    condition     = aws_ecr_repository.main.image_tag_mutability == "MUTABLE"
    error_message = "Image tag mutability should be MUTABLE"
  }

  assert {
    condition     = aws_ecr_repository.main.image_scanning_configuration[0].scan_on_push == true
    error_message = "Scan on push should be enabled"
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].encryption_type == "AES256"
    error_message = "Encryption type should be AES256"
  }
}

# Test with custom repository name
run "custom_repository_name" {
  command = plan

  variables {
    repository_name = "custom-repo"
  }

  assert {
    condition     = aws_ecr_repository.main.name == "custom-repo"
    error_message = "Custom repository name should be used when specified"
  }
}

# Test IMMUTABLE image tag mutability
run "immutable_tags" {
  command = plan

  variables {
    image_tag_mutability = "IMMUTABLE"
  }

  assert {
    condition     = aws_ecr_repository.main.image_tag_mutability == "IMMUTABLE"
    error_message = "Image tag mutability should be IMMUTABLE"
  }
}

# Test KMS encryption
run "kms_encryption" {
  command = plan

  variables {
    encryption_type = "KMS"
    kms_key_id      = "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].encryption_type == "KMS"
    error_message = "Encryption type should be KMS"
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].kms_key == "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "KMS key should be set when encryption_type is KMS"
  }
}

# Test lifecycle policy
run "lifecycle_policy_enabled" {
  command = plan

  variables {
    enable_lifecycle_policy    = true
    untagged_image_count_limit = 5
    tagged_image_count_limit   = 10
    image_age_limit_days       = 30
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.main != null
    error_message = "Lifecycle policy should be created when enabled"
  }
}

# Test lifecycle policy disabled
run "lifecycle_policy_disabled" {
  command = plan

  variables {
    enable_lifecycle_policy = false
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.main == null
    error_message = "Lifecycle policy should not be created when disabled"
  }
}

# Test repository policy
run "repository_policy_enabled" {
  command = plan

  variables {
    enable_repository_policy = true
    allowed_principals       = ["123456789012"]
    allowed_actions          = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
  }

  assert {
    condition     = aws_ecr_repository_policy.main != null
    error_message = "Repository policy should be created when enabled"
  }
}

# Test outputs
run "verify_outputs" {
  command = apply

  assert {
    condition     = output.repository_url != null
    error_message = "repository_url output should be available"
  }

  assert {
    condition     = output.repository_arn != null
    error_message = "repository_arn output should be available"
  }

  assert {
    condition     = output.repository_name != null
    error_message = "repository_name output should be available"
  }

  assert {
    condition     = output.registry_id != null
    error_message = "registry_id output should be available"
  }

  assert {
    condition     = output.aws_account_id != null
    error_message = "aws_account_id output should be available"
  }

  assert {
    condition     = output.aws_region != null
    error_message = "aws_region output should be available"
  }
}

# Test tags
run "verify_tags" {
  command = plan

  assert {
    condition     = aws_ecr_repository.main.tags["Project"] == "test-ecr"
    error_message = "Project tag should be set correctly"
  }

  assert {
    condition     = aws_ecr_repository.main.tags["Environment"] == "dev"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = aws_ecr_repository.main.tags["Purpose"] == "testing"
    error_message = "Purpose tag should be set correctly"
  }

  assert {
    condition     = aws_ecr_repository.main.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag should be set correctly"
  }
}
