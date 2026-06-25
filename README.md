# terraform-hello-cicd

A complete, end-to-end Terraform + CI/CD reference solution. It deploys a simple
**"Hello World"** application to **AWS Lambda + API Gateway**, across two fully
isolated environments (**dev** and **prod**), driven entirely by a **Git-based
GitHub Actions** workflow.

---

## 1. Solution architecture

```
Developer ── Git ──▶ GitHub Actions (OIDC) ──▶ AWS
                          │
   PR ─────────────▶ terraform-ci    : fmt + validate + plan (dev & prod)
   merge to main ──▶ deploy-dev       : terraform apply  → DEV
   release (tag v*)▶ deploy-prod       : manual approval → terraform apply → PROD

AWS per environment:   API Gateway (HTTP) ─▶ Lambda (Hello World) ─▶ CloudWatch Logs
Shared:                S3 (remote state, versioned+encrypted, native lockfile)
```

The application is an AWS Lambda function fronted by an HTTP API Gateway. It
returns a JSON body containing the environment name, so a successful deployment
is visually verifiable per environment.

See [`docs/architecture.md`](docs/architecture.md) for the detailed diagram and
rationale.

## 2. Repository layout

```
.
├── app/src/handler.py          # The deployable application (Hello World)
├── modules/lambda-api/         # Reusable module: Lambda + API GW + IAM + logs
├── environments/
│   ├── dev/                    # dev root config (own state key + tfvars)
│   └── prod/                   # prod root config (own state key + tfvars)
├── bootstrap/                  # One-time: state bucket + OIDC role
├── .github/workflows/          # CI/CD pipelines
│   ├── terraform-ci.yml        # PR: fmt/validate/plan
│   ├── deploy-dev.yml          # push to main: apply dev
│   └── deploy-prod.yml         # release: apply prod (manual approval)
└── docs/                       # Architecture, CI/CD, troubleshooting, FAQ
```

## 3. Design decisions

| Decision | Choice | Why |
|---|---|---|
| Compute | Lambda + HTTP API Gateway | Cheapest/simplest serverless Hello World; clean infra/app split |
| Reuse | Single `lambda-api` module consumed by both environments | DRY; environments differ only by inputs |
| State | S3 backend with native lockfile (`use_lockfile`) | Durable, encrypted, versioned, lockable remote state with no extra services (Terraform >= 1.10) |
| Env isolation | Separate directory + separate state **key** per environment | No shared workspace; blast radius contained |
| CI auth | GitHub OIDC → IAM role | No long-lived AWS keys stored in GitHub |
| Backend config | Bucket hardcoded in `backend.tf` | Simple: `terraform init` needs no extra flags |
| App deploy | Lambda code hashed via `source_code_hash` | App changes redeploy through the same pipeline as infra |

## 4. Environment separation strategy

Each environment is **fully isolated**:

- **Configuration**: separate `environments/<env>/terraform.tfvars`.
- **State**: separate S3 key (`dev/terraform.tfstate` vs `prod/terraform.tfstate`).
- **Deployment target**: separate, uniquely-named AWS resources
  (`hello-app-dev`, `hello-app-prod`) including separate IAM roles and log groups.
- **Pipeline**: dev deploys automatically on merge; prod requires a release tag
  **and** manual approval via a protected GitHub Environment.

## 5. Prerequisites

- An AWS account + credentials with admin (for the one-time bootstrap only).
- Terraform >= 1.10 (required for native S3 state locking), AWS CLI v2.
- A GitHub repository for this code.

## 6. Deployment instructions

### Step 1 — Bootstrap (run once, locally)

Creates the state bucket and GitHub OIDC role.

```bash
cd bootstrap
terraform init
terraform apply -var="github_repo=YOUR_GH_OWNER/YOUR_GH_REPO"
```

Record the two outputs: `state_bucket` and `github_actions_role_arn`.

### Step 2 — Wire up configuration

1. The state bucket is hardcoded in both `backend.tf` files
   (`environments/dev/backend.tf`, `environments/prod/backend.tf`). If your
   bootstrap bucket name differs from the committed value, update the `bucket`
   field in both.
2. In GitHub → repo **Settings → Secrets and variables → Actions**, add secret:
   - `AWS_ROLE_ARN` = `<github_actions_role_arn>`
3. In GitHub → **Settings → Environments**, create:
   - `dev`  (no protection needed)
   - `prod` (enable **Required reviewers** → add yourself = manual approval gate)

### Step 3 — Deploy via Git (the intended path)

- Open a PR → `terraform-ci` runs fmt/validate/plan for both environments.
- Merge to `main` → `deploy-dev` applies to **dev** automatically.
- Publish a Release with a `v*` tag → `deploy-prod` waits for approval, then applies to **prod**.

### Local deployment (optional, for debugging)

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
terraform output api_endpoint    # then: curl "$(terraform output -raw api_endpoint)"
```

## 7. Verifying a deployment

```bash
curl "$(terraform -chdir=environments/dev  output -raw api_endpoint)"
curl "$(terraform -chdir=environments/prod output -raw api_endpoint)"
```

Expected response:

```json
{"message":"Hello World","app":"hello-app","environment":"dev","version":"<git-sha>"}
```

## 8. Troubleshooting & FAQ

See [`docs/troubleshooting.md`](docs/troubleshooting.md).

## 9. Known limitations, assumptions & future improvements

**Assumptions**
- AWS + GitHub Actions were chosen since the platform was left to the engineer.
- Single AWS account; environments are isolated by naming + state key. Real-world
  setups often use separate accounts per environment.

**Known limitations**
- The bootstrap CI IAM policy uses `lambda:*`/`apigateway:*` for convenience.
  Tighten to specific actions/resources for production.
- No custom domain / TLS certificate; uses the default API Gateway URL.
- No automated application tests beyond `terraform validate` and a smoke curl.

**Future improvements**
- Add a `staging` environment (the module already supports it).
- Per-environment AWS accounts via assumable roles.
- Add `tflint`/`checkov`/`trivy` security scanning to the CI workflow.
- Add a post-deploy smoke test step that curls the endpoint and asserts 200.
- Add automated rollback on failed prod smoke test.

