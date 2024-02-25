################################################
# AWS Provider information
################################################

provider "aws" {
  region = local.region
}

################################################
# Define Terraform state backend
################################################

terraform {
  backend "s3" {
    encrypt        = "true"
    bucket         = "prod-terraform-files"
    key            = "prod/s3/terraform-files/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}

################################################
# Tags variables defined into locals
################################################

locals {
  name   = "terraform-files"
  region = "ap-south-1"
  environment = "prod"
  tags = {
    environment  = "prod"
    Terraform    = "True"
  }
}

################################################
# S3 Module
################################################

module "terraform-files_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.6.0"
  bucket                  = "${local.environment}-${local.name}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  versioning = {
    enabled = false
  }

  tags = local.tags
}

