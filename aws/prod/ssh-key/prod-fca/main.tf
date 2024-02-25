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
    key            = "prod/ssh-key/prod-fca/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}

locals {
  region = "ap-south-1"
  key_name = "prod-fca"

}

resource "tls_private_key" "prod-fca-private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "prod-fca-key_pair" {
  key_name   = local.key_name       # Create a "myKey" to AWS!!
  public_key = tls_private_key.prod-fca-private_key.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.prod-fca-private_key.private_key_pem}' > ./${local.key_name}.pem"
  }
}