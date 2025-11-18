# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for microservice 2 uploads"
  value       = module.storage.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for microservice 2 uploads"
  value       = module.storage.s3_bucket_arn
}

# SQS Outputs
output "sqs_queue_url" {
  description = "URL of the SQS email queue"
  value       = module.storage.sqs_queue_url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS email queue"
  value       = module.storage.sqs_queue_arn
}

output "sqs_dlq_url" {
  description = "URL of the SQS dead letter queue"
  value       = module.storage.sqs_dlq_url
}

output "sqs_dlq_arn" {
  description = "ARN of the SQS dead letter queue"
  value       = module.storage.sqs_dlq_arn
}

# SSM Outputs
output "ssm_token_parameter_name" {
  description = "Name of the SSM parameter storing the API token"
  value       = module.storage.ssm_token_parameter_name
}

# IAM Outputs
output "microservice1_task_role_arn" {
  description = "ARN of the IAM role for microservice 1 tasks"
  value       = module.iam.microservice1_task_role_arn
}

output "microservice2_task_role_arn" {
  description = "ARN of the IAM role for microservice 2 tasks"
  value       = module.iam.microservice2_task_role_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  value       = module.iam.ecs_task_execution_role_arn
}