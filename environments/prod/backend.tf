###############################################################################
# Remote state backend (prod).
# Fully specified here so `terraform init` needs no extra flags.
# Separate `key` => fully isolated state file from dev.
###############################################################################
terraform {
  backend "s3" {
    bucket       = "tf-hello-cicd-tfstate-584894"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 state locking (Terraform >= 1.10); no DynamoDB
  }
}
