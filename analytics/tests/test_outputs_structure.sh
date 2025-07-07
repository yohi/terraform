#!/bin/bash

# Test Terraform outputs structure
# This script validates the structure of Terraform outputs

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

test_outputs_structure() {
    local outputs_file="../athena/terraform/outputs.tf"

    print_status "$BLUE" "🔍 Testing outputs.tf structure..."

    # Check if file exists
    if [ ! -f "$outputs_file" ]; then
        print_status "$RED" "❌ outputs.tf not found"
        return 1
    fi

    local exit_code=0

    # Check for required output blocks
    local required_outputs=(
        "aws_account_id"
        "project"
        "environment"
        "app"
        "athena_database_name"
        "athena_workgroup_name"
        "logs_bucket_name"
        "athena_console_url"
        "glue_database_name"
        "s3_bucket_name"
    )

    print_status "$BLUE" "  Checking required outputs..."

    for output in "${required_outputs[@]}"; do
        if grep -q "^output \"$output\"" "$outputs_file"; then
            print_status "$GREEN" "    ✅ Found output: $output"
        else
            print_status "$RED" "    ❌ Missing output: $output"
            exit_code=1
        fi
    done

    # Check output syntax
    print_status "$BLUE" "  Checking output syntax..."

    # Create a temporary directory for test
    local temp_dir
    temp_dir=$(mktemp -d)

    # Copy outputs.tf and create minimal main.tf
    cp "$outputs_file" "$temp_dir/"

    # Create minimal main.tf to support outputs
    cat > "$temp_dir/main.tf" << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# Minimal resources to satisfy outputs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "project_name" {
  type = string
  default = "test"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "app" {
  type = string
  default = "web"
}

variable "logs_bucket_name" {
  type = string
  default = "test-bucket"
}

variable "logs_s3_prefix" {
  type = string
  default = "logs"
}

variable "log_types" {
  type = map(object({
    table_name_suffix = string
    description       = string
    schema = map(object({
      type        = string
      description = string
    }))
  }))
  default = {}
}

variable "enable_quicksight" {
  type = bool
  default = false
}

variable "aws_region" {
  type = string
  default = "ap-northeast-1"
}

locals {
  project_env = "${var.project_name}-${var.environment}"
  athena_database_name = "test_database"
  logs_bucket = var.logs_bucket_name
}

# Minimal resources to satisfy outputs
resource "aws_glue_catalog_database" "main" {
  name = local.athena_database_name
}

resource "aws_athena_workgroup" "main" {
  name = "${local.project_env}-workgroup"
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "${local.project_env}-glue-crawler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "quicksight_role" {
  count = var.enable_quicksight ? 1 : 0
  name  = "${local.project_env}-quicksight-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_athena_named_query" "all_tables_overview" {
  name      = "all_tables_overview"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name
  query     = "SELECT 1"
}

resource "aws_athena_named_query" "current_day_all_data" {
  name      = "current_day_all_data"
  database  = local.athena_database_name
  workgroup = aws_athena_workgroup.main.name
  query     = "SELECT 1"
}

resource "aws_iam_role" "athena_workgroup_user_role" {
  name = "${local.project_env}-athena-user-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "athena_admin_policy" {
  name = "${local.project_env}-athena-admin-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "athena:*"
        Resource = "*"
      }
    ]
  })
}
EOF

    cd "$temp_dir"

    # Initialize and validate
    if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
        print_status "$GREEN" "    ✅ Outputs syntax is valid"
    else
        print_status "$RED" "    ❌ Outputs syntax is invalid"
        exit_code=1
    fi

    # Check for descriptions
    print_status "$BLUE" "  Checking output descriptions..."

    local outputs_without_desc=0
    while IFS= read -r line; do
        if [[ $line =~ ^output\ \"([^\"]+)\" ]]; then
            local output_name="${BASH_REMATCH[1]}"
            if ! grep -A 5 "^output \"$output_name\"" "$outputs_file" | grep -q "description"; then
                print_status "$YELLOW" "    ⚠️  Output '$output_name' missing description"
                ((outputs_without_desc++))
            fi
        fi
    done < <(grep "^output " "$outputs_file")

    if [ $outputs_without_desc -eq 0 ]; then
        print_status "$GREEN" "    ✅ All outputs have descriptions"
    else
        print_status "$YELLOW" "    ⚠️  $outputs_without_desc outputs missing descriptions"
    fi

    # Count total outputs
    local total_outputs
    total_outputs=$(grep -c "^output " "$outputs_file")
    print_status "$BLUE" "  📊 Total outputs: $total_outputs"

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    if [ $exit_code -eq 0 ]; then
        print_status "$GREEN" "✅ Outputs structure is valid"
    else
        print_status "$RED" "❌ Outputs structure has issues"
    fi

    return $exit_code
}

# Execute test
test_outputs_structure
