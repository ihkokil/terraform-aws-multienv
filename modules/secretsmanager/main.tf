data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  full_secret_name = "${local.name_prefix}-${var.secret_name}"
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# 1. KMS Key for Secrets Manager (if kms_key_id is not provided)
resource "aws_kms_key" "secrets" {
  count                   = var.kms_key_id == null ? 1 : 0
  description             = "KMS Key for ${local.full_secret_name} secret encryption"
  deletion_window_in_days = var.recovery_window_days == 0 ? 7 : var.recovery_window_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager service to use key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.full_secret_name}-kms-key"
    }
  )
}

resource "aws_kms_alias" "secrets" {
  count         = var.kms_key_id == null ? 1 : 0
  name          = "alias/${local.full_secret_name}-key"
  target_key_id = aws_kms_key.secrets[0].key_id
}

locals {
  kms_arn = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.secrets[0].arn
}

# 2. Secrets Manager Secret
resource "aws_secretsmanager_secret" "main" {
  name                    = local.full_secret_name
  description             = "Encrypted application secrets for ${local.name_prefix}"
  kms_key_id              = local.kms_arn
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = local.full_secret_name
    }
  )
}

# 3. Secret Version
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = var.secret_string
}

# 4. Secret Resource Policy
resource "aws_secretsmanager_secret_policy" "main" {
  secret_arn = aws_secretsmanager_secret.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RestrictAccessToAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}
