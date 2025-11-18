output "s3_bucket_name" {
  description = "Name of the S3 bucket for microservice 2 uploads"
  value       = aws_s3_bucket.microservice2_uploads.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for microservice 2 uploads"
  value       = aws_s3_bucket.microservice2_uploads.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS email queue"
  value       = aws_sqs_queue.email_queue.id
}

output "sqs_queue_arn" {
  description = "ARN of the SQS email queue"
  value       = aws_sqs_queue.email_queue.arn
}

output "sqs_dlq_url" {
  description = "URL of the SQS dead letter queue"
  value       = aws_sqs_queue.email_queue_dlq.id
}

output "sqs_dlq_arn" {
  description = "ARN of the SQS dead letter queue"
  value       = aws_sqs_queue.email_queue_dlq.arn
}

output "ssm_token_parameter_name" {
  description = "Name of the SSM parameter storing the API token"
  value       = aws_ssm_parameter.api_token.name
}

output "ssm_token_parameter_arn" {
  description = "ARN of the SSM parameter storing the API token"
  value       = aws_ssm_parameter.api_token.arn
}