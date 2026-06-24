variable "aws_region" {
  description = "AWS region for bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket. Account ID is appended for global uniqueness."
  type        = string
  default     = "hello-cicd-tfstate"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI role, as OWNER/REPO."
  type        = string
}
