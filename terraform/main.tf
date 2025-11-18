module "networking" {
  source = "./networking"

  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
}

# Storage Module (S3, SQS, SSM)
module "storage" {
  source = "./storage"

  project_name      = var.project_name
  environment       = var.environment
  api_token_default = var.api_token_default
}

# IAM Module (depends on storage for resource ARNs)
module "iam" {
  source = "./iam"

  project_name            = var.project_name
  environment             = var.environment
  sqs_queue_arn           = module.storage.sqs_queue_arn
  sqs_dlq_arn             = module.storage.sqs_dlq_arn
  s3_bucket_arn           = module.storage.s3_bucket_arn
  ssm_token_parameter_arn = module.storage.ssm_token_parameter_arn
}