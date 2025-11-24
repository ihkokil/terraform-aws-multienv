data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  service_name = "${local.name_prefix}-${var.service_name}"
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# 1. ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecr"
    }
  )
}

# 2. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "apprunner" {
  name              = "/aws/apprunner/${local.service_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.service_name}-logs"
    }
  )
}

# 3. IAM Access Role (For App Runner to pull from ECR and read Secrets)
resource "aws_iam_role" "apprunner_access_role" {
  name = "${local.service_name}-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Grant Secrets Manager access if secrets provided
resource "aws_iam_policy" "apprunner_secrets_policy" {
  count       = length(var.secret_arns) > 0 ? 1 : 0
  name        = "${local.service_name}-secrets-policy"
  description = "Allows App Runner service role to fetch secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_secrets_attach" {
  count      = length(var.secret_arns) > 0 ? 1 : 0
  role       = aws_iam_role.apprunner_access_role.name
  policy_arn = aws_iam_policy.apprunner_secrets_policy[0].arn
}

# 4. IAM Instance Role (App Container Runtime Permissions)
resource "aws_iam_role" "apprunner_instance_role" {
  name = "${local.service_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# 5. App Runner VPC Connector
resource "aws_apprunner_vpc_connector" "connector" {
  count              = length(var.subnet_ids) > 0 ? 1 : 0
  vpc_connector_name = "${local.service_name}-vpc-conn"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.service_name}-vpc-conn"
    }
  )
}

# 6. Auto Scaling Configuration
resource "aws_apprunner_auto_scaling_configuration_version" "scaling" {
  auto_scaling_configuration_name = "${local.service_name}-asg-config"
  max_concurrency                 = 100
  max_size                        = var.max_size
  min_size                        = var.min_size

  tags = local.common_tags
}

# 7. App Runner Service
resource "aws_apprunner_service" "app" {
  service_name = local.service_name

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.scaling.arn

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access_role.arn
    }

    image_repository {
      image_identifier      = var.image_uri
      image_repository_type = length(regexall("^public.ecr.aws", var.image_uri)) > 0 ? "ECR_PUBLIC" : "ECR"

      image_configuration {
        port                        = "8080"
        runtime_environment_variables = var.env_vars
      }
    }
  }

  network_configuration {
    egress_configuration {
      egress_type       = length(var.subnet_ids) > 0 ? "VPC" : "DEFAULT"
      vpc_connector_arn = length(var.subnet_ids) > 0 ? aws_apprunner_vpc_connector.connector[0].arn : null
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.service_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.apprunner_ecr_access
  ]
}
