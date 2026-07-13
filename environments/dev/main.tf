terraform {
  required_version = ">= 1.10.0" # use_lockfile (native S3 locking) requires >= 1.10

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Auto-derive the environment name from this directory's name
  # (e.g. environments/dev -> "dev"). Setting var.environment overrides it.
  environment = coalesce(var.environment, basename(abspath(path.root)))
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-hello-cicd"
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}

module "app" {
  # dev tracks the latest module code on the main branch.
  # Run `terraform init -upgrade` to pull newer commits.
  source = "git::https://github.com/ntcct/terraform-hello-cicd.git//modules/lambda-api?ref=main"

  # lambda_runtime    = "python3.14"
  app_name          = var.app_name
  environment       = local.environment
  lambda_source_dir = "${path.module}/../../app/src"
  app_version       = var.app_version

  lambda_memory_mb   = var.lambda_memory_mb
  log_retention_days = var.log_retention_days
}
