output "state_bucket" {
  description = "Name of the S3 state bucket. Set this as the bucket in environments/*/backend.tf."
  value       = aws_s3_bucket.state.id
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions. Put this in GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}
