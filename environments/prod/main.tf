provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedDate = "2026-07-29"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  environment       = "prod"
  az_list           = slice(data.aws_availability_zones.available.names, 0, 3)
  bucket_name_state = var.state_bucket_name != null ? var.state_bucket_name : "tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

# Remote State Data Source (Reads Staging Outputs for reference/cross-env verification)
data "terraform_remote_state" "staging" {
  backend = "s3"

  config = {
    bucket = local.bucket_name_state
    key    = "staging/terraform.tfstate"
    region = var.region
  }
}

# 1. Networking Module (3 AZs, High Availability NAT Gateway per AZ)
module "networking" {
  source               = "../../modules/networking"
  environment          = local.environment
  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.az_list
  single_nat_gateway   = false # HA: One NAT Gateway per AZ
  tags                 = var.tags
}

# 2. Secrets Manager Module (30-day recovery window, rotation enabled)
module "secretsmanager" {
  source               = "../../modules/secretsmanager"
  environment          = local.environment
  region               = var.region
  project_name         = var.project_name
  secret_name          = "app-secrets"
  recovery_window_days = var.secret_recovery_window_days
  enable_rotation      = var.enable_secret_rotation
  rotation_days        = 30
  tags                 = var.tags
}

# 3. App Runner Module (1 vCPU, 2 GB RAM, Multi-AZ VPC Connector)
module "apprunner" {
  source             = "../../modules/apprunner"
  environment        = local.environment
  region             = var.region
  project_name       = var.project_name
  service_name       = "api"
  cpu                = var.app_runner_cpu
  memory             = var.app_runner_memory
  min_size           = 2
  max_size           = 10
  secret_arns        = [module.secretsmanager.secret_arn]
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = module.networking.security_group_ids
  tags               = var.tags
}
