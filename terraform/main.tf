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

# ECS Module (depends on networking, storage, and IAM)
module "ecs" {
  source = "./ecs"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Networking inputs
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  # IAM inputs
  microservice1_task_role_arn = module.iam.microservice1_task_role_arn
  microservice2_task_role_arn = module.iam.microservice2_task_role_arn
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn

  # Storage inputs
  sqs_queue_url            = module.storage.sqs_queue_url
  s3_bucket_name           = module.storage.s3_bucket_name
  ssm_token_parameter_name = module.storage.ssm_token_parameter_name
}