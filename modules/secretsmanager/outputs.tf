output "secret_id" {
  description = "The ID of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.main.id
}

output "secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.main.arn
}

output "secret_name" {
  description = "The name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.main.name
}

output "kms_key_arn" {
  description = "The ARN of the KMS Key used for secret encryption"
  value       = local.kms_arn
}
