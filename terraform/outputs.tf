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

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.ecs_cluster_id
}

output "ecr_repository_microservice1_url" {
  description = "URL of the ECR repository for microservice 1"
  value       = module.ecs.ecr_repository_microservice1_url
}

output "ecr_repository_microservice2_url" {
  description = "URL of the ECR repository for microservice 2"
  value       = module.ecs.ecr_repository_microservice2_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "microservice1_service_name" {
  description = "Name of the ECS service for microservice 1"
  value       = module.ecs.microservice1_service_name
}

output "microservice2_service_name" {
  description = "Name of the ECS service for microservice 2"
  value       = module.ecs.microservice2_service_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.ecs.cloudwatch_dashboard_url
}