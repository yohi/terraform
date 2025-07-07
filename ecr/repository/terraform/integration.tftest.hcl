# ECR Repository Module - Integration Tests
# This test suite validates ECR repository creation with real AWS resources
# WARNING: This test creates actual AWS resources and may incur costs

# Provider configuration for integration tests
provider "aws" {
  region = "ap-northeast-1"
  # Uses actual AWS credentials from environment or AWS config
}

# Common variables for all tests
variables {
  project_name = "test-ecr-integration"
  environment  = "dev"
  app          = "integration-test"

  common_tags = {
    Project     = "test-ecr-integration"
    Environment = "dev"
    Purpose     = "integration-testing"
    ManagedBy   = "terraform"
    TestRun     = "true"
  }
}

# Integration test - Create actual ECR repository
run "create_ecr_repository" {
  command = apply

  variables {
    # Use timestamp in name to ensure uniqueness
    repository_name      = "integration-test-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"

    # Enable lifecycle policy
    enable_lifecycle_policy    = true
    untagged_image_count_limit = 3
    tagged_image_count_limit   = 5
    image_age_limit_days       = 7
  }

  assert {
    condition     = aws_ecr_repository.main != null
    error_message = "ECR repository should be created"
  }

  assert {
    condition     = output.repository_url != null
    error_message = "Repository URL should be available"
  }

  assert {
    condition     = output.repository_arn != null
    error_message = "Repository ARN should be available"
  }

  assert {
    condition     = output.aws_account_id != null
    error_message = "AWS account ID should be available"
  }

  assert {
    condition     = output.aws_region != null
    error_message = "AWS region should be available"
  }

  assert {
    condition     = can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/", output.repository_url))
    error_message = "Repository URL should match ECR URL format"
  }

  assert {
    condition     = can(regex("^arn:aws:ecr:[a-z0-9-]+:[0-9]{12}:repository/", output.repository_arn))
    error_message = "Repository ARN should match ECR ARN format"
  }
}

# Integration test - Create multiple repositories
run "create_multiple_repositories" {
  command = apply

  variables {
    repositories = [
      {
        name                 = "integration-web-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
        image_tag_mutability = "MUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      },
      {
        name                 = "integration-api-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
        encryption_type      = "AES256"
      }
    ]

    # Enable lifecycle policy
    enable_lifecycle_policy    = true
    untagged_image_count_limit = 3
    tagged_image_count_limit   = 5
    image_age_limit_days       = 7
  }

  assert {
    condition     = length(keys(aws_ecr_repository.main)) == 2
    error_message = "Should create exactly 2 ECR repositories"
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
}

# Integration test - Test lifecycle policy
run "test_lifecycle_policy" {
  command = apply

  variables {
    repository_name            = "integration-lifecycle-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    enable_lifecycle_policy    = true
    untagged_image_count_limit = 2
    tagged_image_count_limit   = 3
    image_age_limit_days       = 5
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.main != null
    error_message = "Lifecycle policy should be created"
  }

  assert {
    condition     = output.lifecycle_policy_enabled == true
    error_message = "Lifecycle policy should be enabled in outputs"
  }
}

# Integration test - Test repository policy
run "test_repository_policy" {
  command = apply

  variables {
    repository_name          = "integration-policy-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    enable_repository_policy = true
    allowed_principals       = [data.aws_caller_identity.current.account_id]
    allowed_actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }

  assert {
    condition     = aws_ecr_repository_policy.main != null
    error_message = "Repository policy should be created"
  }

  assert {
    condition     = output.repository_policy_enabled == true
    error_message = "Repository policy should be enabled in outputs"
  }
}

# Integration test - Test tags
run "test_tags_integration" {
  command = apply

  variables {
    repository_name = "integration-tags-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

    common_tags = {
      Project     = "test-ecr-integration"
      Environment = "dev"
      Purpose     = "integration-testing"
      ManagedBy   = "terraform"
      TestRun     = "true"
      Owner       = "integration-test"
    }
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["Project"] == "test-ecr-integration"
    error_message = "Project tag should be set correctly"
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["Environment"] == "dev"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["Purpose"] == "integration-testing"
    error_message = "Purpose tag should be set correctly"
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be set correctly"
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["TestRun"] == "true"
    error_message = "TestRun tag should be set correctly"
  }

  assert {
    condition     = values(aws_ecr_repository.main)[0].tags["Owner"] == "integration-test"
    error_message = "Owner tag should be set correctly"
  }
}

# Integration test - Test image URI format
run "test_image_uri_format" {
  command = apply

  variables {
    repository_name = "integration-uri-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  }

  assert {
    condition     = can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[a-zA-Z0-9-_]+:latest$", values(output.repository_image_uris)[0]))
    error_message = "Repository image URI should match expected format"
  }

  assert {
    condition     = length(output.repository_push_commands[keys(output.repository_push_commands)[0]]) == 4
    error_message = "Repository push commands should contain 4 commands"
  }

  assert {
    condition     = can(regex("^aws ecr get-login-password", output.repository_push_commands[keys(output.repository_push_commands)[0]][0]))
    error_message = "First push command should be AWS ECR login"
  }

  assert {
    condition     = can(regex("^docker build", output.repository_push_commands[keys(output.repository_push_commands)[0]][1]))
    error_message = "Second push command should be Docker build"
  }

  assert {
    condition     = can(regex("^docker tag", output.repository_push_commands[keys(output.repository_push_commands)[0]][2]))
    error_message = "Third push command should be Docker tag"
  }

  assert {
    condition     = can(regex("^docker push", output.repository_push_commands[keys(output.repository_push_commands)[0]][3]))
    error_message = "Fourth push command should be Docker push"
  }
}

# Integration test - Test resource cleanup
run "test_resource_cleanup" {
  command = apply

  variables {
    repository_name = "integration-cleanup-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  }

  # This run block is mainly to test that resources can be created and destroyed
  # The actual cleanup will happen when the test completes
  assert {
    condition     = aws_ecr_repository.main != null
    error_message = "ECR repository should be created for cleanup test"
  }
}
