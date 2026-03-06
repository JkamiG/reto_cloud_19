terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "networking" {
  source               = "../../modules/networking"
  environment          = var.environment
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "compute" {
  source           = "../../modules/compute"
  environment      = var.environment
  project          = var.project
  instance_type    = var.instance_type
  subnet_id        = module.networking.private_subnet_ids[0]
  subnet_ids       = module.networking.private_subnet_ids
  vpc_id           = module.networking.vpc_id
  root_volume_size = var.root_volume_size
  use_asg          = var.use_asg
  asg_min          = var.asg_min
  asg_max          = var.asg_max
  asg_desired      = var.asg_desired
  ingress_rules = [
    { port = 22, protocol = "tcp", cidr_blocks = ["10.2.0.0/16"], description = "SSH from VPC only" },
    { port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" },
    { port = 8080, protocol = "tcp", cidr_blocks = ["10.2.0.0/16"], description = "App port from VPC" }
  ]
}
