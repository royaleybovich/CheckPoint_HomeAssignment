variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "RoyalHA"
}

variable "api_token_default" {
  description = "Default API token value (should be overridden via tfvars in production)"
  type        = string
  default     = "default-token-change-me"
  sensitive   = true
}