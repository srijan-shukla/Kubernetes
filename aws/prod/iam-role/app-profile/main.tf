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
    key            = "prod/iam-role/app-profile/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}

################################################
# Tags variables defined into locals
################################################

locals {
  name   = "app-profile"
  region = "ap-south-1"
  environment = "prod"
  tags = {
    environment  = "prod"
    Terraform    = "True"
  }
}
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "v4.0.0"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role = true

  role_name         = local.name
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  number_of_custom_role_policy_arns = 1
  tags                              = local.tags
}

resource "aws_iam_instance_profile" "main" {
  name = local.name
  path = "/"
  role = module.iam_assumable_role.iam_role_name
  tags = local.tags
}