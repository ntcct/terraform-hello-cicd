variable "app_name" {
  description = "Base name of the application. Used to build resource names."
  type        = string
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
}

variable "lambda_timeout_seconds" {
  description = "Lambda execution timeout, in seconds."
  type        = number
  default     = 10
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
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
