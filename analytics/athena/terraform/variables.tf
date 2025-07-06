# Required variables (no defaults) - order determines input sequence
variable "project_name" {
  description = "Project name (e.g., rcs, myapp)"
  type        = string
  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app" {
  description = "Application name for catalog (e.g., web, api, batch)"
  type        = string
  validation {
    condition     = length(var.app) > 0
    error_message = "Application name must not be empty."
  }
}

variable "logs_bucket_name" {
  description = "S3 bucket name where logs are stored (REQUIRED). This bucket will also be used for Athena query results. Example: 'rcs-stg-logs-data', 'my-app-logs'"
  type        = string
  validation {
    condition     = length(var.logs_bucket_name) > 0
    error_message = "S3 logs bucket name must not be empty. Please specify the bucket where your log files are stored."
  }
}

variable "logs_s3_prefix" {
  description = "S3 prefix within the bucket where logs are stored (without log type suffix). Example: 'firelens/firelens/fluent-bit-logs', 'app-logs/production', 'logs/containers'"
  type        = string
  validation {
    condition     = length(var.logs_s3_prefix) > 0
    error_message = "S3 logs prefix must not be empty. Please specify the path within the bucket to your log files (e.g., 'firelens/firelens/fluent-bit-logs')."
  }
  validation {
    condition     = !can(regex("/$", var.logs_s3_prefix))
    error_message = "S3 logs prefix should not end with '/'. The log type will be appended automatically."
  }
}

# Optional variables (with defaults)
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "create_ddl_queries" {
  description = "Whether to create DDL queries (CREATE TABLE, CREATE VIEW) in Athena saved queries. Set to false to avoid non-SELECT queries in Athena query editor."
  type        = bool
  default     = false
}

variable "athena_database_name" {
  description = "Athena database name (optional). If not specified, defaults to '{project}_{env}_{app}_logs' format for clear identification"
  type        = string
  default     = ""
}

variable "log_types" {
  description = "List of log types to create tables for"
  type = map(object({
    table_name_suffix = string
    description       = string
    schema = map(object({
      type        = string
      description = string
    }))
  }))
  default = {
    django_web = {
      table_name_suffix = "django_web"
      description       = "Django Webアプリケーションログ"
      schema = {
        date = {
          type        = "string"
          description = "Log timestamp"
        }
        source = {
          type        = "string"
          description = "Log source (stdout/stderr)"
        }
        log = {
          type        = "string"
          description = "Log message content"
        }
        container_id = {
          type        = "string"
          description = "Container ID"
        }
        container_name = {
          type        = "string"
          description = "Container name"
        }
        ec2_instance_id = {
          type        = "string"
          description = "EC2 instance ID"
        }
        ecs_cluster = {
          type        = "string"
          description = "ECS cluster name"
        }
        ecs_task_arn = {
          type        = "string"
          description = "ECS task ARN"
        }
        ecs_task_definition = {
          type        = "string"
          description = "ECS task definition"
        }
      }
    }
    nginx_web = {
      table_name_suffix = "nginx_web"
      description       = "Nginx Webサーバーログ"
      schema = {
        date = {
          type        = "string"
          description = "Log timestamp"
        }
        source = {
          type        = "string"
          description = "Log source (stdout/stderr)"
        }
        log = {
          type        = "string"
          description = "Log message content"
        }
        container_id = {
          type        = "string"
          description = "Container ID"
        }
        container_name = {
          type        = "string"
          description = "Container name"
        }
        ec2_instance_id = {
          type        = "string"
          description = "EC2 instance ID"
        }
        ecs_cluster = {
          type        = "string"
          description = "ECS cluster name"
        }
        ecs_task_arn = {
          type        = "string"
          description = "ECS task ARN"
        }
        ecs_task_definition = {
          type        = "string"
          description = "ECS task definition"
        }
      }
    }
    error = {
      table_name_suffix = "error"
      description       = "エラーログ"
      schema = {
        date = {
          type        = "string"
          description = "Log timestamp"
        }
        source = {
          type        = "string"
          description = "Log source (stdout/stderr)"
        }
        log = {
          type        = "string"
          description = "Log message content"
        }
        container_id = {
          type        = "string"
          description = "Container ID"
        }
        container_name = {
          type        = "string"
          description = "Container name"
        }
        ec2_instance_id = {
          type        = "string"
          description = "EC2 instance ID"
        }
        ecs_cluster = {
          type        = "string"
          description = "ECS cluster name"
        }
        ecs_task_arn = {
          type        = "string"
          description = "ECS task ARN"
        }
        ecs_task_definition = {
          type        = "string"
          description = "ECS task definition"
        }
      }
    }
  }
}

