output "api_endpoint" {
  description = "Hello World endpoint for the prod environment."
  value       = module.app.api_endpoint
}

output "function_name" {
  description = "Lambda function name (prod)."
  value       = module.app.function_name
}
