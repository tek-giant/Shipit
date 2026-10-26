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
    key            = "dev/app/terraform.tfstate"
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
      Layer       = "app"
      ManagedBy   = "terraform"
    }
  }
}

# Read the network built earlier (VPC and subnet IDs)
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "shipit-tfstate-743978812281"
    key     = "dev/network/terraform.tfstate"
    region  = "eu-west-2"
    profile = "shipit"
  }
}

locals {
  name               = "shipit-dev"
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_app_subnet_ids
}
