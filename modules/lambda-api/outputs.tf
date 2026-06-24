output "api_endpoint" {
  description = "Base URL of the deployed Hello World application."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.app.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.app.arn
}

output "log_group_name" {
  description = "CloudWatch log group for the function."
  value       = aws_cloudwatch_log_group.lambda.name
}
