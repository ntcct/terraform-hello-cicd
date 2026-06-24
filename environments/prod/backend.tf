###############################################################################
# Remote state backend (partial configuration).
# Values supplied at `terraform init` via backend.hcl.
###############################################################################
terraform {
  backend "s3" {}
}
