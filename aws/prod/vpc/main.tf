###############################################
# AWS Provider information
################################################

provider "aws" {

  region     = "ap-south-1"

}

################################################
# Define Terraform state backend
################################################

terraform {
  backend "s3" {
    encrypt        = "true"
    bucket         = "prod-terraform-files"
    key            = "prod/vpc/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}

################################################
# Tags variables defined into locals
################################################

locals {
  name         = "fca"
  region       = "ap-south-1"
  environment  = "prod"
  tags = {
    # Name         = "${local.name}"
    Terraform    = "True"
    environment  = "prod"
  }
}

################################################
# VPC Module
################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"

  name = "${local.environment}-${local.name}-vpc"
  cidr = "10.16.224.0/20"

  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets     = ["10.16.224.0/22", "10.16.228.0/22","10.16.232.0/22"]
  private_subnet_names = [ "prod-fca-vpc-ap-south-1a" , "prod-fca-vpc-ap-south-1b" , "prod-fca-vpc-ap-south-1c"]
  elasticache_subnets = ["10.16.237.128/25", "10.16.238.0/25","10.16.238.128/25"]
  database_subnets    = ["10.16.239.0/26", "10.16.239.64/26","10.16.239.128/26"]
  public_subnets      = ["10.16.236.0/25", "10.16.236.128/25","10.16.237.0/25"]
  create_database_subnet_group = true
  create_database_subnet_route_table = true

  create_elasticache_subnet_group = true
  create_elasticache_subnet_route_table = true

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_vpn_gateway   = true
  map_public_ip_on_launch = false

  private_subnet_suffix     = "app"
  database_subnet_suffix = "db"
  public_subnet_suffix      = "public"
  elasticache_subnet_suffix = "infra"
     
  one_nat_gateway_per_az    = true
  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "service.consul"
  dhcp_options_domain_name_servers = ["10.16.224.2"]

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = false
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnet_tags = {
    "kubernetes.io/cluster/prod-fca" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/prod-fca" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  elasticache_subnet_tags = {
  "role" = "infra"
  }

  tags = local.tags
}