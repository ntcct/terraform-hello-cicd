###############################################################################
# Remote state backend (dev).
# Fully specified here so `terraform init` needs no extra flags.
# NOTE: `bucket` is the account-specific S3 state bucket created by bootstrap.
###############################################################################
terraform {
  backend "s3" {
    bucket       = "tf-hello-cicd-tfstate-584894"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 state locking (Terraform >= 1.10); no DynamoDB
  }
}
