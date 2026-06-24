# prod environment state location. Separate key => fully isolated state file.
bucket       = "hello-cicd-tfstate-584894272353"
key          = "prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true # native S3 state locking (Terraform >= 1.10); no DynamoDB
