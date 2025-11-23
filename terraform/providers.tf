terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  #  backend "s3" {
  #    bucket = "royal-terraform-backend-bucket"
  #    key    = "checkpoint-ha/terraform.tfstate"
  #    region = "eu-west-1"
  #  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CheckPoint-HomeAssignment"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}