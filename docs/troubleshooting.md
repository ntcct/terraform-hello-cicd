# Troubleshooting & FAQ

## Common issues

### `Error: Failed to get existing workspaces / NoSuchBucket`
The state bucket does not exist or `backend.hcl` / `TF_STATE_BUCKET` is wrong.
Re-check the `bootstrap` output `state_bucket` and ensure it matches both
`environments/*/backend.hcl` and the `TF_STATE_BUCKET` GitHub secret.

### `Error: error configuring S3 Backend: no valid credential sources`
Running locally without AWS credentials, or in CI the OIDC assume-role failed.
- Locally: `aws sts get-caller-identity` to confirm credentials.
- CI: confirm the workflow has `permissions: id-token: write` and the role trust
  policy `sub` condition matches `repo:OWNER/REPO:*`.

### `Error acquiring the state lock`
A previous run crashed and left a lock file in the S3 bucket (native locking,
`use_lockfile = true`). Confirm no apply is in progress, then:
```
terraform force-unlock <LOCK_ID>
```
Only do this when you are certain no other run is active. If `force-unlock`
cannot reach the lock, the stale lock object can be removed directly from the
state bucket (key `<env>/terraform.tfstate.tflock`).

### `ConflictException` / `ResourceConflict` on API Gateway or Lambda
Usually a name collision from a partially-applied previous run. Run
`terraform plan` to see drift; import or `terraform apply` again. Names are
`hello-app-<env>` and must be unique per account/region.

### `terraform fmt -check` fails in CI
Formatting drift. Run `terraform fmt -recursive` locally and commit.

### Lambda returns 500 / Internal Server Error
Check the function logs:
```
aws logs tail /aws/lambda/hello-app-dev --since 10m --follow
```
Verify the handler path matches `lambda_handler` (`handler.handler`).

### Prod deploy never runs after creating a release
- Ensure the Release was **published** (not draft).
- Ensure a reviewer approves the pending deployment in the Actions run
  (the `prod` environment gate).

### OIDC: `Not authorized to perform sts:AssumeRoleWithWebIdentity`
The role trust `sub` condition does not match the repo. Re-run bootstrap with the
correct `github_repo = "OWNER/REPO"`.

---

## FAQ

**Q: Why Lambda + API Gateway instead of EC2/ECS/S3?**
It is the simplest, lowest-cost way to host a Hello World web app while keeping a
clean separation between infrastructure and application code. The module
boundary makes it straightforward to swap implementations later.

**Q: How are environments kept isolated?**
Separate config directories, separate Terraform state keys, separate
uniquely-named AWS resources, and separate pipeline gates. Nothing is shared
except the state *bucket* and lock *table* (which use distinct keys per env).

**Q: How do I add a `staging` environment?**
Copy `environments/dev` to `environments/staging`, set `environment = "staging"`
and `key = "staging/terraform.tfstate"`, add a `staging` GitHub Environment, and
add it to the CI matrix / a deploy workflow. The module already validates
`staging` as an allowed value.

**Q: Does deploying the app require a separate pipeline?**
No. Application code changes are detected through the Lambda `source_code_hash`
and deployed by the same `terraform apply`. The `app_version` variable records
which build is live.

**Q: How do I roll back?**
Revert the offending commit and re-run the pipeline, or for prod re-publish a
previous release tag. Terraform will converge resources back to the prior state.

**Q: How much does this cost?**
With light traffic it stays within / near the AWS free tier (Lambda + HTTP API +
minimal logs + tiny state storage). For an authoritative estimate, use the
[AWS Pricing Calculator](https://calculator.aws/).

**Q: Can I run everything locally?**
Yes — see the "Local deployment" section in the root `README.md`. CI is the
intended path, but local runs share the same backend and module.

**Q: Where do I store secrets?**
GitHub Actions secrets (`AWS_ROLE_ARN`, `TF_STATE_BUCKET`). The solution uses
OIDC, so no long-lived AWS keys are stored anywhere.
