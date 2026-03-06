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

# Read outputs from the dev environment state
data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = var.dev_state_bucket
    key    = "dev/terraform.tfstate"
    region = var.aws_region
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
  vpc_id           = module.networking.vpc_id
  root_volume_size = var.root_volume_size
  use_asg          = var.use_asg
  ingress_rules = [
    { port = 22, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "SSH from internal" },
    { port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" }
  ]
}

module "peering_dev_staging" {
  source = "../../modules/peering"

  requester_vpc_id          = data.terraform_remote_state.dev.outputs.vpc_id
  accepter_vpc_id           = module.networking.vpc_id
  requester_vpc_cidr        = data.terraform_remote_state.dev.outputs.vpc_cidr_block
  accepter_vpc_cidr         = var.vpc_cidr
  requester_route_table_ids = data.terraform_remote_state.dev.outputs.private_route_table_ids
  accepter_route_table_ids  = module.networking.private_route_table_ids
  requester_env             = "dev"
  accepter_env              = "staging"
}
