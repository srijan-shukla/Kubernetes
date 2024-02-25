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
    encrypt = "true"
    bucket  = "prod-terraform-files"
    key     = "prod/dynamodb/terraform-dynamodb/terraform.tfstate"
    region  = "ap-south-1"
  }
}

################################################
# Tags variables defined into locals
################################################

locals {
  name   = "terraform"
  region = "ap-south-1"
  environment = "prod"
  tags = {
    environment  = "prod"
    Terraform    = "True"
  }
}

################################################
# DYNAMODB Module
################################################

module "terraform-dynamodb" {
  source         = "terraform-aws-modules/dynamodb-table/aws"
  version        = "3.1.2"
  name           = "${local.name}-dynamodb"
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 1

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = local.tags
}