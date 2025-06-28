module "vpc" {
  source = "./modules/vpc"

  name            = "eks-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  principal_arn   = "arn:aws:iam::779846819464:user/terraform-user"
  policy_arn      = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_eks_cluster_auth" "token" {
  name = module.eks.cluster_name
}
