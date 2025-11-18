variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS email queue"
  type        = string
}

variable "sqs_dlq_arn" {
  description = "ARN of the SQS dead letter queue"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for microservice 2 uploads"
  type        = string
}

variable "ssm_token_parameter_arn" {
  description = "ARN of the SSM parameter storing the API token"
  type        = string
}
