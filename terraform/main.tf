module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  map_public_ip_on_launch = true
  enable_nat_gateway = false  #  Tắt NAT gateway

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  subnet_ids = module.vpc.public_subnets  #  Dùng public subnet
  vpc_id     = module.vpc.vpc_id

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false  #  Không cần thiết nếu dùng public subnet

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 2

      instance_types = ["t3.medium"]  #  Rẻ hơn
    }
  }

  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::779846819464:user/terraform-user"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
            namespaces = []
          }
        }
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_eks_cluster_auth" "token" {
  name = module.eks.cluster_name
}
