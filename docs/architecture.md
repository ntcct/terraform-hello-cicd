# Solution architecture

## Overview

A serverless "Hello World" application deployed to AWS via Terraform and
GitHub Actions, across two isolated environments.

```mermaid
flowchart TB
    subgraph Dev["Git-driven workflow"]
        PR["Pull Request to main"]
        MERGE["Merge to main"]
        REL["Release / tag v*"]
    end

    subgraph GHA["GitHub Actions (OIDC federation)"]
        CI["terraform-ci<br/>fmt + validate + plan (dev & prod)"]
        DDEV["deploy-dev<br/>terraform apply"]
        DPROD["deploy-prod<br/>manual approval + apply"]
    end

    subgraph AWS["AWS account"]
        subgraph Shared["Shared state"]
            S3["S3 (versioned, encrypted, native lockfile)"]
        end
        subgraph EDEV["Environment: dev"]
            AD["API Gateway HTTP"] --> LD["Lambda hello-app-dev"] --> CWD["CloudWatch Logs"]
        end
        subgraph EPROD["Environment: prod"]
            AP["API Gateway HTTP"] --> LP["Lambda hello-app-prod"] --> CWP["CloudWatch Logs"]
        end
    end

    PR --> CI
    MERGE --> DDEV --> EDEV
    REL --> DPROD --> EPROD
    CI -.read.-> Shared
    DDEV -.read/write/lock.-> Shared
    DPROD -.read/write/lock.-> Shared
```

## Request flow

```mermaid
sequenceDiagram
    participant U as Client (curl/browser)
    participant G as API Gateway (HTTP)
    participant L as Lambda (handler.py)
    participant C as CloudWatch Logs

    U->>G: GET /
    G->>L: AWS_PROXY invoke (v2.0 event)
    L->>C: log invocation
    L-->>G: 200 + JSON {message, environment, version}
    G-->>U: 200 + JSON
```

## Components

- **Application** (`app/src/handler.py`): a Python Lambda returning a JSON
  greeting that includes the environment name and version.
- **Module** (`modules/lambda-api`): packages the source, creates the Lambda,
  its least-privilege IAM role, a CloudWatch log group with retention, and an
  HTTP API Gateway with an `ANY /` route.
- **Environments** (`environments/dev`, `environments/prod`): thin root modules
  that call the shared module with environment-specific inputs and their own
  remote-state key.
- **Bootstrap** (`bootstrap/`): one-time creation of the state bucket and the
  GitHub OIDC provider + IAM role.

## Why this design

- A single reusable module keeps the two environments consistent and DRY; they
  differ only by input values (memory, log retention, version label).
- Remote state in S3 with native lockfile locking (`use_lockfile`, Terraform
  >= 1.10) enables safe concurrent collaboration and CI execution without a
  separate DynamoDB table. Separate state keys guarantee environment isolation.
- OIDC removes the need to store static AWS access keys in GitHub.
