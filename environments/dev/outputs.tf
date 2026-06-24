output "api_endpoint" {
  description = "Hello World endpoint for the dev environment."
  value       = module.app.api_endpoint
}

output "function_name" {
  description = "Lambda function name (dev)."
  value       = module.app.function_name
}
