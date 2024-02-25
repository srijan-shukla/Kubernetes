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
    key            = "prod/eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-dynamodb"
  }
}

################################################
# Get the details from vpc state file
################################################

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region = "ap-south-1"
    bucket = "prod-terraform-files"
    key    = "prod/vpc/terraform.tfstate"
  }
}


data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/1.28/amazon-linux-2-arm64/recommended/image_id"
}

################################################
# Tags variables defined into locals
################################################

locals {
  name            = "fca"
  region          = "ap-south-1"
  cluster_version = "1.28"
  environment     = "prod"
  component       = "fca"
  key_name        = "aws-login-personal"
  tags = {
    Terraform    = "True"
    environment  = "prod"
  }
}

################################################
# Additional security group
################################################


resource "aws_security_group" "additional" {
  name_prefix = "${local.environment}-${local.component}-eks-additional"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = merge(
     local.tags,
     {
      Name = "prod-fca-cluster-additional-sg"
     },
  )

  # ingress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   security_groups = ["sg-04e29d804f5d4ba2c"]
  #   description = "Allow connectivity from cluster to nodes"
  # } 
  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   security_groups = ["sg-04e29d804f5d4ba2c"]
  #   description = "connectivity from external alb"
  # } 
  # ingress {
  #   from_port   = 8080
  #   to_port     = 8080
  #   protocol    = "tcp"
  #   security_groups = ["sg-04e29d804f5d4ba2c"]
  #   description = "connectivity from external alb"
  # } 
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     security_groups = ["sg-04e29d804f5d4ba2c"]
#     description = "connectivity from internal alb"
#   }
}


################################################
# Provider configuration
################################################

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
  #  api_version = "client.authentication.k8s.io/v1alpha1"
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# aws_caller_identity to get the account details
data "aws_caller_identity" "current" {}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 19.4.2"
  cluster_name                    = "${local.environment}-${local.component}"
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_addons = {
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE" 
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE" 
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE" 
    }
  }
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.infra_subnets
  #control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.all_private_subnets

# Additional Extend cluster security group rules (sg-0957afcc6e722724c)
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 0
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    },
    inress_nodes_ephemeral_ports_tcp = {
      description = "Allow https from office vpn and other access"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.16.224.0/20"]
    },
    
}

# Extend node-to-node security group rules ()
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    ingress_self_https = {
      description = "Node group allow https "
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.16.224.0/20"]
    },
   ingress_self_alternative_https = {
      description = "Node group allow alernative https "
      protocol    = "tcp"
      from_port   = 9443
      to_port     = 9443
      type        = "ingress"
      cidr_blocks = ["10.16.224.0/20"]
    },
    egress = {
      protocol    = "-1"
      description      = "Node all egress"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["18.205.93.0/25","13.52.5.0/25","104.192.136.0/21","18.234.32.128/25","185.166.140.0/22","10.16.224.0/20"]
    }
  }

#   node_security_group_tags = {
#     public-sg = true
#   }

  
  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    key_name                     = local.key_name
   # vpc_security_group_ids       = [data.terraform_remote_state.vpc.outputs.additional_sg]
    vpc_security_group_ids       = [aws_security_group.additional.id]
    ami_type                     = "AL2_ARM_64"
    ami_id                       = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)   
    instance_type                = "t4g.small"
    iam_role_additional_policies = {
      additional = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    instance_refresh = {}
  }
     

  self_managed_node_groups = {

    # Node Group prod-fca-grp-1
    prod-fca-grp-1 = {
      name = "prod-fca-grp-1"
      use_name_prefix = false
      iam_role_use_name_prefix = false
      iam_role_name = "prod-fca-grp-1"
    #  ami_id          = data.aws_ami.eks_default.image_id
      instance_types = ["m6g.xlarge"]
     # instance_types = ["m5a.large"]

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 25
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            delete_on_termination = true
          }
        }
      }
      #iam_role_additional_policies = {
      #  AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      #  AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
     # }
      min_size = 1
      max_size = 30
      capacity_rebalance = false
      suspended_processes = ["AZRebalance"]

      use_mixed_instances_policy = true

      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 100
          spot_allocation_strategy                 = "capacity-optimized-prioritized"
        }

        override = [
          {
            instance_type = "t4g.small"
          },
          {
            instance_type = "t4g.large"
          },
      ]
      }

      labels = merge(
        local.tags,
        {
          Node-group = "prod-fca-grp-1",
          Cluster    = "${local.environment}-${local.component}",
          "k8s.io/cluster-autoscaler/enabled" = "TRUE",
          "k8s.io/cluster-autoscaler/prod-fca" = "owned",
        },
      )

     subnet_ids = data.terraform_remote_state.vpc.outputs.app_subnets

      # See issue https://github.com/awslabs/amazon-eks-ami/issues/844
      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      export KUBELET_EXTRA_ARGS="--max-pods=110"
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT
      
      #bootstrap_extra_args = "--kubelet-extra-args '--node-labels=worker-type=group-1 --register-with-taints=worker-type=group-1:NoSchedule'"

      #bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot,worker-type=group-1 --register-with-taints=worker-type=group-1:NoSchedule'"
      #bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
      # Installation of SSM agent
      post_bootstrap_user_data = <<-EOT
      cd /tmp
     # sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      EOT

      tags = merge(
        local.tags,
        {
          Node-group = "prod-fca-grp-1",
          Cluster    = "${local.environment}-${local.component}",
          "k8s.io/cluster-autoscaler/enabled" = "TRUE",
          "k8s.io/cluster-autoscaler/prod-fca" = "owned",
        },
      )

    }


  }


  # aws-auth configmap
  create_aws_auth_configmap = true
  # manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::590184126329:role/app-profile"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::767397730150:user/terraform-admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_accounts = [data.aws_caller_identity.current.account_id]

  tags = local.tags
}


resource "kubernetes_namespace" "example" {
  metadata {
    annotations = {
      name = "argocd"
    }

    labels = {
      mylabel = "argocd"
    }

    name = "argocd"
  }
}