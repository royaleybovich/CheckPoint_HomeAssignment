variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "api_token_default" {
  description = "Default API token value (should be overridden via tfvars in production)"
  type        = string
  sensitive   = true
}