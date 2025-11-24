output "app_runner_service_arn" {
  description = "The ARN of the App Runner Service"
  value       = aws_apprunner_service.app.arn
}

output "app_runner_service_url" {
  description = "The domain URL of the App Runner Service"
  value       = "https://${aws_apprunner_service.app.service_url}"
}

output "app_runner_service_id" {
  description = "The unique Service ID of the App Runner Service"
  value       = aws_apprunner_service.app.service_id
}

output "ecr_repository_url" {
  description = "The URL of the ECR Repository"
  value       = aws_ecr_repository.app.repository_url
}