variable "owner_team" {
  description = "リソースの所有者チーム"
  type        = string
  default     = "analytics-team"
}

variable "owner_email" {
  description = "リソースの所有者チームのメールアドレス"
  type        = string
  default     = "analytics@example.com"
}

variable "cost_center" {
  description = "コストセンター"
  type        = string
  default     = "engineering"
}

variable "billing_code" {
  description = "請求コード"
  type        = string
  default     = ""
}

variable "data_classification" {
  description = "データ分類レベル (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification は 'public', 'internal', 'confidential', 'restricted' のいずれかである必要があります。"
  }
}

variable "backup_required" {
  description = "バックアップが必要かどうか"
  type        = bool
  default     = true
}

variable "monitoring_level" {
  description = "監視レベル (basic, enhanced)"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "enhanced"], var.monitoring_level)
    error_message = "monitoring_level は 'basic' または 'enhanced' である必要があります。"
  }
}

variable "schedule" {
  description = "運用スケジュール (24x7, business-hours)"
  type        = string
  default     = "24x7"
}

variable "retention_period" {
  description = "データ保持期間"
  type        = string
  default     = "7-years"
}

variable "tags" {
  description = "Tags to apply to resources（追加・上書き用）"
  type        = map(string)
  default     = {}
}

variable "auto_create_bucket" {
  description = "Automatically create S3 buckets without confirmation (useful for CI/CD)"
  type        = bool
  default     = false
}

variable "enable_quicksight" {
  description = "Enable QuickSight integration (creates IAM roles and policies for QuickSight access)"
  type        = bool
  default     = false
}

# Glue Crawler 自動実行設定
variable "enable_crawler_schedule" {
  description = "Enable automatic Glue Crawler execution schedule"
  type        = bool
  default     = true
}

variable "crawler_schedule_expression" {
  description = "Schedule expression for Glue Crawler execution (cron or rate expression)"
  type        = string
  default     = "cron(0 3 * * ? *)" # 毎日午前3時に実行

  validation {
    condition     = can(regex("^(rate|cron)\\(.*\\)$", var.crawler_schedule_expression))
    error_message = "crawler_schedule_expression must be a valid cron or rate expression (e.g., 'cron(0 3 * * ? *)' or 'rate(1 hour)')."
  }
}

variable "crawler_max_concurrent_runs" {
  description = "Maximum number of concurrent runs for Glue Crawler"
  type        = number
  default     = 1

  validation {
    condition     = var.crawler_max_concurrent_runs >= 1 && var.crawler_max_concurrent_runs <= 10
    error_message = "crawler_max_concurrent_runs must be between 1 and 10."
  }
}

# Local values are defined in main.tf to avoid duplication

# ==================================================
# Validation Variables
# ==================================================
# These variables are used for native Terraform validation instead of external bash scripts

variable "expected_aws_account_id" {
  description = "Expected AWS account ID for validation. If empty, account validation is skipped. This replaces the bash script validation for CI/CD environments."
  type        = string
  default     = ""
  validation {
    condition     = var.expected_aws_account_id == "" || can(regex("^[0-9]{12}$", var.expected_aws_account_id))
    error_message = "expected_aws_account_id must be empty or a valid 12-digit AWS account ID."
  }
}

variable "require_bucket_exists" {
  description = "Whether to require that the S3 bucket already exists (true) or allow Terraform to create it (false). Set to true in CI/CD environments to enforce pre-existing buckets."
  type        = bool
  default     = false
}

variable "skip_bucket_validation" {
  description = "Skip S3 bucket existence validation entirely. Useful for CI/CD environments where bucket validation should be handled externally."
  type        = bool
  default     = false
}
