terraform {
  required_version = ">= 1.10.0" # use_lockfile (native S3 locking) requires >= 1.10

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-hello-cicd"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "app" {
  source = "../../modules/lambda-api"

  app_name          = var.app_name
  environment       = var.environment
  lambda_source_dir = "${path.module}/../../app/src"
  app_version       = var.app_version

  lambda_memory_mb   = var.lambda_memory_mb
  log_retention_days = var.log_retention_days
}
