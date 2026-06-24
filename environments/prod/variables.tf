variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application base name."
  type        = string
  default     = "hello-app"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "app_version" {
  description = "Application version (injected by CI, e.g. git tag)."
  type        = string
  default     = "0.0.0"
}

variable "lambda_memory_mb" {
  description = "Lambda memory size."
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
