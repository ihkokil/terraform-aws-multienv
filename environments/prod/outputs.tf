output "vpc_id" {
  description = "The VPC ID of the prod environment"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs across 3 AZs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs across 3 AZs"
  value       = module.networking.private_subnet_ids
}

output "app_runner_service_url" {
  description = "URL of the Production App Runner service"
  value       = module.apprunner.app_runner_service_url
}

output "ecr_repository_url" {
  description = "URL of the Production ECR repository"
  value       = module.apprunner.ecr_repository_url
}

output "secret_arn" {
  description = "ARN of the Production AWS Secrets Manager secret"
  value       = module.secretsmanager.secret_arn
}

output "kms_key_arn" {
  description = "ARN of the Production KMS Customer Master Key"
  value       = module.secretsmanager.kms_key_arn
}

output "staging_vpc_id_reference" {
  description = "Reference to staging VPC ID via remote state data source"
  value       = data.terraform_remote_state.staging.outputs.vpc_id
}
