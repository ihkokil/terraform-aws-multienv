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
  description = "CIDR block for staging VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for staging public subnets across 2 AZs"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for staging private subnets across 2 AZs"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.20.0/24"]
}

variable "app_runner_cpu" {
  description = "App Runner CPU setting (512 = 0.5 vCPU)"
  type        = string
  default     = "512"
}

variable "app_runner_memory" {
  description = "App Runner Memory setting (1024 = 1 GB)"
  type        = string
  default     = "1024"
}

variable "secret_recovery_window_days" {
  description = "Recovery window for Secrets Manager deletion in staging"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
