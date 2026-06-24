###############################################################################
# lambda-api module
#
# Provisions a serverless "Hello World" application:
#   - Packages the application source into a deployment zip
#   - Lambda function (runs the application code)
#   - IAM execution role with least-privilege logging permissions
#   - CloudWatch log group with retention
#   - HTTP API Gateway fronting the function (ANY route)
#
# The module is environment-agnostic: callers pass `environment` and the module
# derives consistent, unique names from `app_name` + `environment`.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

locals {
  name = "${var.app_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Application = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "lambda-api"
  })
}

# ---------------------------------------------------------------------------
# Package the application source into a deployment artifact.
# source_code_hash ensures the Lambda is redeployed whenever app code changes,
# which is how application deployments flow through the pipeline.
# ---------------------------------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/.build/${local.name}.zip"
}

# ---------------------------------------------------------------------------
# IAM execution role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------------------------
# CloudWatch log group (created explicitly so retention is managed by Terraform)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# ---------------------------------------------------------------------------
# Lambda function (the application)
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "app" {
  function_name    = local.name
  role             = aws_iam_role.lambda.arn
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  memory_size      = var.lambda_memory_mb
  timeout          = var.lambda_timeout_seconds
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      APP_NAME    = var.app_name
      APP_VERSION = var.app_version
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# HTTP API Gateway -> Lambda
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
  tags          = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.app.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
