###############################################################################
# Remote state backend (partial configuration).
#
# The concrete values (bucket, key, region, lock file) are provided at
# `terraform init` time via backend.hcl, keeping this file environment-neutral
# and free of hardcoded account-specific values.
###############################################################################
terraform {
  backend "s3" {}
}
