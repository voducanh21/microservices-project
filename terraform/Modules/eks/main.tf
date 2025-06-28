module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.3"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  subnet_ids                      = var.subnet_ids
  vpc_id                          = var.vpc_id
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      instance_types = ["t3.medium"]
    }
  }

  access_entries = {
    admin = {
      principal_arn = var.principal_arn

      policy_associations = {
        admin = {
          policy_arn    = var.policy_arn
          access_scope = {
            type       = "cluster"
            namespaces = []
          }
        }
      }
    }
  }

  tags = var.tags
}
