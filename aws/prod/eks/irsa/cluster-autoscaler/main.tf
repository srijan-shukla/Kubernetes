##############################################################
# AWS Provider information
##############################################################

provider "aws" {
  region = local.region
}

##############################################################
# Define Terraform state backend
##############################################################

terraform {
  backend "s3" {
    encrypt        = "true"
    bucket         = "prod-terraform-files"
    key            = "prod/eks/irsa/cluster-autoscaler/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}



##############################################################
# Get the details from vpc state file
##############################################################

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    region = "ap-south-1"
    bucket = "prod-terraform-files"
    key    = "prod/eks/terraform.tfstate"
  }
}


##############################################################
# Tags variables defined into locals
##############################################################

locals {
  name            = "fca"
  region          = "ap-south-1"
  cluster_version = "1.28"
  environment     = "prod"
  component       = "fca"
  key_name        = "ppsl-mo-prod-mumbai"
  tags = {
    Terraform    = "True"
    environment  = "prod"
}

}
data "aws_caller_identity" "current" {}


##############################################################
# IAM role for Cluster Autoscaler
##############################################################

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeInstanceTypes",
      "autoscaling:DescribeInstances",
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:SetDesiredCapacity",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
    }
  }

module "eks_iam_role_cluster_autoscaler" {
  source  = "cloudposse/eks-iam-role/aws"
  version = "0.10.3"

  namespace                   = "kube-system"
  environment                 = "prod"
  name                        = "${local.name}-${local.component}-clstrautsclr"
  delimiter                   = "-"
  aws_account_number          = data.aws_caller_identity.current.account_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  service_account_name        = "*"
  service_account_namespace   = "kube-system"
  aws_iam_policy_document     = data.aws_iam_policy_document.cluster_autoscaler.json

  # tags = local.tags
}