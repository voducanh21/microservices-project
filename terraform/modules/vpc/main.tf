module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name                 = var.name
  cidr                 = var.cidr
  azs                  = var.azs
  public_subnets       = var.public_subnets
  map_public_ip_on_launch = true
  enable_nat_gateway   = false

  tags = var.tags
}
