variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# IAM inputs
variable "microservice1_task_role_arn" {
  description = "ARN of IAM role for microservice 1 tasks"
  type        = string
}

variable "microservice2_task_role_arn" {
  description = "ARN of IAM role for microservice 2 tasks"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of IAM role for ECS task execution"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS email queue"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for microservice 2 uploads"
  type        = string
}

variable "ssm_token_parameter_name" {
  description = "Name of the SSM parameter storing the API token"
  type        = string
}

variable "microservice1_cpu" {
  description = "CPU units for microservice 1 (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "microservice1_memory" {
  description = "Memory for microservice 1 in MB"
  type        = number
  default     = 512
}

variable "microservice2_cpu" {
  description = "CPU units for microservice 2 (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "microservice2_memory" {
  description = "Memory for microservice 2 in MB"
  type        = number
  default     = 512
}

variable "microservice1_desired_count" {
  description = "Desired number of microservice 1 tasks"
  type        = number
  default     = 1
}

variable "microservice2_desired_count" {
  description = "Desired number of microservice 2 tasks"
  type        = number
  default     = 1
}