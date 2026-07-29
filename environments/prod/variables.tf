variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "CIDR block for prod VPC"
  type        = string
  default     = "10.3.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for prod public subnets across 3 AZs"
  type        = list(string)
  default     = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for prod private subnets across 3 AZs"
  type        = list(string)
  default     = ["10.3.10.0/24", "10.3.20.0/24", "10.3.30.0/24"]
}

variable "app_runner_cpu" {
  description = "App Runner CPU setting (1024 = 1 vCPU)"
  type        = string
  default     = "1024"
}

variable "app_runner_memory" {
  description = "App Runner Memory setting (2048 = 2 GB)"
  type        = string
  default     = "2048"
}

variable "secret_recovery_window_days" {
  description = "Recovery window for Secrets Manager deletion in prod"
  type        = number
  default     = 30
}

variable "enable_secret_rotation" {
  description = "Enable automatic rotation for production secret"
  type        = bool
  default     = true
}

variable "state_bucket_name" {
  description = "S3 Bucket name for remote state lookup"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
