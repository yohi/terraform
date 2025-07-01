# Required variables (no defaults) - order determines input sequence
variable "project" {
  description = "Project name (e.g., rcs, myapp)"
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "Project name must not be empty."
  }
}

variable "env" {
  description = "Environment name (e.g., prd, stg, dev)"
  type        = string
  validation {
    condition     = length(var.env) > 0
    error_message = "Environment name must not be empty."
  }
}

variable "logs_s3_prefix" {
  description = "S3 prefix where logs are stored (without log type suffix). Example: 'firelens/firelens/fluent-bit-logs', 'app-logs/production', 'logs/containers'"
  type        = string
  validation {
    condition     = length(var.logs_s3_prefix) > 0
    error_message = "S3 logs prefix must not be empty. Please specify the path to your log files (e.g., 'firelens/firelens/fluent-bit-logs')."
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

variable "logs_bucket_name" {
  description = "S3 bucket name where Firelens logs are stored"
  type        = string
  default     = ""
}

variable "athena_results_bucket_name" {
  description = "S3 bucket name for Athena query results"
  type        = string
  default     = ""
}

variable "athena_database_name" {
  description = "Athena database name"
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
      description       = "Django web application logs"
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
      description       = "Nginx web server logs"
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
      description       = "Error logs"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Local values for computed names
locals {
  project_env                = "${var.project}-${var.env}"
  logs_bucket_name           = var.logs_bucket_name != "" ? var.logs_bucket_name : "${local.project_env}-logs-data"
  athena_results_bucket_name = var.athena_results_bucket_name != "" ? var.athena_results_bucket_name : "${local.project_env}-athena-results"
  athena_database_name       = var.athena_database_name != "" ? var.athena_database_name : "${var.project}_${var.env}_logs"

  default_tags = {
    Environment = var.env
    Project     = var.project
    Component   = "analytics"
  }

  tags = merge(local.default_tags, var.tags)
}
