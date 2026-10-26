terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket         = "shipit-tfstate-743978812281"
    key            = "dev/network/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "shipit-tf-locks"
    encrypt        = true
    profile        = "shipit"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "shipit"

  default_tags {
    tags = {
      Project     = "shipit"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name       = "shipit-dev"
  cidr       = "10.10.0.0/16"
  azs        = ["eu-west-2a", "eu-west-2b"]
  enable_nat = false
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  value = module.vpc.private_data_subnet_ids
}

module "ecr_orders_api" {
  source = "../../modules/ecr"

  name = "shipit/orders-api"
}

output "orders_api_repository_url" {
  value = module.ecr_orders_api.repository_url
}
