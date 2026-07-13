###############################################################################
# Shared variable declarations for all environments.
#
# This file is the single source of truth. Each environment directory
# (dev, prod, ...) symlinks to it:
#
#   environments/dev/variables.tf  -> ../shared/variables.tf
#   environments/prod/variables.tf -> ../shared/variables.tf
#
# Per-environment VALUES live in each environment's terraform.tfvars.
# Variables that differ per environment intentionally have no default so
# that terraform.tfvars remains the source of truth.
#
# EXCEPTION: `environment` defaults to null and is auto-derived from the
# environment directory name by a locals block in each environment's main.tf
# (environments/dev -> "dev", environments/prod -> "prod"). Set it explicitly
# only to override that behavior.
###############################################################################

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
  description = "Environment name (e.g. dev, prod). Optional: when left null it is auto-derived from the environment directory name (see locals in each environment's main.tf). Set here or in terraform.tfvars only to override."
  type        = string
  default     = null
}

variable "app_version" {
  description = "Application version (injected by CI, e.g. git sha or tag)."
  type        = string
  default     = "0.0.0"
}

variable "lambda_memory_mb" {
  description = "Lambda memory size. Set per environment in terraform.tfvars."
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days. Set per environment in terraform.tfvars."
  type        = number
}
