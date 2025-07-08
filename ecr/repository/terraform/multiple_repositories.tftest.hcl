# ECR Repository Module - Multiple Repositories Tests
# This test suite validates multiple ECR repository creation and configuration

# Use mocks for unit testing
mock_provider "aws" {}

# Common variables for all tests
variables {
  project_name = "test-multi-ecr"
  environment  = "dev"

  common_tags = {
    Project     = "test-multi-ecr"
    Environment = "dev"
    Purpose     = "testing"
    ManagedBy   = "terraform"
  }
}

# Test multiple repositories creation
run "multiple_repositories_creation" {
  command = plan

  variables {
    repositories = [
      {
        name                 = "web-app"
        image_tag_mutability = "MUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      },
      {
        name                 = "api-server"
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      },
      {
        name                 = "worker"
        image_tag_mutability = "MUTABLE"
        scan_on_push         = false
        encryption_type      = "KMS"
        kms_key_id           = "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    ]
  }

  assert {
    condition     = length(keys(aws_ecr_repository.main)) == 3
    error_message = "Expected exactly 3 ECR repositories to be created"
  }

  assert {
    condition     = contains(keys(aws_ecr_repository.main), "web-app")
    error_message = "web-app repository should be created"
  }

  assert {
    condition     = contains(keys(aws_ecr_repository.main), "api-server")
    error_message = "api-server repository should be created"
  }

  assert {
    condition     = contains(keys(aws_ecr_repository.main), "worker")
    error_message = "worker repository should be created"
  }
}

# Test different configurations per repository
run "different_configurations_per_repository" {
  command = plan

  variables {
    repositories = [
      {
        name                 = "web-app"
        image_tag_mutability = "MUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      },
      {
        name                 = "api-server"
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      }
    ]
  }

  assert {
    condition     = aws_ecr_repository.main["web-app"].image_tag_mutability == "MUTABLE"
    error_message = "web-app should have MUTABLE image tag mutability"
  }

  assert {
    condition     = aws_ecr_repository.main["api-server"].image_tag_mutability == "IMMUTABLE"
    error_message = "api-server should have IMMUTABLE image tag mutability"
  }

  assert {
    condition     = aws_ecr_repository.main["web-app"].image_scanning_configuration[0].scan_on_push == true
    error_message = "web-app should have scan on push enabled"
  }

  assert {
    condition     = aws_ecr_repository.main["api-server"].image_scanning_configuration[0].scan_on_push == true
    error_message = "api-server should have scan on push enabled"
  }
}

# Test repositories with KMS encryption
run "repositories_with_kms_encryption" {
  command = plan

  variables {
    repositories = [
      {
        name                 = "secure-app"
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
        encryption_type      = "KMS"
        kms_key_id           = "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    ]
  }

  assert {
    condition     = aws_ecr_repository.main["secure-app"].encryption_configuration[0].encryption_type == "KMS"
    error_message = "secure-app should use KMS encryption"
  }

  assert {
    condition     = aws_ecr_repository.main["secure-app"].encryption_configuration[0].kms_key == "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "secure-app should use specified KMS key"
  }
}

# Test repositories with optional parameters
run "repositories_with_optional_parameters" {
  command = plan

  variables {
    repositories = [
      {
        name = "minimal-app"
        # Using default values for optional parameters
      }
    ]
  }

  assert {
    condition     = aws_ecr_repository.main["minimal-app"].image_tag_mutability == "MUTABLE"
    error_message = "minimal-app should have default MUTABLE image tag mutability"
  }

  assert {
    condition     = aws_ecr_repository.main["minimal-app"].image_scanning_configuration[0].scan_on_push == true
    error_message = "minimal-app should have default scan on push enabled"
  }

  assert {
    condition     = aws_ecr_repository.main["minimal-app"].encryption_configuration[0].encryption_type == "AES256"
    error_message = "minimal-app should have default AES256 encryption"
  }
}

# Test repository naming
run "repository_naming" {
  command = plan

  variables {
    repositories = [
      {
        name = "my-app"
      }
    ]
  }

  assert {
    condition     = aws_ecr_repository.main["my-app"].name == "my-app"
    error_message = "Repository name should match the specified name"
  }
}

# Test outputs for multiple repositories
run "verify_multiple_repositories_outputs" {
  command = plan

  variables {
    repositories = [
      {
        name = "app-1"
      },
      {
        name = "app-2"
      }
    ]
  }

  assert {
    condition     = length(keys(output.repository_urls)) == 2
    error_message = "Should have 2 repository URLs"
  }

  assert {
    condition     = length(keys(output.repository_arns)) == 2
    error_message = "Should have 2 repository ARNs"
  }

  assert {
    condition     = length(keys(output.repository_names)) == 2
    error_message = "Should have 2 repository names"
  }

  assert {
    condition     = length(keys(output.registry_ids)) == 2
    error_message = "Should have 2 registry IDs"
  }

  assert {
    condition     = contains(keys(output.repository_urls), "app-1")
    error_message = "app-1 should be in repository_urls"
  }

  assert {
    condition     = contains(keys(output.repository_urls), "app-2")
    error_message = "app-2 should be in repository_urls"
  }
}

# Test that single repository outputs are null for multiple repositories
run "single_repository_outputs_null_for_multiple" {
  command = plan

  variables {
    repositories = [
      {
        name = "app-1"
      },
      {
        name = "app-2"
      }
    ]
  }

  assert {
    condition     = output.repository_url == null
    error_message = "repository_url should be null for multiple repositories"
  }

  assert {
    condition     = output.repository_arn == null
    error_message = "repository_arn should be null for multiple repositories"
  }

  assert {
    condition     = output.repository_name == null
    error_message = "repository_name should be null for multiple repositories"
  }

  assert {
    condition     = output.registry_id == null
    error_message = "registry_id should be null for multiple repositories"
  }
}

# Test tags for multiple repositories
run "verify_multiple_repositories_tags" {
  command = plan

  variables {
    repositories = [
      {
        name = "app-1"
      },
      {
        name = "app-2"
      }
    ]
  }

  assert {
    condition     = aws_ecr_repository.main["app-1"].tags["Project"] == "test-multi-ecr"
    error_message = "app-1 should have correct Project tag"
  }

  assert {
    condition     = aws_ecr_repository.main["app-2"].tags["Project"] == "test-multi-ecr"
    error_message = "app-2 should have correct Project tag"
  }

  assert {
    condition     = aws_ecr_repository.main["app-1"].tags["Environment"] == "dev"
    error_message = "app-1 should have correct Environment tag"
  }

  assert {
    condition     = aws_ecr_repository.main["app-2"].tags["Environment"] == "dev"
    error_message = "app-2 should have correct Environment tag"
  }
}

# Test image URI outputs for multiple repositories
run "verify_image_uri_outputs" {
  command = plan

  variables {
    repositories = [
      {
        name = "app-1"
      },
      {
        name = "app-2"
      }
    ]
  }

  assert {
    condition     = length(keys(output.repository_image_uris)) == 2
    error_message = "Should have 2 image URIs"
  }

  assert {
    condition     = length(keys(output.repository_push_commands)) == 2
    error_message = "Should have 2 push command sets"
  }

  assert {
    condition     = contains(keys(output.repository_image_uris), "app-1")
    error_message = "app-1 should be in repository_image_uris"
  }

  assert {
    condition     = contains(keys(output.repository_image_uris), "app-2")
    error_message = "app-2 should be in repository_image_uris"
  }
}
