# dev environment state location.
# `bucket` is intentionally a placeholder: it is globally unique and created by
# the bootstrap step. CI overrides it via -backend-config="bucket=...".
bucket       = "REPLACE_ME-tfstate"
key          = "dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true # native S3 state locking (Terraform >= 1.10); no DynamoDB
