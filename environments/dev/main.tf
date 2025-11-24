provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "dev"
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
  environment = "dev"
  az_list     = [data.aws_availability_zones.available.names[0]]
}

# 1. Networking Module (Single AZ, Single NAT Gateway)
module "networking" {
  source               = "../../modules/networking"
  environment          = local.environment
  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.az_list
  single_nat_gateway   = true
  tags                 = var.tags
}

# 2. Secrets Manager Module (0-day recovery window)
module "secretsmanager" {
  source               = "../../modules/secretsmanager"
  environment          = local.environment
  region               = var.region
  project_name         = var.project_name
  secret_name          = "app-secrets"
  recovery_window_days = var.secret_recovery_window_days
  enable_rotation      = false
  tags                 = var.tags
}

# 3. App Runner Module (0.25 vCPU, 0.5 GB RAM)
module "apprunner" {
  source             = "../../modules/apprunner"
  environment        = local.environment
  region             = var.region
  project_name       = var.project_name
  service_name       = "api"
  cpu                = var.app_runner_cpu
  memory             = var.app_runner_memory
  min_size           = 1
  max_size           = 2
  secret_arns        = [module.secretsmanager.secret_arn]
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = module.networking.security_group_ids
  tags               = var.tags
}

# 4. Compute Module (EC2 instance included for Dev)
module "compute" {
  source              = "../../modules/compute"
  environment         = local.environment
  region              = var.region
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  subnet_id           = module.networking.private_subnet_ids[0]
  instance_type       = var.ec2_instance_type
  associate_public_ip = false
  tags                = var.tags
}
