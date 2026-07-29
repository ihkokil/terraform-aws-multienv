output "vpc_id" {
  description = "The VPC ID of the dev environment"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "app_runner_service_url" {
  description = "URL of the App Runner service"
  value       = module.apprunner.app_runner_service_url
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.apprunner.ecr_repository_url
}

output "secret_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = module.secretsmanager.secret_arn
}

output "ec2_instance_id" {
  description = "EC2 Instance ID in dev environment"
  value       = module.compute.instance_id
}

output "ec2_private_ip" {
  description = "EC2 Instance private IP"
  value       = module.compute.instance_private_ip
}
