###############################################################################
# Bootstrap (run ONCE, uses LOCAL state).
#
# Creates the shared prerequisites that the environments depend on:
#   - S3 bucket for remote state (versioned + encrypted + public access blocked)
#     (state locking is handled natively by the S3 backend, no DynamoDB needed)
#   - GitHub OIDC identity provider + IAM role assumable by GitHub Actions
#
# After applying this, copy the outputs into:
#   - environments/*/backend.tf    (bucket field)
#   - GitHub repo secret (AWS_ROLE_ARN)
###############################################################################

terraform {
  required_version = ">= 1.5.0"

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
      Project   = "terraform-hello-cicd"
      Component = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Use the first 6 digits of the account ID as a short, stable suffix.
  state_bucket_name = "${var.state_bucket_prefix}-${substr(data.aws_caller_identity.current.account_id, 0, 6)}"
}

# ---------------------------------------------------------------------------
# Remote state bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  # Protect remote state: refuse to delete the bucket while it still contains
  # objects (the dev/prod state files + lock files). With force_destroy = false,
  # `terraform destroy`/replace will FAIL rather than silently wipe all state.
  # To intentionally tear down, empty the bucket first (after backing up state).
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# State locking is handled natively by the S3 backend (use_lockfile = true),
# available since Terraform 1.10. No DynamoDB table is required; the lock file
# lives in the same bucket and relies on S3 conditional writes.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# GitHub Actions OIDC provider + role (no long-lived AWS keys in CI)
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to your repository. Format: repo:OWNER/REPO:*
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# Permissions the pipeline needs. Scoped to the services this project uses.
# Tighten further for real production use.
data "aws_iam_policy_document" "github_permissions" {
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    # PutObject/GetObject/DeleteObject also cover the native S3 lock file.
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
  }

  statement {
    sid    = "AppInfra"
    effect = "Allow"
    actions = [
      "lambda:*",
      "apigateway:*",
      "logs:*",
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PassRole",
      "iam:TagRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:GetPolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "terraform-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_permissions.json
}
