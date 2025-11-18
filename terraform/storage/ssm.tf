resource "aws_ssm_parameter" "api_token" {
  name        = "/${var.project_name}/${var.environment}/api-token"
  description = "API token for microservice 1 authentication"
  type        = "SecureString"
  value       = var.api_token_default # In production, this should be provided via terraform.tfvars

  tags = {
    Name        = "${var.project_name}-api-token"
    Description = "Secure token for API authentication"
  }
}