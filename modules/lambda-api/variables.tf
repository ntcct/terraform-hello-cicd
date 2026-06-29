variable "app_name" {
  description = "Base name of the application. Used to build resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.app_name))
    error_message = "app_name must be 1-40 characters, alphanumeric and hyphens only."
  }
}

variable "environment" {
  description = "Environment name (e.g. dev, prod). Used for naming and tags."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "lambda_source_dir" {
  description = "Path to the directory containing the Lambda source code."
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"

  validation {
    condition = contains(
      [
        "python3.10", "python3.11", "python3.12", "python3.13",
      ],
      var.lambda_runtime
    )
    error_message = "lambda_runtime must be a currently supported runtime (update the allowlist as AWS adds/deprecates runtimes)."
  }
}

variable "lambda_handler" {
  description = "Lambda handler entrypoint (file.function)."
  type        = string
  default     = "handler.handler"
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the Lambda function, in MB."
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_mb >= 128 && var.lambda_memory_mb <= 10240
    error_message = "lambda_memory_mb must be between 128 and 10240."
  }
}

variable "lambda_timeout_seconds" {
  description = "Lambda execution timeout, in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout_seconds >= 1 && var.lambda_timeout_seconds <= 900
    error_message = "lambda_timeout_seconds must be between 1 and 900 (15 minutes)."
  }
}

variable "app_version" {
  description = "Application version string surfaced by the app (e.g. git sha or tag)."
  type        = string
  default     = "0.0.0"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a value supported by CloudWatch Logs (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
